-- For running a .sol without outputting a .lua to disk
-- TODO: compiler.sol continaing thing common to sol.sol and solc.sol

require 'globals'
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

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path


------------------------------------------------

local output     = require 'output'
local Lexer      = require 'lexer'
local Parser     = require 'parser'
local _          = require 'scope'
local T          = require 'type'
local TypeCheck  = require 'type_check'
local U          = require 'util'
local printf_err = U.printf_err


local function compile_sol(source_text: string) -> string or nil
	local filename = "input"
	local settings = Parser.SOL_SETTINGS

	local st, tokens = Lexer.lex_sol(source_text, filename, settings)
	if not st then
		os.exit(1)
		return nil
	end

	var module_scope = Scope.create_module_scope()

	local st, ast = Parser.parse_sol(source_text, tokens, filename, settings, module_scope)
	if not st then
		os.exit(2)
		return nil
	end

	local on_require = function(_,_) -> T.Typelist
		return T.AnyTypeList
	end

	local st, _ = TypeCheck(ast, filename, on_require, settings)

	if not st then
		os.exit(3)
		return nil
	end

	local str = output(ast, filename)

	return str
end


local function run_sol(sol: string)
	local lua = compile_sol(sol)
	if lua then
		local f = load(lua)
		if f then
			f()
		else
			printf_err("loadstring returned nil")
		end
	end
end



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
		]])
end


if #arg == 0 then
	print_help()
	os.exit(-1)
else
	local ix          = 1
	local num_files   = 0

	while ix <= #arg do
		local a = arg[ix]
		ix +=  1

		if a == '-h' or a == '--help' then
			print_help()
		elseif a == '-s' then
			g_spam = true
		elseif a == '-e0' then
			g_ignore_errors = true
		else
			local path_in = a
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending" )
				os.exit(-2)
			end

			local sol = U.read_entire_file( path_in )

			if not sol then
				printf_err( "Input file not found" )
				os.exit(-3)
			end

			run_sol( sol )

			num_files +=  1
		end
	end

	if num_files == 0 then
		printf_err( "No input!" )
		print_help()
		os.exit(-1337)
	end
end

os.exit(0) -- Success
