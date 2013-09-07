--[[
Command line compiler.

Compiles .sol to .lua, or prints out an error
--]]

--local folder_of_this_file = (...):match("(.-)[^%.]+$") -- returns 'lib.foo.'
--package.path = folder_of_this_file..'?.lua;' .. package.path
--package.path = '../build/?lua;' .. package.path

--error = dbg.errorlocal

--io.stderr:write('STDERR TEST\n')
--printf_err = function(...)
--	local msg = string.format(...)
--	io.stderr:write(msg .. '\n')
--end

--[[
print = function(msg)
	io.stderr:write(msg .. '\n')
end
--]]

--io.stdout:setvbuf 'no'
local lfs  = require 'lfs'
local path = require 'pl.path'

------------------------------------------------
-- Setup local includes:
-- Without this code 

local sol_dir  = path.dirname(arg[0])

if sol_dir == "" then
	-- OK
elseif path.isabs(sol_dir) then
	sol_dir = sol_dir .. '/'
else
	sol_dir = lfs.currentdir() .. '/' .. sol_dir .. '/'
end

--print("solc: sol_dir: " .. sol_dir)

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path

------------------------------------------------


local D               = require 'sol_debug'
local format_identity = require 'format_identity'
local Lexer           = require 'lexer'
local Parser          = require 'parser'
local S               = require 'scope'
local T               = require 'type'
local TypeCheck       = require 'type_check'
local U               = require 'util'
local printf_err      = U.printf_err

------------------------------------------------

_G.g_local_parse = false -- If true, ignore 'require'
_G.g_spam = false
_G.g_ignore_errors = false


typedef parse_info = {
	ast  : any,  -- For format_identity
	type : any,  -- What the module returns
}

typedef CURRENTLY_PARSING = false
local CURRENTLY_PARSING = false

-- type is CURRENTLY_PARSING during parsing.
var<{string => parse_info or CURRENTLY_PARSING}> g_modules = {}

local FAIL_INFO = { ast = nil, type = T.Any }


-- Find path to a module given it's name, and the path to the file doing the require:ing
local function find_moudle(path_in: string, mod_name: string) -> string?
	local dir      = path.splitpath(path_in) .. '/'

	local sol_path = dir .. mod_name .. '.sol'
	if U.file_exists(sol_path) then
		--U.printf("Found moudle at %q", sol_path)
		return sol_path
	end

	local lua_path = dir .. mod_name .. '.lua'
	if U.file_exists(lua_path) then
		--U.printf("Found moudle at %q", lua_path)
		return lua_path
	end

	--U.printf("No file at %q", sol_path)
	--U.printf_err("No file at %q", sol_path)

	return nil
end


local parse_module


local function parse_module_str(chain: [string], path_in: string, source_text: string) -> parse_info
	local filename = path.basename( path_in )  -- Keep error messages short

	local module_name = path_in:lower()

	local is_sol = (path.extension(filename) == '.sol')

	local settings = (is_sol and Parser.SOL_SETTINGS or Parser.LUA_SETTINGS)

	local st, tokens = Lexer.lex_sol(source_text, filename, settings)
	if not st then
		printf_err("Failed to lex %q", path_in)
		g_modules[module_name] = FAIL_INFO
		os.exit(1)
		return FAIL_INFO
	end

	local module_scope = S.Scope:create_module_scope()

	local st, ast = Parser.parse_sol(source_text, tokens, filename, settings, module_scope)
	if not st then
		--we failed to parse the file, show why
		printf_err("Failed to parse %q", path_in)
		g_modules[module_name] = FAIL_INFO
		os.exit(2)
		return FAIL_INFO
	end

	local on_require = function(mod_name, req_where)
		if _G.g_local_parse then
			return T.Any
		end

		--U.printf('require %q', v)
		local longer_chain = { unpack(chain) }
		table.insert(longer_chain, mod_name)
		local mod_path = find_moudle(path_in, mod_name)
		if mod_path then
			local mod_info = parse_module(longer_chain, mod_path)

			if mod_info == FAIL_INFO then
				-- Something went wrong - continue as if everything went right
				return T.Any
			end

			-- Bring in any globals:

			for _,v in ipairs(mod_info.global_vars) do
				--D.break_();
				local existing = module_scope:get_global( v.name )
				if existing and existing ~= v then
					printf_err("Global clash when including module '%s' at %s:"
						     .. "Global variable '%s' re-declared at %s, previously declared in %s",
						mod_name, req_where, v.name, v.where, existing.where)
				end

				if not existing then
					if _G.g_spam then
						U.printf("Adding global '%s'", v.name)
					end
					module_scope:add_global(v)
				end
			end


			if mod_info.type then
				return mod_info.type
			else
				-- No return-type
				return T.Void
			end
		else
			--printf_err('Failed to find module %q', mod_name)
			U.printf('Failed to find module %q', mod_name)
			return T.Any
		end
	end

	local success, type = TypeCheck(ast, filename, on_require, settings)

	if not success then
		--printf_err("TypeCheck failed: " .. type)
		local info = { ast = ast, type = T.Any }
		g_modules[module_name] = info
		os.exit(3)
		return info
	end

	if _G.g_spam then
		U.printf("Module %q successfully deduced to type %s", path_in, T.name(type))
	else
		--U.printf("Module %q successfully parsed and checked", module_name)
	end

	local info = {
		ast             = ast;
		type            = type;
		global_vars     = module_scope:get_global_vars();
		global_typedefs = module_scope:get_global_typedefs();
	}
	g_modules[module_name] = info
	return info
end


