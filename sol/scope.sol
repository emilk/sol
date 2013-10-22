local T = require 'type'
local D = require 'sol_debug'
local U = require 'util'


--[[
Scopes:

At the top there is the shared and immutable 'global_scope'. This contains the lua-wide globals.
When parsign a module, there is a 'module_scope' whose parent is the 'global_scope'.

User declared globals goes into the 'module_scope' and are marked as 'global'.
--]]

--[-[
global class Scope = {
	-- TODO: static members here, i.e. global_scope
	global_scope = nil : Scope?   -- not found in later lookup :T
}

function Scope.new(where: string, parent: Scope?) -> Scope
	--var s = {} : Scope
	local s = {}
	setmetatable(s, { __index = Scope })
	s:init(where, parent)
	return s
end
--]]
--[[
require 'class'
global class Scope = sol_class("Scope")

function Scope.new(where: string, parent: Scope?) -> Scope
	return Scope(where, parent)
end
--]]

global typedef Variable = {
	scope            : Scope,
	name             : string,
	type             : T.Type?,
	is_global        : bool,
	namespace        : { string => T.Type } ?,
	where            : string,
	forward_declared : bool?,

	-- Usage statistics:
	num_reads        : int,
	num_writes       : int,
	var_type         : 'Function' or 'Loop variable' or 'Argument' or 'Global variable' or 'Local variable' or nil
}


typedef VarOptions = 'ignore_fwd_decl' or nil


Scope.GLOBALS_IN_TOP_SCOPE = true

--------------------------------------------------

-- Constructor
function Scope:init(where: string, parent: Scope?)
	self.where           = where
	self.parent          = parent
	self.children        = {}  : [Scope]
	self.locals          = {}  : { string => Variable }
	self.globals         = {}  : [Variable]  -- TODO: string->var map
	self.typedefs        = {}  : { string => T.Type }
	self.global_typedefs = {}  : { string => T.Type }
	self.vararg          = nil : Variable?
	self.fixed           = false

	if parent then
		parent.children #= self
	end
end


function Scope:is_module_level() -> bool
	-- parent should be global scope, and so should have no parent
	return self.parent and self.parent.parent == nil
end


function Scope:declare_type(name: string, typ: T.Type, where: string, is_local: bool)
	D.assert(not self.fixed)
	D.assert(type(name) == 'string')
	D.assert(type(where) == 'string')
	D.assert(type(is_local) == 'boolean')

	if is_local then
		self.typedefs[name] = typ
	else
		if Scope.GLOBALS_IN_TOP_SCOPE then
			Scope.global_scope.global_typedefs[name] = typ
		else
			self.global_typedefs[name] = typ
		end
	end
end


function Scope:add_global_type(name: string, typ: T.Type)
	self.global_typedefs[name] = typ
end


function Scope:create_local(name: string, where: string) -> Variable
	D.assert(not self.fixed)

	local v = {
		scope      = self,
		name       = name,
		is_global  = false,
		where      = where,
		num_reads  = 0,
		num_writes = 0,
	}

	D.assert(not self.locals[name])
	self.locals[name] = v

	return v
end


function Scope:add_global(v: Variable)
	assert(not self.fixed)
	self.globals #= v
end


function Scope:create_global(name: string, where: string, typ: T.Type?) -> Variable
	assert(not self.fixed)

	local v = {
		scope      = self,
		name       = name,
		is_global  = true,
		where      = where,
		type       = typ,
		num_reads  = 0,
		num_writes = 0,
	}

	if Scope.GLOBALS_IN_TOP_SCOPE and self ~= Scope.global_scope then
		Scope.global_scope:add_global(v)
	else
		self:add_global(v)
	end

	return v
end


function Scope:get_scoped_type(name: string) -> T.Type?
	return self.typedefs[name]
end


function Scope:get_local_type(name: string) -> T.Type?
	local t = self:get_scoped_type(name)
	if t then return t end
	if self.parent then return self.parent:get_type(name) end
	return nil
end


function Scope:get_type(name: string) -> T.Type?
	return self:get_local_type(name) or self:get_global_type(name)
end


function Scope:get_global_type(name: string) -> T.Type ?
	local t = self.global_typedefs[name]
	if t then return t end

	if self.parent then
		return self.parent:get_global_type(name)
	end
end


function Scope:locals_iterator() -> (function(...) -> string,Variable)
	return pairs(self.locals)
end


-- Will only check local scope
function Scope:get_scoped(name: string, options: VarOptions?) -> Variable?
	var v = self.locals[name]
	if v then
		if not v.forward_declared or options ~= 'ignore_fwd_decl' then
			return v
		end
	end
	return nil
end


-- Will check locals and parents
function Scope:get_local(name: string, options: VarOptions?) -> Variable?
	local v = self:get_scoped(name, options)
	if v then return v end

	if self.parent then
		return self.parent:get_local(name, options)
	end
end


-- Global declared in this scope
function Scope:get_scoped_global(name: string, options: VarOptions?) -> Variable ?
	for _, v in ipairs(self.globals) do
		if v.name == name then
			if not v.forward_declared or options ~= 'ignore_fwd_decl' then
				return v
			end
		end
	end
	return nil
end


