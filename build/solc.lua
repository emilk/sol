--[[ DO NOT MODIFY - COMPILED FROM sol/solc.sol --]] --[[
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
local lfs  = require 'lfs' --[[SOL OUTPUT--]] 
local path = require 'pl.path' --[[SOL OUTPUT--]] 

------------------------------------------------
-- Setup local includes:
-- Without this code 

local sol_dir  = path.dirname(arg[0]) --[[SOL OUTPUT--]] 

if sol_dir == "" then
	-- OK
elseif path.isabs(sol_dir) then
	sol_dir = sol_dir .. '/' --[[SOL OUTPUT--]] 
else
	sol_dir = lfs.currentdir() .. '/' .. sol_dir .. '/' --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


print("solc: sol_dir: " .. sol_dir) --[[SOL OUTPUT--]] 
print("path.abspath(''): " .. path.dirname(path.abspath('') .. arg[0])) --[[SOL OUTPUT--]] 

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path --[[SOL OUTPUT--]] 

------------------------------------------------


local D          = require 'sol_debug' --[[SOL OUTPUT--]] 
local output     = require 'output' --[[SOL OUTPUT--]] 
local Lexer      = require 'lexer' --[[SOL OUTPUT--]] 
local Parser     = require 'parser' --[[SOL OUTPUT--]] 
local S          = require 'scope' --[[SOL OUTPUT--]] 
local T          = require 'type' --[[SOL OUTPUT--]] 
local TypeCheck  = require 'type_check' --[[SOL OUTPUT--]] 
local U          = require 'util' --[[SOL OUTPUT--]] 
local printf_err = U.printf_err --[[SOL OUTPUT--]] 

------------------------------------------------

_G.g_local_parse = false --[[SOL OUTPUT--]]  -- If true, ignore 'require'
_G.g_spam = false --[[SOL OUTPUT--]] 
_G.g_ignore_errors = false --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 








local CURRENTLY_PARSING = false --[[SOL OUTPUT--]] 

-- type is CURRENTLY_PARSING during parsing.
local g_modules = {} --[[SOL OUTPUT--]] 

local FAIL_INFO = { ast = nil, type = T.Any } --[[SOL OUTPUT--]] 

local g_did_warn_about = {} --[[SOL OUTPUT--]] 


-- Find path to a module given it's name, and the path to the file doing the require:ing
local function find_moudle(path_in, mod_name)
	local dir      = path.splitpath(path_in) .. '/' --[[SOL OUTPUT--]] 

	local sol_path = dir .. mod_name .. '.sol' --[[SOL OUTPUT--]] 
	if U.file_exists(sol_path) then
		--U.printf("Found moudle at %q", sol_path)
		return sol_path --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local lua_path = dir .. mod_name .. '.lua' --[[SOL OUTPUT--]] 
	if U.file_exists(lua_path) then
		--U.printf("Found moudle at %q", lua_path)
		return lua_path --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--U.printf("No file at %q", sol_path)
	--U.printf_err("No file at %q", sol_path)

	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local parse_module --[[SOL OUTPUT--]] 


local function parse_module_str(chain, path_in, source_text)
	local filename = path.basename( path_in ) --[[SOL OUTPUT--]]   -- Keep error messages short

	local module_name = path_in:lower() --[[SOL OUTPUT--]] 

	local is_sol = (path.extension(filename) == '.sol') --[[SOL OUTPUT--]] 

	local settings = (is_sol and Parser.SOL_SETTINGS or Parser.LUA_SETTINGS) --[[SOL OUTPUT--]] 

	local st, tokens = Lexer.lex_sol(source_text, filename, settings) --[[SOL OUTPUT--]] 
	if not st then
		printf_err("Failed to lex %q", path_in) --[[SOL OUTPUT--]] 
		g_modules[module_name] = FAIL_INFO --[[SOL OUTPUT--]] 
		os.exit(1) --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local module_scope = S.Scope.create_module_scope() --[[SOL OUTPUT--]] 

	local st, ast = Parser.parse_sol(source_text, tokens, filename, settings, module_scope) --[[SOL OUTPUT--]] 
	if not st then
		--we failed to parse the file, show why
		printf_err("Failed to parse %q", path_in) --[[SOL OUTPUT--]] 
		g_modules[module_name] = FAIL_INFO --[[SOL OUTPUT--]] 
		os.exit(2) --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local on_require = function(mod_name, req_where)
		if _G.g_local_parse then
			return T.Any --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--U.printf('require %q', v)
		local longer_chain = { unpack(chain) } --[[SOL OUTPUT--]] 
		table.insert(longer_chain, mod_name) --[[SOL OUTPUT--]] 
		local mod_path = find_moudle(path_in, mod_name) --[[SOL OUTPUT--]] 
		if mod_path then
			local mod_info = parse_module(longer_chain, mod_path) --[[SOL OUTPUT--]] 

			if mod_info == FAIL_INFO then
				-- Something went wrong - continue as if everything went right
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			-- Bring in any globals:

			for _,v in ipairs(mod_info.global_vars) do
				--D.break_();
				local existing = module_scope:get_global( v.name ) --[[SOL OUTPUT--]] 
				if existing and existing ~= v then
					printf_err("Global clash when including module '%s' at %s:"
						     .. "Global variable '%s' re-declared at %s, previously declared in %s",
						mod_name, req_where, v.name, v.where, existing.where) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if not existing then
					if _G.g_spam then
						U.printf("Adding global '%s'", v.name) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					module_scope:add_global(v) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


			if mod_info.type then
				return mod_info.type --[[SOL OUTPUT--]] 
			else
				-- No return-type
				return T.Void --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			if not g_did_warn_about[mod_name:lower()] then
				g_did_warn_about[mod_name:lower()] = true --[[SOL OUTPUT--]] 
				U.printf('Failed to find module %q', mod_name) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return T.Any --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local success, type = TypeCheck(ast, filename, on_require, settings) --[[SOL OUTPUT--]] 

	if not success then
		--printf_err("TypeCheck failed: " .. type)
		local info = { ast = ast, type = T.Any } --[[SOL OUTPUT--]] 
		g_modules[module_name] = info --[[SOL OUTPUT--]] 
		os.exit(3) --[[SOL OUTPUT--]] 
		return info --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if _G.g_spam then
		U.printf("Module %q successfully deduced to type %s", path_in, T.name(type)) --[[SOL OUTPUT--]] 
	else
		--U.printf("Module %q successfully parsed and checked", module_name)
	end --[[SOL OUTPUT--]] 

	local info = {
		ast             = ast;
		type            = type;
		global_vars     = module_scope:get_global_vars();
		global_typedefs = module_scope:get_global_typedefs();
	} --[[SOL OUTPUT--]] 
	g_modules[module_name] = info --[[SOL OUTPUT--]] 
	return info --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Returns { ast, type }
parse_module = function(chain, path_in)
	local module_name = path_in:lower() --[[SOL OUTPUT--]] 

	local old_info = g_modules[module_name] --[[SOL OUTPUT--]] 
	if old_info == CURRENTLY_PARSING then
		printf_err("Module 'require' recusion detected: dependency chain: " .. U.pretty(chain)) --[[SOL OUTPUT--]] 
		error(-42) --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	elseif old_info then
		--U.printf('require(%q) had buffered result', path_in)
		return old_info --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	g_modules[module_name] = CURRENTLY_PARSING --[[SOL OUTPUT--]] 

	if _G.g_spam then
		U.printf("Parsing %q...", path_in) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local source_text = U.read_entire_file( path_in ) --[[SOL OUTPUT--]] 

	if not source_text then
		printf_err("'Failed to read %q", path_in) --[[SOL OUTPUT--]] 
		g_modules[module_name] = FAIL_INFO --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local info = parse_module_str(chain, path_in, source_text) --[[SOL OUTPUT--]] 
	return info --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function output_module(info, path_in, path_out)
	if info.ast and path_out then
		U.write_unprotect(path_out) --[[SOL OUTPUT--]]  -- Ensure we can write over it

		local out_text = '--[[ DO NOT MODIFY - COMPILED FROM ' .. path_in .. ' --]] ' --[[SOL OUTPUT--]] 
		out_text = out_text .. output(info.ast, path_in) --[[SOL OUTPUT--]] 
		if not U.write_file(path_out, out_text) then
			printf_err("Failed to open %q for writing", path_out) --[[SOL OUTPUT--]] 
			os.exit(4) --[[SOL OUTPUT--]] 
		else
			if _G.g_spam then
				U.printf("File written to %q", path_out) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			U.write_protect(path_out) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if info.type and path_out then
		-- TODO: output .solh file with type deductions
		--U.write_file(path_out .. '.h', T.name(info.type) .. '\n')
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function compile_file(path_in, path_out)
	local settings = (function()
		if path.extension(path_in):lower() == '.sol' then
			return Parser.SOL_SETTINGS --[[SOL OUTPUT--]] 
		else
			return Parser.LUA_SETTINGS --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end)() --[[SOL OUTPUT--]] 

	local info = parse_module({}, path_in) --[[SOL OUTPUT--]] 
	output_module(info, path_in, path_out) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


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
		]]) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

