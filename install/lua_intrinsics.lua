--[[ DO NOT MODIFY - COMPILED FROM sol/lua_intrinsics.sol --]] local INTRINSICS = [[
	global assert = extern : function(any, string?, ...) -> ...
	global collectgarbage = extern : function("collect" or "stop" or "restart" or "count" or "step" or "setpause" or "setstepmul" or "isrunning", any?) -> ...
	global dofile = extern : function(string?) -> ...
	global error = extern : function(any, int?) -> ... -- TODO: return never-type
	global print = extern : function(...) -> void
	global tonumber = extern : function(any, uint?) -> number?
	global tostring = extern : function(any, uint?) -> string
	global type = extern : function(any) -> "nil" or "number" or "string" or "boolean" or "table" or "function" or "thread" or "userdata"
	global unpack = extern : function([any]) -> ...

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

		sqrt  = extern : function(number) -> number;
		pow   = extern : function(number, number) -> number;

		sin   = extern : function(number) -> number;
		asin  = extern : function(number) -> number;
		cos   = extern : function(number) -> number;
		acos  = extern : function(number) -> number;
		tan   = extern : function(number) -> number;
		atan  = extern : function(number) -> number;
		atan2 = extern : function(number, number) -> number;
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

		clock = extern : function() -> number;
	}

	global package = {
		path = extern : string;
	}

	global string = {
		byte   = extern : function(string, int, int?, int?) -> ...;
		char   = extern : function(string, ... : int) -> string;
		format = extern : function(string, ...) -> string;
		rep    = extern : function(...) -> ...;

		sub    = extern : function(string, int, int?) -> string?;

		-- Patterns:
		gsub   = extern : function(...) -> ...;
		find   = extern : function(...) -> ...;
		match  = extern : function(...) -> ...;
		gmatch = extern : function(...) -> ...;   -- TODO: a generator
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
	assert(st, tokens) --[[SOL OUTPUT--]] 
	local st, ast = P.parse_sol(INTRINSICS, tokens, filename, settings, scope) --[[SOL OUTPUT--]] 
	assert(st, ast) --[[SOL OUTPUT--]] 
	local st, err = TypeCheck(ast, filename, nil, settings) --[[SOL OUTPUT--]] 
	assert(st, err) --[[SOL OUTPUT--]] 

	if not Scope.GLOBALS_IN_TOP_SCOPE then
		global_scope.fixed = false --[[SOL OUTPUT--]] 

		for _,v in ipairs(module_scope:get_global_vars()) do
			global_scope:add_global(v) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for name,type in pairs(module_scope:get_global_typedefs()) do
			global_scope:add_global_type( name, type ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		global_scope.fixed = true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return M --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 