-- Returns { ast, type }
parse_module = function(chain: [string], path_in: string) -> parse_info
	local module_name = path_in:lower()

	local old_info = g_modules[module_name]
	if old_info == CURRENTLY_PARSING then
		printf_err("Module 'require' recusion detected: dependency chain: " .. U.pretty(chain))
		error(-42)
		return FAIL_INFO
	elseif old_info then
		--U.printf('require(%q) had buffered result', path_in)
		return old_info
	end

	g_modules[module_name] = CURRENTLY_PARSING

	if _G.g_spam then
		U.printf("Parsing %q...", path_in)
	end

	local source_text = U.read_entire_file( path_in )

	if not source_text then
		printf_err("'Failed to find module %q", path_in)
		g_modules[module_name] = FAIL_INFO
		return FAIL_INFO
	end

	local info = parse_module_str(chain, path_in, source_text)
	return info
end


local function output_module(info: parse_info, path_in: string, path_out: string?)
	if info.ast and path_out then
		U.write_unprotect(path_out) -- Ensure we can write over it

		local out_text = '--[[ DO NOT MODIFY - COMPILED FROM ' .. path_in .. ' --]] '
		out_text = out_text .. format_identity(info.ast, path_in)
		if not U.write_file(path_out, out_text) then
			printf_err("Failed to open %q for writing", path_out)
			os.exit(4)
		else
			if _G.g_spam then
				U.printf("File written to %q", path_out)
			end
			U.write_protect(path_out)
		end
	end

	if info.type and path_out then
		-- TODO: output .solh file with type deductions
		--U.write_file(path_out .. '.h', T.name(info.type) .. '\n')
	end
end


local function compile_file(path_in: string, path_out: string?)
	local settings = (function()
		if path.extension(path_in):lower() == '.sol' then
			return Parser.SOL_SETTINGS
		else
			return Parser.LUA_SETTINGS
		end
	end)()

	local info = parse_module({}, path_in)
	output_module(info, path_in, path_out)
end


local function print_help()
	print([[
		NAME:
		    solc - Sol compiler

		SYNOPSIS
			solc [ options ] [ filenames ]

		EXAMPLE
			lua solc.lua -o build *.sol
			ls build/

		DESCRIPTION
			solc translates files written in Sol to Lua. The filenames must end with .sol.

		AUTHOR
			Emil Ernerfeldt

		OPTIONS
			-h or --help
				print this help text

			-o output_dir
				Write compiled .lua files here rather than the default '.'

			-p
				Parse mode: Compile but do not write any Lua. This is useful for syntax checking.

			-s
				Spam mode: Will print extensive trace text (for debugging solc)

			-e0
				Ignore all errors and push through

			--check input_file_path
				Will read from stdin as if it was a file at the given path.
				Will look for local includes using that path.

			--profile
				Will profile solc to find slow parts of compilation process

			-d  or  --debug
				For debugging solc compiler
		]])
end

local g_profiler = nil


if #arg == 0 then
	print_help()
	os.exit(-1)
else
	local g_write_lua = true
	local g_out_dir = ''
	local ix = 1
	local num_files = 0

	while ix <= #arg do
		local a = arg[ix]
		ix = ix + 1

		if a == '-h' or a == '--help' then
			print_help()

		elseif a == '-o' then
			g_out_dir = arg[ix] .. '/'
			ix = ix + 1
			print('Files will be written to ' .. g_out_dir)

		elseif a == '-p' or a == '--parse' then
			-- e.g. for syntax checking
			g_write_lua = false

		elseif a == '-s' or a == '--spam' then
			_G.g_spam = true

		elseif a == '-e0' then
			_G.g_ignore_errors = true

		elseif a == '--profile' then
			g_profiler = require 'ProFi'
			print('Profiling (this may take a while)...')
			g_profiler:start()

		elseif a == '-d' or a == '--debug' then
			D.activate()
			print('Debugger activated')

		elseif a == '--check' then
			local path_in = arg[ix]
			ix = ix + 1
			
			_G.g_local_parse = true -- FIXME: else too slow for live-parsing

			-- Read entire stdin
			print("Reading from stdin...")
			local file_content = U.read_entire_stdin()
			U.printf("Parsing " .. path_in)
			local info = parse_module_str({}, path_in, file_content)

			-- TODO: write output?
			--output_module(info, path_in, path_out)

			num_files = num_files + 1

		elseif a:match('^-') then
			U.printf_err("Unknown option: %q", a)
			print_help()
			os.exit(1337)

		else
			local path_in = a
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending: %q", path_in)
				os.exit(-2)
			end

			if g_write_lua then
				path.mkdir( g_out_dir ) -- Ensure we can write there

				local dir, fn  = path.splitpath(path_in)
				local path_out = g_out_dir .. path.splitext(fn) .. '.lua'
				--local path_out = path_in .. '.lua'
				compile_file(path_in, path_out)
			else
				compile_file(path_in)
			end

			num_files = num_files + 1
		end
	end

	if num_files == 0 then
		printf_err( "No input!" )
		print_help()
		os.exit(-1337)
	end
end

if g_profiler then
	g_profiler:stop()
	--local REPORT_PATH = 'profiler_report.txt'
	--local REPORT_PATH = os.date("profiler_report_%Y_%m_%d_%X.txt")
	local REPORT_PATH = os.date("profile_reports/profiler_report_%Y_%m_%d__%H_%M_%S.txt")
	g_profiler:writeReport( REPORT_PATH )
	--print( 'Profile report written to ' .. REPORT_PATH)
end

os.exit(0) -- Success
