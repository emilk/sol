--[[ DO NOT MODIFY - COMPILED FROM sol/sol.sol --]] -- For running a .sol without outputting a .lua to disk
-- TODO: compiler.sol continaing thing common to sol.sol and solc.sol

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

-- Ensure the local includes work:
package.path = sol_dir..'?.lua;' .. package.path
	

------------------------------------------------

local FormatIdentity  = require 'format_identity'
local Lexer           = require 'lexer'
local Parser          = require 'parser'
local S               = require 'scope'
local T               = require 'type'
local TypeCheck       = require 'type_check'
local util            = require 'util'
local printf_err = util.printf_err


local function compile_sol(source_text)
	local filename = "input"
	local settings = Parser.SolSettings

	local st, tokens = Lexer.LexSol(source_text, filename, settings)
	if not st then
		os.exit(1)
		return nil
	end

	local module_scope = S.Scope:create_module_scope()

	local st, ast = Parser.ParseSol(source_text, tokens, filename, settings, module_scope)
	if not st then
		os.exit(2)
		return nil
	end

	local on_require = function(name, where)
		return T.Any
	end

	local st, type = TypeCheck(ast, filename, on_require, settings)

	if not st then
		os.exit(3)
		return nil
	end

	local str = FormatIdentity(ast, filename)

	return str
end


local function run_sol(sol)
	local lua = compile_sol(sol)
	if lua then
		local f = loadstring(lua)
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
				Print this help text

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
	local g_write_lua = true
	local g_out_dir = 'build/'  -- TODO: use penlight for this
	local ix = 1
	local num_files = 0

	while ix <= #arg do
		local a = arg[ix]
		ix = ix + 1

		if a == '-h' or a == '--help' then
			print_help()
		elseif a == '-s' then
			_G.g_spam = true
		elseif a == '-e0' then
			_G.g_ignore_errors = true
		else
			local path_in = a
			if path.extension(path_in) ~= '.sol' then
				printf_err( "Input file must have .sol ending" )
				os.exit(-2)
			end

			local sol = util.read_entire_file( path_in )

			if not sol then
				printf_err( "Input file not found" )
				os.exit(-3)
			end

			run_sol( sol )

			num_files = num_files + 1
		end
	end

	if num_files == 0 then
		printf_err( "No input!" )
		print_help()
		os.exit(-1337)
	end
end

os.exit(0) -- Success
