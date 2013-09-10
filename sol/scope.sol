local T = require 'type'
local D = require 'sol_debug'
local U = require 'util'


--[[
Scopes:

At the top there is the shared and immutable 'global_scope'. This contains the lua-wide globals.
When parsign a module, there is a 'module_scope' whose parent is the 'global_scope'.

User declared globals goes into the 'module_scope' and are marked as 'global'.
--]]


typedef Variable = {
	--scope : Scope,  TODO
	scope      : any,
	name       : string,
	type       : T.Type?,
	is_global  : bool,
	references : int,
	namespace  : { string => T.Type } ?,
	where      : string,
}


--[[
typedef Scope = {
	parent   : Scope?,
	children : [Scope],
	locals   : [Variable],
	globals  : [Variable],
	typedefs : { string => T.Type },
	vararg   : Variable?,  -- if non-nil, points to a variable named '...' with the type of T.VarArgs

	--get_scoped_type : function(self, name: string) -> T.Type?
}
local Scope = {}
--]]
class Scope = {}

--[-[

function Scope.new(parent: Scope?) -> Scope
	local s = {}	
	setmetatable(s, { __index = Scope })
	s:init(parent)
	return s
end
--]]
--[[
require 'class'
local Scope = sol_class("Scope")
--class Scope

function Scope.new(parent: Scope?) -> Scope
	return Scope(parent)
end
--]]

--------------------------------------------------
-- Static members:

-- Created the global top-level scope
function Scope.get_global_scope() -> Scope
	Scope.global_scope = Scope.global_scope or Scope.create_global_scope()
	return Scope.global_scope
end


function Scope.create_module_scope() -> Scope
	local top_scope = Scope.get_global_scope()
	return Scope.new( top_scope )
end


function Scope.create_global_scope() -> Scope
	local s = Scope.new()
	local where = "[intrinsic]"  -- var.where


	--[[
	-- Print out all globals
	for k,v in pairs(_G)  do print(k, "\t=\t", v)  end
	--]]

	var tables = {
		'_G',
		'coroutine', 'debug', 'io', 'math', 'os', 'package', 'string', 'table',
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
		'tonumber', 'tostring', 'unpack', 'xpcall',
	}

	for _,name in ipairs(tables) do
		s:create_global( name, where, T.Object )
	end

	for _,name in ipairs(functions) do
		var<T.Function> fun_t = {
			tag            = "function",
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
		tag            = "function",
		args           = { { type = T.String } },
		rets           = T.AnyTypeList,
		name           = "require",
		intrinsic_name = "require",
	}

	-- Ensure 'pairs' and 'ipairs' are recognized by TypeCheck.sol
	local pairs = s:create_global( 'pairs', where )
	pairs.type = {
		tag            = "function",
		args           = { { type = T.Any } },
		rets           = T.AnyTypeList,
		intrinsic_name = "pairs",
		name           = "pairs",
	}

	local ipairs_ = s:create_global( 'ipairs', where )
	ipairs_.type = {
		tag            = "function",
		args           = { { type = T.List } },
		rets           = T.AnyTypeList,
		intrinsic_name = "ipairs",
		name           = "ipairs",
	}

	local setmetatable = s:create_global( 'setmetatable', where )
	setmetatable.type = {
		tag            = "function",
		args           = { {  type = T.Table }, { type = T.Table } },
		rets           = { T.Table },
		intrinsic_name = "setmetatable",
		name           = "setmetatable",
	}

	local type = s:create_global( 'type', where )
	type.type = {
		tag            = "function",
		args           = { {        type = T.Any } },
		rets           = { T.String },
		intrinsic_name = "type",
		name           = "type",
	}


	--s:declare_type( 'void',    T.Void ) -- Not a valid type, only allowed as a typelist
	s:declare_type( 'bool',   T.Bool,   where )
	s:declare_type( 'int',    T.Int,    where )
	s:declare_type( 'uint',   T.Uint,   where )
	s:declare_type( 'number', T.Num,    where )
	s:declare_type( 'string', T.String, where )
	s:declare_type( 'any',    T.Any,    where )
	s:declare_type( 'table',  T.Table,  where )
	--s:declare_type( 'list',   T.List,   where ) -- use: [any]
	--s:declare_type( 'map',    T.Map,    where ) -- use: {any => any}
	s:declare_type( 'object', T.Object, where )

	-- keywords are handles explicitly during parsing
	--s:declare_type( 'nil',     T.Nil)    -- for e.g.:   foo or bar or nil
	--s:declare_type( 'true',    T.True)
	--s:declare_type( 'false',   T.False)

	-- No more changes - user globals should be declared in module scope (a direct child)
	s.fixed = true

	return s
