local T = require 'type'
local D = require 'sol_debug'
local util = require 'util'
require 'class'


--[[
Scopes:

At the top there is the shared and immutable 'global_scope'. This contains the lua-wide globals.
When parsign a module, there is a 'module_scope' whose parent is the 'global_scope'.

User declared globals goes into the 'module_scope' and are marked as 'global'.
--]]


typedef Scope;


typedef Variable = {
	--Scope : Scope,  TODO
	Sope : any,
	Name  : string,
	Type  : T.Type?,
	IsGlobal   : bool,
	References : int,
	Namespace  : { string => T.Type } ?,
}

typedef Scope = {
	Parent   : Scope?,
	Children : [Scope],
	Locals   : [Variable],
	Globals  : [Variable],
	Typedefs : { string => T.Type },
	VarArg   : Variable?,  -- if non-nil, points to a variable named '...' with the type of T.VarArgs

	--GetScopedType : function(self, name: string) -> T.Type?
}


local S = {}

typedef S.Scope    = Scope
typedef S.Variable = Variable

--global Scope = class("Scope")
local Scope = {}

function Scope:new(parent: S.Scope?) -> S.Scope
	var<S.Scope> s = {
		Parent             = parent;
		Children           = { };
		Locals             = { };
		Globals            = { };
		Typedefs           = { };  -- string -> T.Type     - simple typedefs:
		GlobalsTypedefs    = { };
		fixed              = false;
	}
	
	if parent then
		table.insert(parent.Children, s)
	end
	
	return setmetatable(s, { __index = self })
end


-- Created the global top-level scope
function Scope:get_global_scope() -> S.Scope
	Scope.global_scope = Scope.global_scope or Scope:create_global_scope()
	return Scope.global_scope
end


function Scope:create_module_scope() -> S.Scope
	local top_scope = self:get_global_scope()
	return Scope:new( top_scope )
end


function Scope:is_module_level() -> bool
	-- Parent should be global scope, and so should have no parent
	return self.Parent and self.Parent.Parent == nil
end


function Scope:create_global_scope() -> S.Scope
	local s = Scope:new()
	local where = "[intrinsic]"  -- var.where

	-- TODO: types
	--[[
	for k,v in pairs(_G)  do print(k, "\t=\t", v)  end
	--]]
	local intrinsics = {
		-- Tables:
		'_G',
		'coroutine', 'debug', 'io', 'math', 'os', 'package', 'string', 'table',

		-- Functions:
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
		'tonumber', 'tostring', 'type', 'unpack', 'xpcall',

		-- String:
		'_VERSION',

		-- String list:
		'arg',

		-- luajit:
		'jit',
	}
	for _,name in ipairs(intrinsics) do
		s:CreateGlobal( name, where )
	end

	-- Ensure 'require' is recognized by TypeCheck.sol
	local require = s:CreateGlobal( 'require', where )
	require.Type = {
		tag  = "function",
		args = { { type = T.String } },
		rets = T.AnyTypeList,
		name = "require"
	}

	-- Ensure 'pairs' and 'ipairs' are recognized by TypeCheck.sol
	local pairs = s:CreateGlobal( 'pairs', where )
	pairs.Type = {
		tag  = "function",
		args = { { type = T.Any } },
		rets = T.AnyTypeList,
		name = "pairs"
	}

	local ipairs = s:CreateGlobal( 'ipairs', where )
	ipairs.Type = {
		tag  = "function",
		args = { { type = T.List } },
		rets = T.AnyTypeList,
		name = "ipairs"
	}

	local setmetatable = s:CreateGlobal( 'setmetatable', where )
	setmetatable.Type = {
		tag  = "function",
		args = { { type = T.Object }, { type = T.Object } },
		rets = { T.Object },
		name = "setmetatable"
	}


	--s:DeclareType( 'void',    T.Void ) -- Not a valid type, only allowed as a typelist
	s:DeclareType( 'bool',    T.Bool,   where )
	s:DeclareType( 'int',     T.Int,    where )
	s:DeclareType( 'uint',    T.Uint,   where )
	s:DeclareType( 'number',  T.Num,    where )
	s:DeclareType( 'string',  T.String, where )
	s:DeclareType( 'any',     T.Any,    where )

	-- Keywords are handles explicitly:
	--s:DeclareType( 'nil',     T.Nil)    -- for e.g.:   foo or bar or nil
	--s:DeclareType( 'true',    T.True)
	--s:DeclareType( 'false',   T.False)

	-- No more changes - user globals should be declared in 
	s.fixed = true

	return s
end


function Scope:DeclareType(name: string, type: T.Type, where: string)
	D.assert(not self.fixed)
	D.assert(name and where)
	self.Typedefs[name] = type
end


function Scope:CreateLocal(name: string, where: string) -> S.Variable
	D.assert(not self.fixed)
	D.assert(name and where)

	local v = {
		Scope      = self,
		Name       = name,
		IsGlobal   = false,
		References = 1,
		Type       = nil,
		where      = where,
	}

	table.insert(self.Locals, v)

	return v
end


function Scope:add_global(v)
	assert(not self.fixed)
	table.insert(self.Globals, v)
end


function Scope:CreateGlobal(name: string, where: string) -> S.Variable
	assert(not self.fixed)
	assert(name and where)

	local v = {
		Scope      = self,
		Name       = name,
		IsGlobal   = true,
		References = 1,
		Type       = nil,
		where      = where,
	}

	self:add_global(v)

	return v
end


function Scope:GetScopedType(name: string) -> T.Type?
	return self.Typedefs[name]
end


function Scope:GetType(name) -> T.Type?
	local t = self:GetScopedType(name)
	if t then return t end
	if self.Parent then return self.Parent:GetType(name) end
	return nil
end


-- Will only check local scope
function Scope:GetScoped(name: string) -> S.Variable?
	for _,v in ipairs(self.Locals) do
		if v.Name == name then return v end
	end

	return nil
end


-- Will check locals and parents
function Scope:GetLocal(name: string) -> S.Variable?
	local v = self:GetScoped(name)
	if v then return v end
	
	if self.Parent then
		return self.Parent:GetLocal(name)
	end
end


-- Global declared in this scope
function Scope:GetScopedGlobal(name: string) -> S.Variable ?
	assert(name and name ~= '')

	for k, v in ipairs(self.Globals) do
		if v.Name == name then return v end
	end
end


function Scope:GetGlobal(name: string) -> S.Variable ?
	local v = self:GetScopedGlobal(name)
	if v then return v end
	
	if self.Parent then
		return self.Parent:GetGlobal(name)
	end
end


-- Var declared in this scope
function Scope:GetScopedVar(name: string) -> S.Variable ?
	return self:GetScoped(name) or self:GetScopedGlobal(name)
end


function Scope:GetVar(name: string) -> S.Variable ?
	return self:GetLocal(name) or self:GetGlobal(name)
end


function Scope:GetVarArgs() -> T.Type?
	local v = self:GetLocal('...')
	
	if v then
		return v.Type or T.Any
	end

	if self.Parent then
		return self.Parent:GetVarArgs()
	end

	return nil
end


function Scope:get_global_vars(list: [Variable] or nil) -> [Variable]
	list = list or {}
	util.table_join(list, self.Globals)
	for _,c in ipairs(self.Children) do
		c:get_global_vars(list)
	end
	return list
end


function Scope:get_global_typedefs(list: [Variable] or nil) -> [Variable]
	return util.shallow_clone( self.GlobalsTypedefs )
end


S.Scope = Scope
return S
