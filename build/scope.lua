--[[ DO NOT MODIFY - COMPILED FROM sol/scope.sol --]] local T = require 'type' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 
local U = require 'util' --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 






































local S = {} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 

--[-[



local Scope = {} --[[SOL OUTPUT--]] 

function Scope.new(parent)
	local s = {} --[[SOL OUTPUT--]] 	
	setmetatable(s, { __index = Scope }) --[[SOL OUTPUT--]] 
	s:init(parent) --[[SOL OUTPUT--]] 
	return s --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 
--]]
--[[
require 'class'
local Scope = sol_class("Scope")
--class Scope

function Scope.new(parent: S.Scope?) -> S.Scope
	return Scope(parent)
end
--]]

-- Constructor
function Scope:init(parent)
	self.parent          = parent --[[SOL OUTPUT--]] 
	self.children        = { } --[[SOL OUTPUT--]] 
	self.locals          = { } --[[SOL OUTPUT--]] 
	self.globals         = { } --[[SOL OUTPUT--]] 
	self.typedefs        = { } --[[SOL OUTPUT--]]  -- string -> T.Type     - simple typedefs:
	self.global_typedefs = { } --[[SOL OUTPUT--]] 
	self.fixed           = false --[[SOL OUTPUT--]] 
	
	if parent then
		table.insert(parent.children, self) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

