--[[ DO NOT MODIFY - COMPILED FROM sol/lua_intrinsics.sol --]] local INTRINSICS = [[
	global debug = {
		getinfo = extern : function(...: number) -> ...;
	}

	global math = {
		min   = extern : function(...: number) -> number;
		max   = extern : function(...: number) -> number;
		abs   = extern : function(...: number) -> number;
		ceil  = extern : function(...: number) -> number;
		floor = extern : function(...: number) -> number;
		huge  = extern : number;
	}

	global io = {
		open    = extern : function(...) -> ...;
		read    = extern : function(...) -> ...;
		stderr  = extern;
	}

	global os = {
		exit    = extern : function(...) -> ...;
		date    = extern : function(...) -> ...;
		getenv  = extern : function(...) -> ...;
		execute = extern : function(...) -> ...;
	}

	global string = {
		format = extern : function(...) -> ...;
		byte   = extern : function(...) -> ...;
		rep    = extern : function(...) -> ...;
		sub    = extern : function(...) -> ...;
	}

	global table = {
		concat = extern : function(...) -> ...;
		insert = extern : function(...) -> ...;
		sort   = extern : function(...) -> ...;
		remove = extern : function(...) -> ...;
	}
]] --[[SOL OUTPUT--]] 



----------------------------------------------


local   P         = require 'parser' --[[SOL OUTPUT--]] 
local   L         = require 'lexer' --[[SOL OUTPUT--]] 
local   TypeCheck = require 'type_check' --[[SOL OUTPUT--]] 
require 'scope' --[[SOL OUTPUT--]] 

local M = {} --[[SOL OUTPUT--]] 

function M.add_intrinsics_to_global_scope()
	local global_scope = Scope.get_global_scope() --[[SOL OUTPUT--]] 
	local module_scope = Scope.create_module_scope() --[[SOL OUTPUT--]] 
	local scope = module_scope --[[SOL OUTPUT--]] 

	local filename = "INTRINSICS" --[[SOL OUTPUT--]] 
	local settings = P.SOL_SETTINGS --[[SOL OUTPUT--]] 

	local st, tokens = L.lex_sol(INTRINSICS, filename, settings) --[[SOL OUTPUT--]] 
	assert(st) --[[SOL OUTPUT--]] 
	local st, ast = P.parse_sol(INTRINSICS, tokens, filename, settings, scope) --[[SOL OUTPUT--]] 
	assert(st) --[[SOL OUTPUT--]] 
	local st, type = TypeCheck(ast, filename, nil, settings) --[[SOL OUTPUT--]] 
	assert(st) --[[SOL OUTPUT--]] 

	global_scope.fixed = false --[[SOL OUTPUT--]] 

	for _,v in ipairs(module_scope:get_global_vars()) do
		global_scope:add_global(v) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for name,type in pairs(module_scope:get_global_typedefs()) do
		global_scope:add_global_type( name, type ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	global_scope.fixed = true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return M --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 