--[[ DO NOT MODIFY - COMPILED FROM sol/scope.sol on 2013 Oct 09  22:26:40 --]] local T = require 'type' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 
local U = require 'util' --[[SOL OUTPUT--]] 


--[[
Scopes:

At the top there is the shared and immutable 'global_scope'. This contains the lua-wide globals.
When parsign a module, there is a 'module_scope' whose parent is the 'global_scope'.

User declared globals goes into the 'module_scope' and are marked as 'global'.
--]]

  Scope = {
	-- TODO: static members here, i.e. global_scope
} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 


Scope

















.GLOBALS_IN_TOP_SCOPE = true --[[SOL OUTPUT--]] 

function Scope.new(where, parent)
	--var s = {} : Scope
	local s = {} --[[SOL OUTPUT--]] 
	setmetatable(s, { __index = Scope }) --[[SOL OUTPUT--]] 
	s:init(where, parent) --[[SOL OUTPUT--]] 
	return s --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 
--[[
require 'class'
local Scope = sol_class("Scope")
--class Scope

function Scope.new(where: string, parent: Scope?) -> Scope
	return Scope(where, parent)
end
--]]

--------------------------------------------------

-- Constructor
function Scope:init(where, parent)
	self.where           = where --[[SOL OUTPUT--]] 
	self.parent          = parent --[[SOL OUTPUT--]]  
	self.children        = {} --[[SOL OUTPUT--]] 
	self.locals          = {} --[[SOL OUTPUT--]] 
	self.globals         = {} --[[SOL OUTPUT--]] 
	self.typedefs        = {} --[[SOL OUTPUT--]] 
	self.global_typedefs = {} --[[SOL OUTPUT--]] 
	self.vararg          = nil --[[SOL OUTPUT--]] 
	self.fixed           = false --[[SOL OUTPUT--]]   
	
	if parent then
		table.insert(parent.children, self) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:is_module_level()
	-- parent should be global scope, and so should have no parent
	return self.parent and self.parent.parent == nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:declare_type(name, typ, where, is_local)
	D.assert(not self.fixed) --[[SOL OUTPUT--]] 
	D.assert(type(name) == 'string') --[[SOL OUTPUT--]] 
	D.assert(type(where) == 'string') --[[SOL OUTPUT--]] 
	D.assert(type(is_local) == 'boolean') --[[SOL OUTPUT--]] 

	if is_local then
		self.typedefs[name] = typ --[[SOL OUTPUT--]] 
	else
		if Scope.GLOBALS_IN_TOP_SCOPE then
			Scope.global_scope.global_typedefs[name] = typ --[[SOL OUTPUT--]] 
		else
			self.global_typedefs[name] = typ --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:add_global_type(name, typ)
	self.global_typedefs[name] = typ --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:create_local(name, where)
	D.assert(not self.fixed) --[[SOL OUTPUT--]] 

	local v = {
		scope      = self,
		name       = name,
		is_global  = false,
		where      = where,
		num_reads  = 0,
		num_writes = 0,
	} --[[SOL OUTPUT--]] 

	table.insert(self.locals, v) --[[SOL OUTPUT--]] 

	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:add_global(v)
	assert(not self.fixed) --[[SOL OUTPUT--]] 
	table.insert(self.globals, v) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:create_global(name, where, typ)
	assert(not self.fixed) --[[SOL OUTPUT--]] 

	local v = {
		scope      = self,
		name       = name,
		is_global  = true,
		where      = where,
		type       = typ,
		num_reads  = 0,
		num_writes = 0,
	} --[[SOL OUTPUT--]] 

	if Scope.GLOBALS_IN_TOP_SCOPE and self ~= Scope.global_scope then
		Scope.global_scope:add_global(v) --[[SOL OUTPUT--]] 
	else
		self:add_global(v) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_scoped_type(name)
	return self.typedefs[name] --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_local_type(name)
	local t = self:get_scoped_type(name) --[[SOL OUTPUT--]] 
	if t then return t --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if self.parent then return self.parent:get_type(name) --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_type(name)
	return self:get_local_type(name) or self:get_global_type(name) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global_type(name)
	local t = self.global_typedefs[name] --[[SOL OUTPUT--]] 
	if t then return t --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	
	if self.parent then
		return self.parent:get_global_type(name) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:locals_iterator()
	return ipairs(self.locals) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Will only check local scope
function Scope:get_scoped(name, options)
	for _,v in ipairs(self.locals) do
		if v.name == name then
			if not v.forward_declared or options ~= 'ignore_fwd_decl' then
				return v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Will check locals and parents
function Scope:get_local(name, options)
	local v = self:get_scoped(name, options) --[[SOL OUTPUT--]] 
	if v then return v --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	
	if self.parent then
		return self.parent:get_local(name, options) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Global declared in this scope
function Scope:get_scoped_global(name, options)
	for _, v in ipairs(self.globals) do
		if v.name == name then
			if not v.forward_declared or options ~= 'ignore_fwd_decl' then
				return v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global(name, options)
	local v = self:get_scoped_global(name, options) --[[SOL OUTPUT--]] 
	if v then return v --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	
	if self.parent then
		return self.parent:get_global(name, options) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 



