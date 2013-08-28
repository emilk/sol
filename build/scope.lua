--[[ DO NOT MODIFY - COMPILED FROM sol/scope.sol --]] local T = require 'type'
local D = require 'sol_debug'
local U = require 'util'
require 'class'






































local S = {}


--[-[



local Scope = {}

function Scope:new(parent)
	local s = {
		parent             = parent;
		children           = { };
		locals             = { };
		globals            = { };
		typedefs           = { };  -- string -> T.Type     - simple typedefs:
		global_typedefs    = { };
		fixed              = false;
	}
	
	if parent then
		table.insert(parent.children, s)
	end
	
	return setmetatable(s, { __index = self })
end
--]]
--[[
global Scope = class("Scope")

function Scope:init(parent: S.Scope?)
	self.parent             = parent
	self.children           = { }
	self.locals             = { }
	self.globals            = { }
	self.typedefs           = { }  -- string -> T.Type     - simple typedefs:
	self.global_typedefs    = { }
	self.fixed              = false
end

function Scope:new(parent: S.Scope?) -> S.Scope
	return Scope(parent)
end
--]]


-- Created the global top-level scope
function Scope:get_global_scope()
	Scope.global_scope = Scope.global_scope or Scope:create_global_scope()
	return Scope.global_scope
end


function Scope:create_module_scope()
	local top_scope = self:get_global_scope()
	return Scope:new( top_scope )
end


function Scope:is_module_level()
	-- parent should be global scope, and so should have no parent
	return self.parent and self.parent.parent == nil
end


function Scope:create_global_scope()
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
		s:create_global( name, where )
	end

	-- Ensure 'require' is recognized by TypeCheck.sol
	local require = s:create_global( 'require', where )
	require.type = {
		tag  = "function",
		args = { { type = T.String } },
		rets = T.AnyTypeList,
		name = "require"
	}

	-- Ensure 'pairs' and 'ipairs' are recognized by TypeCheck.sol
	local pairs = s:create_global( 'pairs', where )
	pairs.type = {
		tag  = "function",
		args = { { type = T.Any } },
		rets = T.AnyTypeList,
		name = "pairs"
	}

	local ipairs_ = s:create_global( 'ipairs', where )
	ipairs_.type = {
		tag  = "function",
		args = { { type = T.List } },
		rets = T.AnyTypeList,
		name = "ipairs"
	}

	local setmetatable = s:create_global( 'setmetatable', where )
	setmetatable.type = {
		tag  = "function",
		args = { { type = T.Object }, { type = T.Object } },
		rets = { T.Object },
		name = "setmetatable"
	}


	--s:declare_type( 'void',    T.Void ) -- Not a valid type, only allowed as a typelist
	s:declare_type( 'bool',    T.Bool,   where )
	s:declare_type( 'int',     T.Int,    where )
	s:declare_type( 'uint',    T.Uint,   where )
	s:declare_type( 'number',  T.Num,    where )
	s:declare_type( 'string',  T.String, where )
	s:declare_type( 'any',     T.Any,    where )

	-- keywords are handles explicitly:
	--s:declare_type( 'nil',     T.Nil)    -- for e.g.:   foo or bar or nil
	--s:declare_type( 'true',    T.True)
	--s:declare_type( 'false',   T.False)

	-- No more changes - user globals should be declared in 
	s.fixed = true

	return s
end


function Scope:declare_type(name, type, where)
	D.assert(not self.fixed)
	D.assert(name) D.assert(where)
	self.typedefs[name] = type
end


function Scope:create_local(name, where)
	D.assert(not self.fixed)
	D.assert(name and where)

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


function Scope:create_global(name, where)
	assert(not self.fixed)
	assert(name and where)

	local v = {
		scope      = self,
		name       = name,
		is_global  = true,
		references = 1,
		type       = nil,
		where      = where,
	}

	self:add_global(v)

	return v
end


function Scope:get_scoped_type(name)
	return self.typedefs[name]
end


function Scope:get_type(name)
	local t = self:get_scoped_type(name)
	if t then return t end
	if self.parent then return self.parent:get_type(name) end
	return nil
end


-- Will only check local scope
function Scope:get_scoped(name)
	for _,v in ipairs(self.locals) do
		if v.name == name then return v end
	end

	return nil
end


-- Will check locals and parents
function Scope:get_local(name)
	local v = self:get_scoped(name)
	if v then return v end
	
	if self.parent then
		return self.parent:get_local(name)
	end
end


-- Global declared in this scope
function Scope:get_scoped_global(name)
	assert(name and name ~= '')

	for k, v in ipairs(self.globals) do
		if v.name == name then return v end
	end
end


function Scope:get_global(name)
	local v = self:get_scoped_global(name)
	if v then return v end
	
	if self.parent then
		return self.parent:get_global(name)
	end
end


-- Var declared in this scope
function Scope:get_scoped_var(name)
	return self:get_scoped(name) or self:get_scoped_global(name)
end


function Scope:get_var(name)
	return self:get_local(name) or self:get_global(name)
end


function Scope:get_var_args()
	local v = self:get_local('...')
	
	if v then
		return v.type or T.Any
	end

	if self.parent then
		return self.parent:get_var_args()
	end

	return nil
end


function Scope:get_global_vars(list)
	list = list or {}
	U.table_join(list, self.globals)
	for _,c in ipairs(self.children) do
		c:get_global_vars(list)
	end
	return list
end


function Scope:get_global_typedefs(list)
	return U.shallow_clone( self.global_typedefs )
end


S.Scope = Scope
return S