end

--------------------------------------------------

-- Constructor
function Scope:init(parent: Scope?)
	self.parent          = parent
	self.children        = { }
	self.locals          = { }
	self.globals         = { }
	self.typedefs        = { } -- string -> T.Type     - simple typedefs:
	self.global_typedefs = { }
	self.fixed           = false
	
	if parent then
		table.insert(parent.children, self)
	end
end


function Scope:is_module_level() -> bool
	-- parent should be global scope, and so should have no parent
	return self.parent and self.parent.parent == nil
end


function Scope:declare_type(name: string, type: T.Type, where: string)
	D.assert(not self.fixed)
	D.assert(name) D.assert(where)
	self.typedefs[name] = type
end


function Scope:create_local(name: string, where: string) -> Variable
	D.assert(not self.fixed)

	local v = {
		scope      = self,
		name       = name,
		is_global  = false,
		references = 1,
		type       = nil,
		where      = where,
	}

	table.insert(self.locals, v)

	return v
end


function Scope:add_global(v)
	assert(not self.fixed)
	table.insert(self.globals, v)
end


function Scope:create_global(name: string, where: string, type: T.Type) -> Variable
	assert(not self.fixed)

	local v = {
		scope      = self,
		name       = name,
		is_global  = true,
		references = 1,
		type       = nil,
		where      = where,
		type       = type,
	}

	self:add_global(v)

	return v
end


function Scope:get_scoped_type(name: string) -> T.Type?
	return self.typedefs[name]
end


function Scope:get_type(name) -> T.Type?
	local t = self:get_scoped_type(name)
	if t then return t end
	if self.parent then return self.parent:get_type(name) end
	return nil
end


-- Will only check local scope
function Scope:get_scoped(name: string) -> Variable?
	for _,v in ipairs(self.locals) do
		if v.name == name then return v end
	end

	return nil
end


-- Will check locals and parents
function Scope:get_local(name: string) -> Variable?
	local v = self:get_scoped(name)
	if v then return v end
	
	if self.parent then
		return self.parent:get_local(name)
	end
end


-- Global declared in this scope
function Scope:get_scoped_global(name: string) -> Variable ?
	for k, v in ipairs(self.globals) do
		if v.name == name then return v end
	end
end


function Scope:get_global(name: string) -> Variable ?
	local v = self:get_scoped_global(name)
	if v then return v end
	
	if self.parent then
		return self.parent:get_global(name)
	end
end


-- Var declared in this scope
function Scope:get_scoped_var(name: string) -> Variable ?
	return self:get_scoped(name) or self:get_scoped_global(name)
end


function Scope:get_var(name: string) -> Variable ?
	return self:get_local(name) or self:get_global(name)
end


function Scope:get_var_args() -> T.Type?
	local v = self:get_local('...')
	
	if v then
		return v.type or T.Any
	end

	if self.parent then
		return self.parent:get_var_args()
	end

	return nil
end


function Scope:get_global_vars(list: [Variable] or nil) -> [Variable]
	list = list or {}
	U.list_join(list, self.globals)
	for _,c in ipairs(self.children) do
		c:get_global_vars(list)
	end
	return list
end


function Scope:get_global_typedefs(list: [Variable] or nil) -> [Variable]
	return U.shallow_clone( self.global_typedefs )
end


local S = {}
S.Scope = Scope
typedef S.Scope    = Scope
typedef S.Variable = Variable
return S
