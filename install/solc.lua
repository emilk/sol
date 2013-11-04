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
	sol_dir = sol_dir .. ( '/' ) --[[SOL OUTPUT--]] 
else
	sol_dir = lfs.currentdir() .. '/' .. sol_dir .. '/' --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


print("solc: sol_dir: " .. sol_dir) --[[SOL OUTPUT--]] 
--print("path.abspath(''): " .. path.dirname(path.abspath('') .. arg[0]))

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path --[[SOL OUTPUT--]] 

------------------------------------------------

require 'globals' --[[SOL OUTPUT--]] 
local D          = require 'sol_debug' --[[SOL OUTPUT--]] 
local output     = require 'output' --[[SOL OUTPUT--]] 
local L          = require 'lexer' --[[SOL OUTPUT--]] 
local Parser     = require 'parser' --[[SOL OUTPUT--]] 
local _          = require 'scope' --[[SOL OUTPUT--]] 
local T          = require 'type' --[[SOL OUTPUT--]] 
local TypeCheck  = require 'type_check' --[[SOL OUTPUT--]] 
local U          = require 'util' --[[SOL OUTPUT--]] 
local intrinsics = require 'lua_intrinsics' --[[SOL OUTPUT--]] 
local printf_err = U.printf_err --[[SOL OUTPUT--]] 

------------------------------------------------

local ast_type_count = {} --[[SOL OUTPUT--]] 
local has_stats_for  = {} --[[SOL OUTPUT--]]  local 

function collect_stats(ast)
	if type(ast) == 'table' and not has_stats_for[ast] then
		has_stats_for[ast] = true --[[SOL OUTPUT--]] 

		if type(ast.ast_type) == 'string' then
			ast_type_count[ast.ast_type] = (ast_type_count[ast.ast_type] or 0) + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for k,v in pairs(ast) do
			collect_stats(v) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]]  local 

function print_stats()
	U.printf("Ast type popularity:") --[[SOL OUTPUT--]] 
	U.print_sorted_stats(ast_type_count) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 
local     CURRENTLY_PARSING = false --[[SOL OUTPUT--]] 
local   FAIL_INFO = { ast = nil













, type = T.AnyTypeList } --[[SOL OUTPUT--]] 

-- type is CURRENTLY_PARSING during parsing.
local g_modules = {} --[[SOL OUTPUT--]] 

-- Look for moduls in these dirs
local g_mod_paths = { '' } --[[SOL OUTPUT--]] 

-- Result of global includes:
local g_globals = {
	global_vars     = {};
	global_typedefs = {};
} --[[SOL OUTPUT--]] 


local g_did_warn_about  = {} --[[SOL OUTPUT--]] 
local g_lex_only = false --[[SOL OUTPUT--]] 
local g_parse_only = false --[[SOL OUTPUT--]] 


local function look_for_module_in(dir, mod_name)
	local sol_path = dir .. mod_name .. '.sol' --[[SOL OUTPUT--]] 
	if U.file_exists(sol_path) then
		--U.printf("Found moudle at %q", sol_path)
		return sol_path --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local lua_path = dir .. mod_name .. '.lua' --[[SOL OUTPUT--]] 

	--U.printf("Looking in %s...", lua_path)

	if U.file_exists(lua_path) then
		--U.printf("Found moudle at %q", lua_path)
		return lua_path --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Find path to a module given it's name, and the path to the file doing the require:ing
local function find_moudle(path_in, mod_name)
	local dir = path.splitpath(path_in) .. '/' --[[SOL OUTPUT--]] 
	if dir == '/' then dir = '' --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	local path = look_for_module_in(dir, mod_name) --[[SOL OUTPUT--]] 
	if path then return path --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	for _,dir in ipairs(g_mod_paths) do
		local path = look_for_module_in(dir, mod_name) --[[SOL OUTPUT--]] 
		if path then return path --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


------------------------------------------------


local parse_module --[[SOL OUTPUT--]] 


------------------------------------------------