-- Var declared in this scope
function Scope:get_scoped_var(name, options)
	return self:get_scoped(name, options) or self:get_scoped_global(name, options) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_var(name, options)
	return self:get_local(name, options) or self:get_global(name, options) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global_vars(list)
	list = list or {} --[[SOL OUTPUT--]] 
	U.list_join(list, self.globals) --[[SOL OUTPUT--]] 
	for _,c in ipairs(self.children) do
		c:get_global_vars(list) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return list --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope:get_global_typedefs()
	return U.shallow_clone( self.global_typedefs ) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


--------------------------------------------------
-- Static members:

-- Created the global top-level scope
function Scope.get_global_scope()
	Scope.global_scope = Scope.global_scope or Scope.create_global_scope() --[[SOL OUTPUT--]] 
	return Scope.global_scope --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope.create_module_scope()
	local top_scope = Scope.get_global_scope() --[[SOL OUTPUT--]] 
	return Scope.new( "[MODULE_SCOPE]", top_scope ) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function Scope.create_global_scope()
	local s = Scope.new("[GLOBAL_SCOPE]") --[[SOL OUTPUT--]] 
	Scope.global_scope = s --[[SOL OUTPUT--]] 
	local where = "[intrinsic]" --[[SOL OUTPUT--]]   -- var.where


	--[[
	-- Print out all globals
	for k,v in pairs(_G)  do print(k, "\t=\t", v)  end
	--]]

	-- Ommisions explicitly added in lua_intrinsics.sol

	local tables = {
		'_G',
		'package',
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
		'tonumber', 'tostring', 'xpcall',
	} --[[SOL OUTPUT--]] 

	for _,name in ipairs(tables) do
		s:create_global( name, where, T.Object ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for _,name in ipairs(functions) do
		local fun_t = {
			tag            = 'function',
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
		tag            = 'function',
		args           = { { type = T.String } },
		rets           = T.AnyTypeList,
		name           = "require",
		intrinsic_name = "require",
	} --[[SOL OUTPUT--]] 

	-- Ensure 'pairs' and 'ipairs' are recognized by TypeCheck.sol
	local pairs = s:create_global( 'pairs', where ) --[[SOL OUTPUT--]] 
	pairs.type = {
		tag            = 'function',
		args           = { { type = T.Any } },
		rets           = T.AnyTypeList,
		intrinsic_name = "pairs",
		name           = "pairs",
	} --[[SOL OUTPUT--]] 

	local ipairs_ = s:create_global( 'ipairs', where ) --[[SOL OUTPUT--]] 
	ipairs_.type = {
		tag            = 'function',
		args           = { { type = T.List } },
		rets           = T.AnyTypeList,
		intrinsic_name = "ipairs",
		name           = "ipairs",
	} --[[SOL OUTPUT--]] 

	local setmetatable = s:create_global( 'setmetatable', where ) --[[SOL OUTPUT--]] 
	setmetatable.type = {
		tag            = 'function',
		args           = { {  type = T.Table }, { type = T.variant(T.Table, T.Nil) } },
		rets           = { T.Table },
		intrinsic_name = "setmetatable",
		name           = "setmetatable",
	} --[[SOL OUTPUT--]] 

	local type = s:create_global( 'type', where ) --[[SOL OUTPUT--]] 
	type.type = {
		tag            = 'function',
		args           = { {        type = T.Any } },
		rets           = { T.String },
		intrinsic_name = "type",
		name           = "type",
	} --[[SOL OUTPUT--]] 


	local is_local = true --[[SOL OUTPUT--]] 
	--s:declare_type( 'void',    T.Void ) -- Not a valid type, only allowed as a typelist
	s:declare_type( 'bool',   T.Bool,   where, is_local ) --[[SOL OUTPUT--]] 
	s:declare_type( 'int',    T.Int,    where, is_local ) --[[SOL OUTPUT--]] 
	s:declare_type( 'uint',   T.Uint,   where, is_local ) --[[SOL OUTPUT--]] 
	s:declare_type( 'number', T.Num,    where, is_local ) --[[SOL OUTPUT--]] 
	s:declare_type( 'string', T.String, where, is_local ) --[[SOL OUTPUT--]] 
	s:declare_type( 'any',    T.Any,    where, is_local ) --[[SOL OUTPUT--]] 
	s:declare_type( 'table',  T.Table,  where, is_local ) --[[SOL OUTPUT--]] 
	--s:declare_type( 'list',   T.List,   where, is_local ) -- use: [any]
	--s:declare_type( 'map',    T.Map,    where, is_local ) -- use: {any => any}
	s:declare_type( 'object', T.Object, where, is_local ) --[[SOL OUTPUT--]] 

	-- keywords are handles explicitly during parsing
	--s:declare_type( 'nil',     T.Nil)    -- for e.g.:   foo or bar or nil
	--s:declare_type( 'true',    T.True)
	--s:declare_type( 'false',   T.False)

	if not Scope.GLOBALS_IN_TOP_SCOPE then
		-- No more changes - user globals should be declared in module scope (a direct child)
		s.fixed = true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return s --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

----------------------------------------

return {} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 