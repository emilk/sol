var INTRINSICS = [[
	global coroutine = {
		yield = extern : function(...) -> ...;
		wrap  = extern : function(...) -> ...;
	}

	global debug = {
		getinfo = extern : function(...) -> ...;
	}

	global math = {
		min   = extern : function(...: number) -> number;
		max   = extern : function(...: number) -> number;
		abs   = extern : function(number) -> number;
		ceil  = extern : function(number) -> number;
		floor = extern : function(number) -> number;
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
		byte   = extern : function(string, int, int?, int?) -> ...;
		char   = extern : function(string, ... : int) -> string;
		format = extern : function(...) -> ...;
		rep    = extern : function(...) -> ...;
		sub    = extern : function(...) -> ...;
	}

	global table = {
		concat = extern : function(...) -> ...;
		insert = extern : function(...) -> ...;
		sort   = extern : function(...) -> ...;
		remove = extern : function(...) -> ...;
	}
]]



----------------------------------------------


local   P         = require 'parser'
local   L         = require 'lexer'
local   TypeCheck = require 'type_check'
require 'scope'

local M = {}

function M.add_intrinsics_to_global_scope()
	var global_scope = Scope.get_global_scope()
	var module_scope = Scope.create_module_scope()
	var scope = module_scope

	var filename = "INTRINSICS"
	var settings = P.SOL_SETTINGS

	local st, tokens = L.lex_sol(INTRINSICS, filename, settings)
	assert(st)
	local st, ast = P.parse_sol(INTRINSICS, tokens, filename, settings, scope)
	assert(st)
	local st, type = TypeCheck(ast, filename, nil, settings)
	assert(st)

	global_scope.fixed = false

	for _,v in ipairs(module_scope:get_global_vars()) do
		global_scope:add_global(v)
	end

	for name,type in pairs(module_scope:get_global_typedefs()) do
		global_scope:add_global_type( name, type )
	end

	global_scope.fixed = true
end

return M