-- Returns its type
local function require_module(path_in, mod_name, module_scope, req_where, req_chain)
	--U.printf('require %q', v)
	req_chain = { unpack(req_chain) } --[[SOL OUTPUT--]]   -- clone
	req_chain [ # req_chain + 1 ] = mod_name --[[SOL OUTPUT--]] 

	local mod_path = find_moudle(path_in, mod_name) --[[SOL OUTPUT--]] 
	if not mod_path then
		if not g_did_warn_about[mod_name:lower()] then
			g_did_warn_about[mod_name:lower()] = true --[[SOL OUTPUT--]] 
			U.printf("WARNING: %s: Failed to find module %q",req_where, mod_name) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return T.AnyTypeList --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local mod_info = parse_module(req_chain, mod_path) --[[SOL OUTPUT--]] 

	if mod_info == FAIL_INFO then
		-- Something went wrong - continue as if everything went right
		return T.AnyTypeList --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if not Scope.GLOBALS_IN_TOP_SCOPE then
		for _,v in ipairs(mod_info.global_vars) do
			--D.break_();
			local existing = module_scope:get_global( v.name ) --[[SOL OUTPUT--]] 
			if existing and existing ~= v then
				printf_err("Global clash when including module '%s' in %s:"
					     .. "Global variable '%s' re-declared in %s, previously declared in %s",
					mod_name, req_where, v.name, v.where, existing.where) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if not existing then
				if g_spam then
					U.printf("Adding global '%s'", v.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				module_scope:add_global(v) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for name,type in pairs(mod_info.global_typedefs) do
			--D.break_();
			local existing = module_scope:get_global_type( name ) --[[SOL OUTPUT--]] 
			if existing and existing ~= type then
				printf_err("Global clash when including module '%s' in %s:"
					     .. "Global type '%s' re-declared in %s, previously declared in %s",
					mod_name, req_where, name, type.where, existing.where) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if not existing then
				if g_spam then
					U.printf("Adding global '%s'", name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				module_scope:add_global_type( name, type ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if mod_info.type then
		return mod_info.type --[[SOL OUTPUT--]] 
	else
		-- No return-type
		return T.Void --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


------------------------------------------------


local function parse_module_str(chain, path_in, source_text)
	--local filename = path.basename( path_in )  -- Keep error messages short
	local filename = path_in --[[SOL OUTPUT--]]    -- Make sure error message point out the file in full

	local module_id = path.abspath( path_in:lower() ) --[[SOL OUTPUT--]] 

	local is_sol = (path.extension(filename) == '.sol') --[[SOL OUTPUT--]] 

	local settings = (is_sol and Parser.SOL_SETTINGS or Parser.LUA_SETTINGS) --[[SOL OUTPUT--]] 

	local st, tokens = L.lex_sol(source_text, filename, settings) --[[SOL OUTPUT--]] 
	if not st then
		printf_err("Failed to lex %q", path_in) --[[SOL OUTPUT--]] 
		g_modules[module_id] = FAIL_INFO --[[SOL OUTPUT--]] 
		os.exit(1) --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if g_lex_only then
		return {} --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local module_scope = Scope.create_module_scope() --[[SOL OUTPUT--]] 

	--------------------------------------------------
	-- Import from global requires:

	for _,v in ipairs(g_globals.global_vars) do
		local existing = module_scope:get_global( v.name ) --[[SOL OUTPUT--]] 
		if existing and existing ~= v then
			printf_err("Global variable '%s' re-declared in %s, previously declared in %s",
				v.name, v.where, existing.where) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if not existing then
			module_scope:add_global(v) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for name,type in pairs(g_globals.global_typedefs) do
		local existing = module_scope:get_global_type( name ) --[[SOL OUTPUT--]] 
		if existing and existing ~= type then
			printf_err("Global type '%s' re-declared in %s, previously declared in %s",
				name, type.where, existing.where) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if not existing then
			module_scope:add_global_type( name, type ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--------------------------------------------------

	local st, ast = Parser.parse_sol(source_text, tokens, filename, settings, module_scope) --[[SOL OUTPUT--]] 
	if not st then
		--we failed to parse the file, show why
		printf_err("Failed to parse %q", path_in) --[[SOL OUTPUT--]] 
		g_modules[module_id] = FAIL_INFO --[[SOL OUTPUT--]] 
		os.exit(2) --[[SOL OUTPUT--]]   -- report the failure
		return FAIL_INFO --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if g_print_stats then
		collect_stats(ast) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if g_parse_only then
		return {} --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local on_require = function(mod_name, req_where)
		if g_local_parse then
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local ts = require_module(path_in, mod_name, module_scope, req_where, chain) --[[SOL OUTPUT--]] 
		D.assert( T.is_type_list(ts) ) --[[SOL OUTPUT--]] 
		return ts --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local success, type = TypeCheck(ast, filename, on_require, settings) --[[SOL OUTPUT--]] 

	if not success then
		U.printf("TypeCheck failed for %q: %s", filename, type) --[[SOL OUTPUT--]] 
		local info = { ast = ast, type = T.AnyTypeList } --[[SOL OUTPUT--]] 
		g_modules[module_id] = info --[[SOL OUTPUT--]] 
		os.exit(3) --[[SOL OUTPUT--]]   -- report the failure
		return info --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if g_spam then
		U.printf("Module %q successfully deduced to type %s", path_in, T.name(type)) --[[SOL OUTPUT--]] 
	else
		--U.printf("Module %q successfully parsed and checked", module_name)
	end --[[SOL OUTPUT--]] 

	--U.printf("Storing result for module %q", module_id)

	local info = {
		--name            = module_name;
		ast             = ast;
		type            = type;
		global_vars     = module_scope:get_global_vars();
		global_typedefs = module_scope:get_global_typedefs();
	} --[[SOL OUTPUT--]] 
	g_modules[module_id] = info --[[SOL OUTPUT--]] 
	return info --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Returns { ast, type }
parse_module = function(chain, path_in)
	local module_id = path.abspath( path_in:lower() ) --[[SOL OUTPUT--]] 

	local old_info = g_modules[module_id] --[[SOL OUTPUT--]] 
	if old_info == CURRENTLY_PARSING then
		printf_err("Module 'require' recusion detected: dependency chain: " .. U.pretty(chain)) --[[SOL OUTPUT--]] 
		error(-42) --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	elseif old_info then
		--U.printf('require(%q) had buffered result', path_in)
		return old_info --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	g_modules[module_id] = CURRENTLY_PARSING --[[SOL OUTPUT--]] 

	if g_spam then
		U.printf("Parsing %q...", path_in) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local source_text = U.read_entire_file( path_in ) --[[SOL OUTPUT--]] 

	if not source_text then
		printf_err("'Failed to read %q", path_in) --[[SOL OUTPUT--]] 
		g_modules[module_id] = FAIL_INFO --[[SOL OUTPUT--]] 
		return FAIL_INFO --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local info = parse_module_str(chain, path_in, source_text) --[[SOL OUTPUT--]] 
	return info --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function output_module(info, path_in, path_out, header_path_out)
	if info.ast and path_out then
		U.write_unprotect(path_out) --[[SOL OUTPUT--]]  -- Ensure we can write over it

		--local out_text = '--[[ DO NOT MODIFY - COMPILED FROM ' .. path_in .. " on " .. os.date("%Y %b %d  %X") .. ' --]] '
		local out_text = '--[[ DO NOT MODIFY - COMPILED FROM ' .. path_in .. ' --]] ' --[[SOL OUTPUT--]] 
		out_text = out_text .. ( output(info.ast, path_in) ) --[[SOL OUTPUT--]] 
		if not U.write_file(path_out, out_text) then
			printf_err("Failed to open %q for writing", path_out) --[[SOL OUTPUT--]] 
			os.exit(4) --[[SOL OUTPUT--]] 
		else
			if g_spam then
				U.printf("File written to %q", path_out) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			U.write_protect(path_out) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	if info.type and header_path_out then
		--var out_text = "-- Compiled from "..path_in.." on "..os.date("%Y %b %d  %X")..'\n\n'
		local out_text = "-- Compiled from "..path_in..'\n\n' --[[SOL OUTPUT--]] 

		for name,type in pairs(info.global_typedefs) do
			out_text = out_text .. ( "global typedef "..name.." = "..T.name(type).."\n\n" ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for _,v in ipairs(info.global_vars) do
			out_text = out_text .. ( "global "..v.name.." : "..T.name(v.type).."\n\n" ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		out_text = out_text .. ( "return " .. T.name(info.type) ) --[[SOL OUTPUT--]] 
		U.write_file(header_path_out, out_text) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function compile_file(path_in, lua_path_out, header_path_out)
	local info = parse_module({}, path_in) --[[SOL OUTPUT--]] 
	output_module(info, path_in, lua_path_out, header_path_out) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function parse_global_require(mod_name)
	local mod_path = mod_name .. '.sol' --[[SOL OUTPUT--]]  -- FIXME

	local req_chain = { "[global require]" } --[[SOL OUTPUT--]] 
	local mod_info = parse_module(req_chain, mod_path) --[[SOL OUTPUT--]] 

	if mod_info == FAIL_INFO then
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for _,v in ipairs(mod_info.global_vars) do
		if g_spam then
			U.printf("Adding global '%s'", v.name) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		g_globals.global_vars [ # g_globals . global_vars + 1 ] = v --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for name,type in pairs(mod_info.global_typedefs) do
		if g_spam then
			U.printf("Adding global type '%s'", name) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		g_globals.global_typedefs[name] = type --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return true --[[SOL OUTPUT--]] 
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

			--single-line
				Errors and warnings will be printed on single lines

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
		]]) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

local g_profiler = nil --[[SOL OUTPUT--]] 


if #arg == 0 then
	print_help() --[[SOL OUTPUT--]] 
	os.exit(-1) --[[SOL OUTPUT--]] 
else
	local g_write_lua    = true --[[SOL OUTPUT--]] 
	local g_out_dir      = '' --[[SOL OUTPUT--]] 
	local g_header_out_dir = nil --[[SOL OUTPUT--]] 
	local ix             = 1 --[[SOL OUTPUT--]] 
	local num_files      = 0 --[[SOL OUTPUT--]] 

	intrinsics.add_intrinsics_to_global_scope() --[[SOL OUTPUT--]] 

	while ix <= #arg do
		local a = arg[ix] --[[SOL OUTPUT--]] 
		ix = ix + ( 1 ) --[[SOL OUTPUT--]] 

		if a == '-h' or a == '--help' then
			print_help() --[[SOL OUTPUT--]] 
			os.exit(0) --[[SOL OUTPUT--]] 

		elseif a == '-o' then
			g_out_dir = arg[ix] .. '/' --[[SOL OUTPUT--]] 
			ix = ix + (  1 ) --[[SOL OUTPUT--]] 
			print('Files will be written to ' .. g_out_dir) --[[SOL OUTPUT--]] 

		elseif a == '-ho' then
			g_header_out_dir = arg[ix] .. '/' --[[SOL OUTPUT--]] 
			ix = ix + (  1 ) --[[SOL OUTPUT--]] 
			print('Header files will be written to ' .. g_header_out_dir) --[[SOL OUTPUT--]] 
			path.mkdir( g_header_out_dir ) --[[SOL OUTPUT--]]  -- Ensure we can write there

		elseif a == '-p' or a == '--parse' then
			-- e.g. for syntax checking
			g_write_lua = false --[[SOL OUTPUT--]] 

		elseif a == '-L' then
			-- e.g. for syntax checking
			print('Lex only') --[[SOL OUTPUT--]] 
			g_lex_only = true --[[SOL OUTPUT--]] 

		elseif a == '-P' then
			-- e.g. for syntax checking
			print('Parse only') --[[SOL OUTPUT--]] 
			g_parse_only = true --[[SOL OUTPUT--]] 

		elseif a == '-s' or a == '--spam' then
			g_spam = true --[[SOL OUTPUT--]] 

		elseif a == '--single-line' then
			g_one_line_errors = true --[[SOL OUTPUT--]] 

		elseif a == '-e0' then
			g_ignore_errors = true --[[SOL OUTPUT--]] 

		elseif a == '--profile' then
			g_profiler = require 'ProFi' --[[SOL OUTPUT--]] 
			print('Profiling (this may take a while)...') --[[SOL OUTPUT--]] 
			g_profiler:start() --[[SOL OUTPUT--]] 

		elseif a == '-d' or a == '--ebug' then
			D.activate() --[[SOL OUTPUT--]] 
			print('Debugger activated') --[[SOL OUTPUT--]] 

		elseif a == '--check' then
			local path_in = arg[ix] --[[SOL OUTPUT--]] 
			ix = ix + (  1 ) --[[SOL OUTPUT--]] 

			--g_local_parse = true

			local module_id = path.abspath( path_in:lower() ) --[[SOL OUTPUT--]] 

			U.printf("Checking module %q...", module_id) --[[SOL OUTPUT--]] 

			if g_modules[module_id] then
				print("Skipping stdin - path already parsed via -l") --[[SOL OUTPUT--]] 
			else
				-- Read entire stdin
				print("Reading from stdin...") --[[SOL OUTPUT--]] 
				local file_content = U.read_entire_stdin() --[[SOL OUTPUT--]] 
				U.printf("Parsing " .. path_in) --[[SOL OUTPUT--]] 
				parse_module_str({}, path_in, file_content) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			num_files = num_files + (  1 ) --[[SOL OUTPUT--]] 

		elseif a == '-l' then
			local mod_name = arg[ix] --[[SOL OUTPUT--]] 
			ix = ix + (  1 ) --[[SOL OUTPUT--]] 
			if not parse_global_require(mod_name) then
				U.printf_err("Aborting") --[[SOL OUTPUT--]] 
				os.exit(123) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif a == '-m' then
			local dir = arg[ix] --[[SOL OUTPUT--]] 
			ix = ix + (  1 ) --[[SOL OUTPUT--]] 
			g_mod_paths [ # g_mod_paths + 1 ] = dir --[[SOL OUTPUT--]] 

		elseif a == '-Werror' then
			g_warnings_as_errors = true --[[SOL OUTPUT--]] 

		elseif a:match('^-') then
			U.printf_err("Unknown option: %q", a) --[[SOL OUTPUT--]] 
			print_help() --[[SOL OUTPUT--]] 
			os.exit(1337) --[[SOL OUTPUT--]] 

		-- TODO: --  (meaning all subsequent arguments are files and not options)

		else
			local path_in = a --[[SOL OUTPUT--]] 

			--[[
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending: %q", path_in)
				os.exit(-2)
			end
			]]

			if g_write_lua then
				path.mkdir( g_out_dir ) --[[SOL OUTPUT--]]  -- Ensure we can write there
				local _, filename  = path.splitpath(path_in) --[[SOL OUTPUT--]] 
				local lua_path_out = g_out_dir .. path.splitext(filename) .. '.lua' --[[SOL OUTPUT--]] 
				local header_path_out = g_header_out_dir and (g_header_out_dir .. path.splitext(filename) .. '.sol') --[[SOL OUTPUT--]] 
				compile_file(path_in, lua_path_out, header_path_out) --[[SOL OUTPUT--]] 
			else
				compile_file(path_in) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			num_files = num_files + (  1 ) --[[SOL OUTPUT--]] 
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
	path.mkdir("solc_profile_reports") --[[SOL OUTPUT--]] 
	local REPORT_PATH = os.date("solc_profile_reports/profiler_report_%Y_%m_%d__%H_%M_%S.txt") --[[SOL OUTPUT--]] 
	g_profiler:writeReport( REPORT_PATH ) --[[SOL OUTPUT--]] 
	--print( 'Profile report written to ' .. REPORT_PATH)
end --[[SOL OUTPUT--]] 

if g_print_stats then
	L.print_stats() --[[SOL OUTPUT--]] 
	print_stats() --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

os.exit(0) --[[SOL OUTPUT--]]  -- Success
 --[[SOL OUTPUT--]] 