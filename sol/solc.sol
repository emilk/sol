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
	sol_dir ..= '/'
else
	sol_dir = lfs.currentdir() .. '/' .. sol_dir .. '/'
end


print("solc: sol_dir: " .. sol_dir)
--print("path.abspath(''): " .. path.dirname(path.abspath('') .. arg[0]))

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path

------------------------------------------------

require 'globals'
local D          = require 'sol_debug'
local output     = require 'output'
local L          = require 'lexer'
local Parser     = require 'parser'
local _          = require 'scope'
local T          = require 'type'
local TypeCheck  = require 'type_check'
local U          = require 'util'
local intrinsics = require 'lua_intrinsics'
local printf_err = U.printf_err

------------------------------------------------

var ast_type_count = {} : {string => uint}
var has_stats_for  = {} : {any}

function collect_stats(ast)
	if type(ast) == 'table' and not has_stats_for[ast] then
		has_stats_for[ast] = true

		if type(ast.ast_type) == 'string' then
			ast_type_count[ast.ast_type] = (ast_type_count[ast.ast_type] or 0) + 1
		end

		for k,v in pairs(ast) do
			collect_stats(v)
		end
	end
end

function print_stats()
	U.printf("Ast type popularity:")
	U.print_sorted_stats(ast_type_count)
end


------------------------------------------------


typedef parse_info = {
	name:            string;
	ast:             any; -- For output
	type:            T.Typelist?; -- What the module returns
	global_vars:     [Variable];
	global_typedefs: { string => T.Type };
}

typedef CURRENTLY_PARSING = false
var     CURRENTLY_PARSING = false
local   FAIL_INFO = { ast = nil, type = T.AnyTypeList }

-- type is CURRENTLY_PARSING during parsing.
var g_modules = {} : {string => parse_info or CURRENTLY_PARSING}

-- Look for moduls in these dirs
var g_mod_paths = { '' }

-- Result of global includes:
var g_globals = {
	global_vars     = {} : [Variable];
	global_typedefs = {} : { string => T.Type };
}


var g_did_warn_about  = {} : {string => bool}
var g_lex_only = false
var g_parse_only = false


local function look_for_module_in(dir: string, mod_name: string) -> string?
	local sol_path = dir .. mod_name .. '.sol'
	if U.file_exists(sol_path) then
		--U.printf("Found moudle at %q", sol_path)
		return sol_path
	end

	local lua_path = dir .. mod_name .. '.lua'

	--U.printf("Looking in %s...", lua_path)

	if U.file_exists(lua_path) then
		--U.printf("Found moudle at %q", lua_path)
		return lua_path
	end

	return nil
end


-- Find path to a module given it's name, and the path to the file doing the require:ing
local function find_moudle(path_in: string, mod_name: string) -> string?
	local dir = path.splitpath(path_in) .. '/'
	if dir == '/' then dir = '' end

	var path = look_for_module_in(dir, mod_name)
	if path then return path end

	for _,dir in ipairs(g_mod_paths) do
		var path = look_for_module_in(dir, mod_name)
		if path then return path end
	end

	return nil
end


------------------------------------------------


local parse_module


------------------------------------------------


-- Returns its type
local function require_module(path_in: string, mod_name: string, module_scope: Scope, req_where: string, req_chain: [string]) -> T.Typelist
	--U.printf('require %q', v)
	req_chain = { unpack(req_chain) }  -- clone
	req_chain #= mod_name

	local mod_path = find_moudle(path_in, mod_name)
	if not mod_path then
		if not g_did_warn_about[mod_name:lower()] then
			g_did_warn_about[mod_name:lower()] = true
			U.printf("WARNING: %s: Failed to find module %q",req_where, mod_name)
		end
		return T.AnyTypeList
	end


	local mod_info = parse_module(req_chain, mod_path)

	if mod_info == FAIL_INFO then
		-- Something went wrong - continue as if everything went right
		return T.AnyTypeList
	end

	if not Scope.GLOBALS_IN_TOP_SCOPE then
		for _,v in ipairs(mod_info.global_vars) do
			--D.break_();
			local existing = module_scope:get_global( v.name )
			if existing and existing ~= v then
				printf_err("Global clash when including module '%s' in %s:"
					     .. "Global variable '%s' re-declared in %s, previously declared in %s",
					mod_name, req_where, v.name, v.where, existing.where)
			end

			if not existing then
				if g_spam then
					U.printf("Adding global '%s'", v.name)
				end
				module_scope:add_global(v)
			end
		end

		for name,type in pairs(mod_info.global_typedefs) do
			--D.break_();
			local existing = module_scope:get_global_type( name )
			if existing and existing ~= type then
				printf_err("Global clash when including module '%s' in %s:"
					     .. "Global type '%s' re-declared in %s, previously declared in %s",
					mod_name, req_where, name, type.where, existing.where)
			end

			if not existing then
				if g_spam then
					U.printf("Adding global '%s'", name)
				end
				module_scope:add_global_type( name, type )
			end
		end
	end

	if mod_info.type then
		return mod_info.type
	else
		-- No return-type
		return T.Void
	end
