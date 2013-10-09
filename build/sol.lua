--[[ DO NOT MODIFY - COMPILED FROM sol/sol.sol on 2013 Oct 09  22:26:40 --]] -- For running a .sol without outputting a .lua to disk
-- TODO: compiler.sol continaing thing common to sol.sol and solc.sol

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

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path --[[SOL OUTPUT--]] 
	

------------------------------------------------

local output     = require 'output' --[[SOL OUTPUT--]] 
local Lexer      = require 'lexer' --[[SOL OUTPUT--]] 
local Parser     = require 'parser' --[[SOL OUTPUT--]] 
local S          = require 'scope' --[[SOL OUTPUT--]] 
local T          = require 'type' --[[SOL OUTPUT--]] 
local TypeCheck  = require 'type_check' --[[SOL OUTPUT--]] 
local U          = require 'util' --[[SOL OUTPUT--]] 
local printf_err = U.printf_err --[[SOL OUTPUT--]] 


local function compile_sol(source_text)
	local filename = "input" --[[SOL OUTPUT--]] 
	local settings = Parser.SOL_SETTINGS --[[SOL OUTPUT--]] 

	local st, tokens = Lexer.lex_sol(source_text, filename, settings) --[[SOL OUTPUT--]] 
	if not st then
		os.exit(1) --[[SOL OUTPUT--]] 
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local module_scope = Scope.create_module_scope() --[[SOL OUTPUT--]] 

	local st, ast = Parser.parse_sol(source_text, tokens, filename, settings, module_scope) --[[SOL OUTPUT--]] 
	if not st then
		os.exit(2) --[[SOL OUTPUT--]] 
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local on_require = function(_,_)
		return T.Any --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local st, _ = TypeCheck(ast, filename, on_require, settings) --[[SOL OUTPUT--]] 

	if not st then
		os.exit(3) --[[SOL OUTPUT--]] 
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local str = output(ast, filename) --[[SOL OUTPUT--]] 

	return str --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function run_sol(sol)
	local lua = compile_sol(sol) --[[SOL OUTPUT--]] 
	if lua then
		local f = loadstring(lua) --[[SOL OUTPUT--]] 
		if f then
			f() --[[SOL OUTPUT--]] 
		else
			printf_err("loadstring returned nil") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 



local function print_help()
	print([[
		NAME:
		    sol - Sol interpreter

		SYNOPSIS
			sol [ options ] [ filenames ]

		EXAMPLE
			lua sol.lua file.sol

		DESCRIPTION
			sol runs a .sol file

		OPTIONS
			-h or --help
				print this help text

			-s
				Spam mode: Will print extensive trace text (for debugging solc)

			-e0
				Ignore all errors and push through

		AUTHOR
			Emil Ernerfeldt
		]]) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


if #arg == 0 then
	print_help() --[[SOL OUTPUT--]] 
	os.exit(-1) --[[SOL OUTPUT--]] 
else
	local g_write_lua = true --[[SOL OUTPUT--]] 
	local ix          = 1 --[[SOL OUTPUT--]] 
	local num_files   = 0 --[[SOL OUTPUT--]] 

	while ix <= #arg do
		local a = arg[ix] --[[SOL OUTPUT--]] 
		ix = ix + 1 --[[SOL OUTPUT--]] 

		if a == '-h' or a == '--help' then
			print_help() --[[SOL OUTPUT--]] 
		elseif a == '-s' then
			_G.g_spam = true --[[SOL OUTPUT--]] 
		elseif a == '-e0' then
			_G.g_ignore_errors = true --[[SOL OUTPUT--]] 
		else
			local path_in = a --[[SOL OUTPUT--]] 
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending" ) --[[SOL OUTPUT--]] 
				os.exit(-2) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local sol = U.read_entire_file( path_in ) --[[SOL OUTPUT--]] 

			if not sol then
				printf_err( "Input file not found" ) --[[SOL OUTPUT--]] 
				os.exit(-3) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			run_sol( sol ) --[[SOL OUTPUT--]] 

			num_files = num_files + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if num_files == 0 then
		printf_err( "No input!" ) --[[SOL OUTPUT--]] 
		print_help() --[[SOL OUTPUT--]] 
		os.exit(-1337) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

os.exit(0) --[[SOL OUTPUT--]]  -- Success
 --[[SOL OUTPUT--]] 