function Scope:get_global(name: string, options: VarOptions?) -> Variable ?
	local v = self:get_scoped_global(name, options)
	if v then return v end

	if self.parent then
		return self.parent:get_global(name, options)
	end
end



-- Var declared in this scope
function Scope:get_scoped_var(name: string, options: VarOptions?) -> Variable ?
	return self:get_scoped(name, options) or self:get_scoped_global(name, options)
end


function Scope:get_var(name: string, options: VarOptions?) -> Variable ?
	return self:get_local(name, options) or self:get_global(name, options)
end


function Scope:get_global_vars(list: [Variable] or nil) -> [Variable]
	list = list or {}
	U.list_join(list, self.globals)
	for _,c in ipairs(self.children) do
		c:get_global_vars(list)
	end
	return list
end


function Scope:get_global_typedefs() -> { string => T.Type }
	return U.shallow_clone( self.global_typedefs )
end


--------------------------------------------------
-- Static members:

-- Created the global top-level scope
function Scope.get_global_scope() -> Scope
	Scope.global_scope = Scope.global_scope or Scope.create_global_scope()
	return Scope.global_scope
end


function Scope.create_module_scope() -> Scope
	local top_scope = Scope.get_global_scope()
	return Scope.new( "[MODULE_SCOPE]", top_scope )
end


function Scope.create_global_scope() -> Scope
	var s = Scope.new("[GLOBAL_SCOPE]")
	Scope.global_scope = s
	var where = "[intrinsic]"  -- var.where


	--[[
	-- Print out all globals
	for k,v in pairs(_G)  do print(k, "\t=\t", v)  end
	--]]

	-- Ommisions explicitly added in lua_intrinsics.sol

	var tables = {
		'_G',
		'jit'  -- luaJIT
	}

	var functions = {
		'assert',
		'collectgarbage',
		'dofile',
		'error',
		'gcinfo', 'getfenv', 'getmetatable',
		'load', 'loadfile', 'loadstring',
		'module',
		'newproxy', 'next',
		'pcall', 'print',
		'rawequal', 'rawget', 'rawset',
		'select', 'setfenv',
		'tonumber', 'tostring', 'xpcall',
	}

	for _,name in ipairs(tables) do
		s:create_global( name, where, T.Object )
	end

	for _,name in ipairs(functions) do
		var fun_t = {
			tag            = 'function',
			args           = { },
			vararg         = { tag = 'varargs', type = T.Any },
			rets           = T.AnyTypeList,
			name           = name,
			intrinsic_name = name,
		}
		s:create_global( name, where, fun_t)
	end

	s:create_global( '_VERSION', where, T.String )
	s:create_global( 'arg', where, { tag = 'list', type = T.String} )


	-- Ensure 'require' is recognized by TypeCheck.sol
	local require = s:create_global( 'require', where )
	require.type = {
		tag            = 'function',
		args           = { { type = T.String } },
		rets           = T.AnyTypeList,
		name           = "require",
		intrinsic_name = "require",
	}

	-- Ensure 'pairs' and 'ipairs' are recognized by TypeCheck.sol
	local pairs = s:create_global( 'pairs', where )
	pairs.type = {
		tag            = 'function',
		args           = { { type = T.Any } },
		rets           = T.AnyTypeList,
		intrinsic_name = "pairs",
		name           = "pairs",
	}

	local ipairs_ = s:create_global( 'ipairs', where )
	ipairs_.type = {
		tag            = 'function',
		args           = { { type = T.List } },
		rets           = T.AnyTypeList,
		intrinsic_name = "ipairs",
		name           = "ipairs",
	}

	local setmetatable = s:create_global( 'setmetatable', where )
	setmetatable.type = {
		tag            = 'function',
		args           = { {  type = T.Table }, { type = T.variant(T.Table, T.Nil) } },
		rets           = { T.Table },
		intrinsic_name = "setmetatable",
		name           = "setmetatable",
	}

	local type = s:create_global( 'type', where )
	type.type = {
		tag            = 'function',
		args           = { {        type = T.Any } },
		rets           = { T.String },
		intrinsic_name = "type",
		name           = "type",
	}


	var is_local = true
	--s:declare_type( 'void',    T.Void ) -- Not a valid type, only allowed as a typelist
	s:declare_type( 'bool',   T.Bool,   where, is_local )
	s:declare_type( 'int',    T.Int,    where, is_local )
	s:declare_type( 'uint',   T.Uint,   where, is_local )
	s:declare_type( 'number', T.Num,    where, is_local )
	s:declare_type( 'string', T.String, where, is_local )
	s:declare_type( 'any',    T.Any,    where, is_local )
	s:declare_type( 'table',  T.Table,  where, is_local )
	--s:declare_type( 'list',   T.List,   where, is_local ) -- use: [any]
	--s:declare_type( 'map',    T.Map,    where, is_local ) -- use: {any => any}
	s:declare_type( 'object', T.Object, where, is_local )

	-- keywords are handles explicitly during parsing
	--s:declare_type( 'nil',     T.Nil)    -- for e.g.:   foo or bar or nil
	--s:declare_type( 'true',    T.True)
	--s:declare_type( 'false',   T.False)

	if not Scope.GLOBALS_IN_TOP_SCOPE then
		-- No more changes - user globals should be declared in module scope (a direct child)
		s.fixed = true
	end

	return s
end

----------------------------------------

return {}