end


------------------------------------------------


local function parse_module_str(chain: [string], path_in: string, source_text: string) -> parse_info
	--local filename = path.basename( path_in )  -- Keep error messages short
	local filename = path_in   -- Make sure error message point out the file in full

	local module_id = path.abspath( path_in:lower() )

	local is_sol = (path.extension(filename) == '.sol')

	local settings = (is_sol and Parser.SOL_SETTINGS or Parser.LUA_SETTINGS)

	local st, tokens = L.lex_sol(source_text, filename, settings)
	if not st then
		printf_err("Failed to lex %q", path_in)
		g_modules[module_id] = FAIL_INFO
		os.exit(1)
		return FAIL_INFO
	end

	if g_lex_only then
		return {}
	end

	var module_scope = Scope.create_module_scope()

	--------------------------------------------------
	-- Import from global requires:

	for _,v in ipairs(g_globals.global_vars) do
		local existing = module_scope:get_global( v.name )
		if existing and existing ~= v then
			printf_err("Global variable '%s' re-declared in %s, previously declared in %s",
				v.name, v.where, existing.where)
		end

		if not existing then
			module_scope:add_global(v)
		end
	end

	for name,type in pairs(g_globals.global_typedefs) do
		local existing = module_scope:get_global_type( name )
		if existing and existing ~= type then
			printf_err("Global type '%s' re-declared in %s, previously declared in %s",
				name, type.where, existing.where)
		end

		if not existing then
			module_scope:add_global_type( name, type )
		end
	end

	--------------------------------------------------

	local st, ast = Parser.parse_sol(source_text, tokens, filename, settings, module_scope)
	if not st then
		--we failed to parse the file, show why
		printf_err("Failed to parse %q", path_in)
		g_modules[module_id] = FAIL_INFO
		os.exit(2)  -- report the failure
		return FAIL_INFO
	end

	if g_print_stats then
		collect_stats(ast)
	end

	if g_parse_only then
		return {}
	end

	var on_require = function(mod_name: string, req_where: string) -> T.Typelist
		if g_local_parse then
			return T.AnyTypeList
		end

		var ts = require_module(path_in, mod_name, module_scope, req_where, chain)
		D.assert( T.is_type_list(ts) )
		return ts
	end

	local success, type = TypeCheck(ast, filename, on_require, settings)

	if not success then
		U.printf("TypeCheck failed for %q: %s", filename, type)
		local info = { ast = ast, type = T.AnyTypeList }
		g_modules[module_id] = info
		os.exit(3)  -- report the failure
		return info
	end

	if g_spam then
		U.printf("Module %q successfully deduced to type %s", path_in, T.name(type))
	else
		--U.printf("Module %q successfully parsed and checked", module_name)
	end

	--U.printf("Storing result for module %q", module_id)

	local info = {
		--name            = module_name;
		ast             = ast;
		type            = type;
		global_vars     = module_scope:get_global_vars();
		global_typedefs = module_scope:get_global_typedefs();
	}
	g_modules[module_id] = info
	return info
end


-- Returns { ast, type }
parse_module = function(chain: [string], path_in: string) -> parse_info
	local module_id = path.abspath( path_in:lower() )

	local old_info = g_modules[module_id]
	if old_info == CURRENTLY_PARSING then
		printf_err("Module 'require' recusion detected: dependency chain: " .. U.pretty(chain))
		error(-42)
		return FAIL_INFO
	elseif old_info then
		--U.printf('require(%q) had buffered result', path_in)
		return old_info
	end

	g_modules[module_id] = CURRENTLY_PARSING

	if g_spam then
		U.printf("Parsing %q...", path_in)
	end

	local source_text = U.read_entire_file( path_in )

	if not source_text then
		printf_err("'Failed to read %q", path_in)
		g_modules[module_id] = FAIL_INFO
		return FAIL_INFO
	end

	local info = parse_module_str(chain, path_in, source_text)
	return info
end


local function output_module(info: parse_info, path_in: string, path_out: string?, header_path_out: string?)
	if info.ast and path_out then
		U.write_unprotect(path_out) -- Ensure we can write over it

		--local out_text = '--[[ DO NOT MODIFY - COMPILED FROM ' .. path_in .. " on " .. os.date("%Y %b %d  %X") .. ' --]] '
		local out_text = '--[[ DO NOT MODIFY - COMPILED FROM ' .. path_in .. ' --]] '
		out_text ..= output(info.ast, path_in)
		if not U.write_file(path_out, out_text) then
			printf_err("Failed to open %q for writing", path_out)
			os.exit(4)
		else
			if g_spam then
				U.printf("File written to %q", path_out)
			end
			U.write_protect(path_out)
		end
	end


	if info.type and header_path_out then
		--var out_text = "-- Compiled from "..path_in.." on "..os.date("%Y %b %d  %X")..'\n\n'
		var out_text = "-- Compiled from "..path_in..'\n\n'

		for name,type in pairs(info.global_typedefs) do
			out_text ..= "global typedef "..name.." = "..T.name(type).."\n\n"
		end

		for _,v in ipairs(info.global_vars) do
			out_text ..= "global "..v.name.." : "..T.name(v.type).."\n\n"
		end

		out_text ..= "return " .. T.name(info.type)
		U.write_file(header_path_out, out_text)
	end