-- Created the global top-level scope
function Scope:get_global_scope()
	Scope.global_scope = Scope.global_scope or Scope:create_global_scope() --[[SOL OUTPUT--]] 
	return Scope.global_scope --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:create_module_scope()
	local top_scope = self:get_global_scope() --[[SOL OUTPUT--]] 
	return Scope.new( top_scope ) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:is_module_level()
	-- parent should be global scope, and so should have no parent
	return self.parent and self.parent.parent == nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:create_global_scope()
	local s = Scope.new() --[[SOL OUTPUT--]] 
	local where = "[intrinsic]" --[[SOL OUTPUT--]]   -- var.where


	--[[
	-- Print out all globals
	for k,v in pairs(_G)  do print(k, "\t=\t", v)  end
	--]]

	local tables = {
		'_G',
		'coroutine', 'debug', 'io', 'math', 'os', 'package', 'string', 'table',
		'jit'  -- luaJIT
	} --[[SOL OUTPUT--]] 

	local functions = {
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
	} --[[SOL OUTPUT--]] 

	for _,name in ipairs(tables) do
		s:create_global( name, where, T.Object ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for _,name in ipairs(functions) do
		local fun_t = {
			tag            = "function",
			args           = { },
			vararg         = { tag = 'varargs', type = T.Any },
			rets           = T.AnyTypeList,
			name           = name,
			intrinsic_name = name,
		} --[[SOL OUTPUT--]] 
		s:create_global( name, where, fun_t) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	s:create_global( '_VERSION', where, T.String ) --[[SOL OUTPUT--]] 
	s:create_global( 'arg', where, { tag = 'list', type = T.String} ) --[[SOL OUTPUT--]] 


	-- Ensure 'require' is recognized by TypeCheck.sol
	local require = s:create_global( 'require', where ) --[[SOL OUTPUT--]] 
	require.type = {
		tag            = "function",
		args           = { { type = T.String } },
		rets           = T.AnyTypeList,
		name           = "require",
		intrinsic_name = "require",
	} --[[SOL OUTPUT--]] 

	-- Ensure 'pairs' and 'ipairs' are recognized by TypeCheck.sol
	local pairs = s:create_global( 'pairs', where ) --[[SOL OUTPUT--]] 
	pairs.type = {
		tag            = "function",
		args           = { { type = T.Any } },
		rets           = T.AnyTypeList,
		intrinsic_name = "pairs",
		name           = "pairs",
	} --[[SOL OUTPUT--]] 

	local ipairs_ = s:create_global( 'ipairs', where ) --[[SOL OUTPUT--]] 
	ipairs_.type = {
		tag            = "function",
		args           = { { type = T.List } },
		rets           = T.AnyTypeList,
		intrinsic_name = "ipairs",
		name           = "ipairs",
	} --[[SOL OUTPUT--]] 

	local setmetatable = s:create_global( 'setmetatable', where ) --[[SOL OUTPUT--]] 
	setmetatable.type = {
		tag            = "function",
		args           = { {  type = T.Table }, { type = T.Table } },
		rets           = { T.Table },
		intrinsic_name = "setmetatable",
		name           = "setmetatable",
	} --[[SOL OUTPUT--]] 

	local type = s:create_global( 'type', where ) --[[SOL OUTPUT--]] 
	type.type = {
		tag            = "function",
		args           = { {        type = T.Any } },
		rets           = { T.String },
		intrinsic_name = "type",
		name           = "type",
	} --[[SOL OUTPUT--]] 


	--s:declare_type( 'void',    T.Void ) -- Not a valid type, only allowed as a typelist
	s:declare_type( 'bool',   T.Bool,   where ) --[[SOL OUTPUT--]] 
	s:declare_type( 'int',    T.Int,    where ) --[[SOL OUTPUT--]] 
	s:declare_type( 'uint',   T.Uint,   where ) --[[SOL OUTPUT--]] 
	s:declare_type( 'number', T.Num,    where ) --[[SOL OUTPUT--]] 
	s:declare_type( 'string', T.String, where ) --[[SOL OUTPUT--]] 
	s:declare_type( 'any',    T.Any,    where ) --[[SOL OUTPUT--]] 
	s:declare_type( 'table',  T.Table,  where ) --[[SOL OUTPUT--]] 
	--s:declare_type( 'list',   T.List,   where ) -- use: [any]
	--s:declare_type( 'map',    T.Map,    where ) -- use: {any => any}
	--s:declare_type( 'object', T.Object, where ) -- use: {}

	-- keywords are handles explicitly during parsing
	--s:declare_type( 'nil',     T.Nil)    -- for e.g.:   foo or bar or nil
	--s:declare_type( 'true',    T.True)
	--s:declare_type( 'false',   T.False)

	-- No more changes - user globals should be declared in module scope (a direct child)
	s.fixed = true --[[SOL OUTPUT--]] 

	return s --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:declare_type(name, type, where)
	D.assert(not self.fixed) --[[SOL OUTPUT--]] 
	D.assert(name) --[[SOL OUTPUT--]]  D.assert(where) --[[SOL OUTPUT--]] 
	self.typedefs[name] = type --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:create_local(name, where)
	D.assert(not self.fixed) --[[SOL OUTPUT--]] 

	local v = {
		scope      = self,
		name       = name,
		is_global  = false,
		references = 1,
		type       = nil,
		where      = where,
	} --[[SOL OUTPUT--]] 

	table.insert(self.locals, v) --[[SOL OUTPUT--]] 

	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:add_global(v)
	assert(not self.fixed) --[[SOL OUTPUT--]] 
	table.insert(self.globals, v) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:create_global(name, where, type)
	assert(not self.fixed) --[[SOL OUTPUT--]] 

	local v = {
		scope      = self,
		name       = name,
		is_global  = true,
		references = 1,
		type       = nil,
		where      = where,
		type       = type,
	} --[[SOL OUTPUT--]] 

	self:add_global(v) --[[SOL OUTPUT--]] 

	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_scoped_type(name)
	return self.typedefs[name] --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_type(name)
	local t = self:get_scoped_type(name) --[[SOL OUTPUT--]] 
	if t then return t --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if self.parent then return self.parent:get_type(name) --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Will only check local scope
function Scope:get_scoped(name)
	for _,v in ipairs(self.locals) do
		if v.name == name then return v --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Will check locals and parents
function Scope:get_local(name)
	local v = self:get_scoped(name) --[[SOL OUTPUT--]] 
	if v then return v --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	
	if self.parent then
		return self.parent:get_local(name) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Global declared in this scope
function Scope:get_scoped_global(name)
	for k, v in ipairs(self.globals) do
		if v.name == name then return v --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global(name)
	local v = self:get_scoped_global(name) --[[SOL OUTPUT--]] 
	if v then return v --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	
	if self.parent then
		return self.parent:get_global(name) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Var declared in this scope
function Scope:get_scoped_var(name)
	return self:get_scoped(name) or self:get_scoped_global(name) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_var(name)
	return self:get_local(name) or self:get_global(name) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_var_args()
	local v = self:get_local('...') --[[SOL OUTPUT--]] 
	
	if v then
		return v.type or T.Any --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if self.parent then
		return self.parent:get_var_args() --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global_vars(list)
	list = list or {} --[[SOL OUTPUT--]] 
	U.table_join(list, self.globals) --[[SOL OUTPUT--]] 
	for _,c in ipairs(self.children) do
		c:get_global_vars(list) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return list --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global_typedefs(list)
	return U.shallow_clone( self.global_typedefs ) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


S.Scope = Scope --[[SOL OUTPUT--]] 
return S --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 