local g_profiler = nil --[[SOL OUTPUT--]] 


if #arg == 0 then
	print_help() --[[SOL OUTPUT--]] 
	os.exit(-1) --[[SOL OUTPUT--]] 
else
	local g_write_lua = true --[[SOL OUTPUT--]] 
	local g_out_dir = '' --[[SOL OUTPUT--]] 
	local ix = 1 --[[SOL OUTPUT--]] 
	local num_files = 0 --[[SOL OUTPUT--]] 

	while ix <= #arg do
		local a = arg[ix] --[[SOL OUTPUT--]] 
		ix = ix + 1 --[[SOL OUTPUT--]] 

		if a == '-h' or a == '--help' then
			print_help() --[[SOL OUTPUT--]] 

		elseif a == '-o' then
			g_out_dir = arg[ix] .. '/' --[[SOL OUTPUT--]] 
			ix = ix + 1 --[[SOL OUTPUT--]] 
			print('Files will be written to ' .. g_out_dir) --[[SOL OUTPUT--]] 

		elseif a == '-p' or a == '--parse' then
			-- e.g. for syntax checking
			g_write_lua = false --[[SOL OUTPUT--]] 

		elseif a == '-s' or a == '--spam' then
			_G.g_spam = true --[[SOL OUTPUT--]] 

		elseif a == '-e0' then
			_G.g_ignore_errors = true --[[SOL OUTPUT--]] 

		elseif a == '--profile' then
			g_profiler = require 'ProFi' --[[SOL OUTPUT--]] 
			print('Profiling (this may take a while)...') --[[SOL OUTPUT--]] 
			g_profiler:start() --[[SOL OUTPUT--]] 

		elseif a == '-d' or a == '--debug' then
			D.activate() --[[SOL OUTPUT--]] 
			print('Debugger activated') --[[SOL OUTPUT--]] 

		elseif a == '--check' then
			local path_in = arg[ix] --[[SOL OUTPUT--]] 
			ix = ix + 1 --[[SOL OUTPUT--]] 
			
			_G.g_local_parse = true --[[SOL OUTPUT--]]  -- FIXME: else too slow for live-parsing

			-- Read entire stdin
			print("Reading from stdin...") --[[SOL OUTPUT--]] 
			local file_content = U.read_entire_stdin() --[[SOL OUTPUT--]] 
			U.printf("Parsing " .. path_in) --[[SOL OUTPUT--]] 
			local info = parse_module_str({}, path_in, file_content) --[[SOL OUTPUT--]] 

			-- TODO: write output?
			--output_module(info, path_in, path_out)

			num_files = num_files + 1 --[[SOL OUTPUT--]] 

		elseif a:match('^-') then
			U.printf_err("Unknown option: %q", a) --[[SOL OUTPUT--]] 
			print_help() --[[SOL OUTPUT--]] 
			os.exit(1337) --[[SOL OUTPUT--]] 

		else
			local path_in = a --[[SOL OUTPUT--]] 
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending: %q", path_in) --[[SOL OUTPUT--]] 
				os.exit(-2) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if g_write_lua then
				path.mkdir( g_out_dir ) --[[SOL OUTPUT--]]  -- Ensure we can write there

				local dir, fn  = path.splitpath(path_in) --[[SOL OUTPUT--]] 
				local path_out = g_out_dir .. path.splitext(fn) .. '.lua' --[[SOL OUTPUT--]] 
				--local path_out = path_in .. '.lua'
				compile_file(path_in, path_out) --[[SOL OUTPUT--]] 
			else
				compile_file(path_in) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			num_files = num_files + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if num_files == 0 then
		printf_err( "No input!" ) --[[SOL OUTPUT--]] 
		print_help() --[[SOL OUTPUT--]] 
		os.exit(-1337) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

if g_profiler then
	g_profiler:stop() --[[SOL OUTPUT--]] 
	--local REPORT_PATH = 'profiler_report.txt'
	--local REPORT_PATH = os.date("profiler_report_%Y_%m_%d_%X.txt")
	local REPORT_PATH = os.date("profile_reports/profiler_report_%Y_%m_%d__%H_%M_%S.txt") --[[SOL OUTPUT--]] 
	g_profiler:writeReport( REPORT_PATH ) --[[SOL OUTPUT--]] 
	--print( 'Profile report written to ' .. REPORT_PATH)
end --[[SOL OUTPUT--]] 

os.exit(0) --[[SOL OUTPUT--]]  -- Success
 --[[SOL OUTPUT--]] 