end


local function compile_file(path_in: string, lua_path_out: string?, header_path_out: string?)
	local info = parse_module({}, path_in)
	output_module(info, path_in, lua_path_out, header_path_out)
end


local function parse_global_require(mod_name: string) -> bool
	var mod_path = mod_name .. '.sol' -- FIXME

	var req_chain = { "[global require]" }
	var mod_info = parse_module(req_chain, mod_path)

	if mod_info == FAIL_INFO then
		return false
	end

	for _,v in ipairs(mod_info.global_vars) do
		if g_spam then
			U.printf("Adding global '%s'", v.name)
		end
		g_globals.global_vars #= v
	end

	for name,type in pairs(mod_info.global_typedefs) do
		if g_spam then
			U.printf("Adding global type '%s'", name)
		end
		g_globals.global_typedefs[name] = type
	end

	return true
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
				Write compiled .lua files here

			-ho header_output_dir
				Write header files here

			-l name
				Require library 'name'

			-m dir
				Look for modules here

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

			-L
				Lex only: Useful for profiling

			-P
				Parse only: Useful for profiling

			-Werror
				Make all warnings into errors.
		]])
end

local g_profiler = nil


if #arg == 0 then
	print_help()
	os.exit(-1)
else
	var g_write_lua    = true
	var g_out_dir      = ''
	var g_header_out_dir = nil : string?
	var ix             = 1
	var num_files      = 0

	intrinsics.add_intrinsics_to_global_scope()

	while ix <= #arg do
		var a = arg[ix]
		ix += 1

		if a == '-h' or a == '--help' then
			print_help()

		elseif a == '-o' then
			g_out_dir = arg[ix] .. '/'
			ix +=  1
			print('Files will be written to ' .. g_out_dir)

		elseif a == '-ho' then
			g_header_out_dir = arg[ix] .. '/'
			ix +=  1
			print('Header files will be written to ' .. g_header_out_dir)
			path.mkdir( g_header_out_dir ) -- Ensure we can write there

		elseif a == '-p' or a == '--parse' then
			-- e.g. for syntax checking
			g_write_lua = false

		elseif a == '-L' then
			-- e.g. for syntax checking
			print('Lex only')
			g_lex_only = true

		elseif a == '-P' then
			-- e.g. for syntax checking
			print('Parse only')
			g_parse_only = true

		elseif a == '-s' or a == '--spam' then
			g_spam = true

		elseif a == '-e0' then
			g_ignore_errors = true

		elseif a == '--profile' then
			g_profiler = require 'ProFi'
			print('Profiling (this may take a while)...')
			g_profiler:start()

		elseif a == '-d' or a == '--debug' then
			D.activate()
			print('Debugger activated')

		elseif a == '--check' then
			local path_in = arg[ix]
			ix +=  1

			--g_local_parse = true

			local module_id = path.abspath( path_in:lower() )

			U.printf("Checking module %q...", module_id)

			if g_modules[module_id] then
				print("Skipping stdin - path already parsed via -l")
			else
				-- Read entire stdin
				print("Reading from stdin...")
				local file_content = U.read_entire_stdin()
				U.printf("Parsing " .. path_in)
				parse_module_str({}, path_in, file_content)
			end

			num_files +=  1

		elseif a == '-l' then
			var mod_name = arg[ix]
			ix +=  1
			if not parse_global_require(mod_name) then
				U.printf_err("Aborting")
				os.exit(123)
			end

		elseif a == '-m' then
			var dir = arg[ix]
			ix +=  1
			g_mod_paths #= dir

		elseif a == '-Werror' then
			g_warnings_as_errors = true

		elseif a:match('^-') then
			U.printf_err("Unknown option: %q", a)
			print_help()
			os.exit(1337)

		else
			local path_in = a

			--[[
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending: %q", path_in)
				os.exit(-2)
			end
			]]

			if g_write_lua then
				path.mkdir( g_out_dir ) -- Ensure we can write there
				local _, filename  = path.splitpath(path_in)
				local lua_path_out = g_out_dir .. path.splitext(filename) .. '.lua'
				local header_path_out = g_header_out_dir and (g_header_out_dir .. path.splitext(filename) .. '.sol')
				compile_file(path_in, lua_path_out, header_path_out)
			else
				compile_file(path_in)
			end

			num_files +=  1
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
	path.mkdir("solc_profile_reports")
	local REPORT_PATH = os.date("solc_profile_reports/profiler_report_%Y_%m_%d__%H_%M_%S.txt")
	g_profiler:writeReport( REPORT_PATH )
	--print( 'Profile report written to ' .. REPORT_PATH)
end

if g_print_stats then
	L.print_stats()
	print_stats()
end

os.exit(0) -- Success
