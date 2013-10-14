--[[
A type can either be a particular value (number or string) or one of the following.
--]]

local U = require 'util'
local D = require 'sol_debug'

--[[
FIXME: recursive dependency
local S = require 'scope'
--]]
local T = {}


typedef Variable = {
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
}

typedef Scope = object



T.on_error = function(fmt, ...)
	local msg = string.format(fmt, ...)
	U.printf_err( "%s", msg )
	--error(msg, 2)
end


-- Types:
typedef T.TypeID = 'any'
                 or 'int_literal' or 'num_literal' or 'string_literal'
                 or 'nil' or 'true' or 'false' or 'int' or 'number' or 'string'
                 or 'table' or 'list' or 'map' or 'object' or 'function'
                 or 'variant' or 'identifier'
                 or 'varargs'
                 or 'extern' -- TODO: implement fully

var ATOMIC_TAGS = U.set{'any', 'int_literal', 'num_literal', 'string_literal',
                        'nil', 'true', 'false', 'int', 'number', 'string'}

typedef T.Type = {
	tag          : T.TypeID,
	pre_analyzed : bool?,    -- Temporary type reached by pre-analyze?
	where        : string?,  -- Where the type was declared (always set if pre_analyzed is true)
}

typedef T.Typelist = [T.Type]

typedef T.Any           : T.Type = { tag : 'any' }
typedef T.IntLiteral    : T.Type = { tag : 'int_literal',    value : int    }
typedef T.NumLiteral    : T.Type = { tag : 'num_literal',    value : number }
typedef T.StringLiteral : T.Type = {
	tag          : 'string_literal',
	str_quoted   : string,  -- As given in input, e.g:   "\"Hello\"\t'you!'"
	str_contents : string,  -- As Lua would treat it:    "Hello"	'you' 
}
typedef T.Nil           : T.Type = { tag : 'nil'     }
typedef T.True          : T.Type = { tag : 'true'    }
typedef T.False         : T.Type = { tag : 'false'   }
typedef T.Int           : T.Type = { tag : 'int'     }
typedef T.Num           : T.Type = { tag : 'number'     }
typedef T.String        : T.Type = { tag : 'string'  }

typedef T.Table : T.Type = {
	tag  : 'table',
}
typedef T.List : T.Type = {
	tag  : 'list',
	type : T.Type,
}
typedef T.Map : T.Type = {
	tag        : 'map',
	key_type   : T.Type,
	value_type : T.Type,
}
typedef T.Object : T.Type = {
	tag           : 'object',
	members       : { string => T.Type       },
	namespace     : { string => T.Identifier } ?,
	derived       : [ T.Identifier ]  or nil, -- Things that inherit us
	metatable     : T.Object?,
	class_type    : T.Object?,  -- If I am a class, this is my instance
	instance_type : T.Object?,  -- If I am an instance, this is my class
}

-- Very special: represents an unknown number of values, each of the encapsuled type
typedef T.VarArgs : T.Type = {
	tag  : 'varargs',
	type : T.Type,
}

typedef T.Function : T.Type = {
	tag            : 'function',
	args           : [ { name: string?, type: T.Type? } ], -- if first arg is 'self' we are expected to be a member function
	vararg         : T.VarArgs?, -- Any number of this type
	rets           : [T.Type]?,  -- list of return types
	name           : string,     -- Used for nicer error messages.
	intrinsic_name : string?,    -- SPECIAL - used for built-in function like 'require'
}

typedef T.Variant : T.Type = {
	tag      : 'variant',
	variants : [T.Type],
}

-- A typedef/alias.
typedef T.Identifier : T.Type = {
	tag         : 'identifier',
	scope       : Scope,
	var_name    : string?, -- If namespaced typedef, i.e.   typedef some_var.type  =  ...
	--var_        : Variable?, -- If namespaced typedef, i.e.   typedef some_var.type  =  ...
	name        : string,    -- The name of the type
	where       : string,    -- Point of declaration (file:line)
	first_usage : string?,   -- Point of first use
	type        : T.Type?,   -- Filled in by TypeCheck on declaration/assignement on typedef or declaration of 'var_' if any
}

-- An opaque type, e.g. a userdata.
-- Provides type-safety for identifiers passed around.
typedef T.Extern : T.Type = {
	tag   : 'extern',
	where : string,   -- Point of declaration (file:line)
	name  : string?,  -- Name of primary typedef, if any
}

------------------------------------------------------------------
-- Prototypes for common stuff:


-- Any: implicit convert to and from anything.
-- Used for interaction with Lua code.
T.Any  = { tag = 'any'  }  -- Single unknown value
T.AnyTypeList = {}   -- Unkown number of unknown values
--T.AnyTypeList = { { tag = 'varargs', type = T.Any } }  -- TODO

T.Nil      = { tag = 'nil'    }
T.True     = { tag = 'true'   }
T.False    = { tag = 'false'  }
T.String   = { tag = 'string' }
T.Num      = { tag = 'number'    }
T.Int      = { tag = 'int'    }
--T.Empty    = { tag = 'variant', variants = {} }

--T.Void     = T.Empty
T.Void     = {} -- empty type-list
T.Nilable  = T.Any  -- TODO

T.Uint = T.Int               -- TODO
T.Bool = { tag = 'variant',  variants = { T.True, T.False } }


-- General table - could be an object, list or map:
T.Table = { tag = 'table' }

-- Supertype of all objects:
T.Object = { tag = 'object', members = {} }

-- Supertype of all lists:
T.List = { tag = 'list', type = T.Any }

-- Supertype of all maps:
T.Map = { tag = 'map', key_type = T.Any, value_type = T.Any }

------------------------------------------------------------------

function T.is_type(x: any) -> bool
	return type(x) == 'table' and type(x.tag) == 'string'
end

T._empty_table = { tag = 'table' }

-- TODO: disallow=
function T.create_empty_table() -> T.Type
	--return { tag='object', members={} }
	--return T.Table
	return T._empty_table
end

-- TODO: remove
function T.is_empty_table(t: T.Type) -> bool
	--return t.tag == 'object' and next(t.members) == nil
	--return t.tag == 'table'
	--return T.follow_identifiers(t).tag == 'table'
	return t == T._empty_table
end


function T.is_void(ts: T.Typelist) -> bool
	return T.is_type_list(ts) and #ts == 0
end

function T.follow_identifiers(t: T.Type, forgiving: bool?) -> T.Type
	D.assert(t)

	if t.tag ~= 'identifier' then
		-- Early out
		return t
	end

	if forgiving == nil then forgiving = false end

	if _G.g_local_parse then
		forgiving = true
	end

	D.assert(T.is_type(t))

	if not t.type then
		--[[
		if t.type == T.Any then
			-- Maybe a local parse
			forgiving = true
		end
		--]]
		
		assert( t.scope )
		var scope = t.scope

		if t.var_name then
			-- TODO: var (when we can break cyclic depndency)
			var var_ = scope:get_var( t.var_name ) : Variable?  -- A namespace is always a variable
			if not var_ then
				T.on_error("%s: Failed to find namespace variable %q", t.first_usage, t.var_name)
				t.type = T.Any
			elseif not var_.namespace then
				if forgiving then
					return T.Any
				else
					T.on_error("%s: Variable '%s' is not a namespace (looking up '%s')", t.first_usage, var_.name, t.name)
					t.type = T.Any
				end
			else
				t.type = var_.namespace[t.name]
				var_.num_reads = var_.num_reads + 1
				if not t.type then
					T.on_error("%s: type %s not found in namespace '%s'", t.first_usage, t.name, var_.name)
					t.type = T.Any
				end
			end
		else
			t.type = t.scope:get_type( t.name )
			if not t.type then
				T.on_error("%s: typename '%s' not found", t.first_usage, t.name)
				t.type = T.Any
			end
		end

		-- No more need to write to it:
		U.make_const(t)
	end

	return T.follow_identifiers(t.type)
end


-- Helper:
function T.is_integral(str: string) -> bool
	if str:match('0x%w+') then
		-- Hex is intregral
		return true
	elseif str:match('%D') then -- (%d == digit, %D == non-digit)
		-- Non-digits == real
		return false
	else
		-- All digits == integral
		return true
	end
end


function T.from_num_literal(str: string) -> T.IntLiteral or T.NumLiteral or nil
	local n = tonumber(str)

	if n then
		if T.is_integral(str) then
			return {
				tag   = 'int_literal',
				value = n
			}
		else
			return {
				tag   = 'num_literal',
				value = n
			}
		end
	else
		return nil -- Fail
	end
end


function T.from_string_literal(str: string) -> T.StringLiteral
	return {
		tag          = 'string_literal';
		str_quoted   = str;
		str_contents = U.unescape(str);
	}
end


function T.is_type_list(list: any) -> bool
	--return U.is_array(list)
	if not U.is_array(list) then return false end
	for _,v in pairs(list) do
		if not T.is_type(v) then
			return false
		end
	end
	return true
end


function T.is_obj_obj(d: T.Object, b: T.Object, problem_rope: [string]?) -> bool
	assert(d.tag == 'object')
	assert(b.tag == 'object')

	for id, b_type in pairs(b.members) do
		local d_type = d.members[id]
		if not d_type then
			if not T.is_nilable(b_type) then
				if problem_rope then
					problem_rope #= string.format("member '%s' missing", id)
				end

				return false
			end
		elseif not T.isa(d_type, b_type, problem_rope) then
			if problem_rope then
				problem_rope #=
					string.format("member '%s' of wrong type (got: %s, expected: %s)",
					              id, U.quote_or_indent(T.name(d_type)), U.quote_or_indent(T.name(b_type)))
			end
			return false
		end
	end

	-- TODO: check metatables, super-classes etc?

	return true
end


-- i.e., is type 'd' a subset of type 'b' ?
--[[
True:
T.isa(T.Int, T.Num)
T.isa(T.False, T.Bool)
--]]

-- Memoization:
-- true   -> yes, it is
-- false  -> no, and no error string generated yet
-- string -> no, and here's the error string
local RECURSION = {'RECURSION'}
var isa_memo = {} : {T.Type => {T.Type => true or false or string or [string]}}

function T.isa(d: T.Type, b: T.Type, problem_rope: [string]?) -> bool
	D.assert(d)
	D.assert(b)
	local res = isa_memo[d] and isa_memo[d][b]
	D.assert(res ~= RECURSION)

	if res == true then
		return true
	end

	if problem_rope then
		if res == false or res == nil then
			-- We need to generate a problem description:
			isa_memo[d] = isa_memo[d] or {}
			isa_memo[d][b] = RECURSION

			local isa_rope = {}
			T.isa_raw(d, b, isa_rope)
			res = table.concat(isa_rope, '\n')

			isa_memo[d][b] = res
		end
		assert(type(res) == 'string')
		problem_rope #= res
		return false
	else
		-- No problem description needed
		if res==nil then
			isa_memo[d] = isa_memo[d] or {}
			isa_memo[d][b] = RECURSION

			res = T.isa_raw(d, b)

			isa_memo[d][b] = res
		end

		return res
	end
end


function T.isa_raw(d: T.Type, b: T.Type, problem_rope: [string]?) -> bool
	if d == b then
		return true -- Early out optimization
	end

	D.assert(T.is_type(d))
	D.assert(T.is_type(b))
	d = T.follow_identifiers(d)
	b = T.follow_identifiers(b)

	--U.printf("isa, b: %s, d: %s", T.name(b), T.name(d))
	if d == b then
		return true -- Early out optimization
	end


	if b.tag == 'any' or d.tag == 'any' then
		-- 'any' can become anything
		-- Anything can become 'any'
		return true
	end

	if b.tag == 'variant' then
		for _,v in ipairs(b.variants) do
			if T.isa(d, v, problem_rope) then
				return true
			end
		end
	end

	if d.tag == 'variant' then
		local function all_are_b() -> bool
			for _,v in ipairs(d.variants) do
				if not T.isa(v, b, problem_rope) then
					return false
				end
			end
			return true
		end
		return all_are_b()
	end


	if d.tag == 'int_literal' then
		if (b.tag == 'int_literal' or b.tag == 'num_literal') and b.value == d.value then
			-- Same value
			return true
		end

		return b.tag == 'number' or b.tag == 'int'
	end

	if d.tag == 'num_literal' then
		if b.tag == 'num_literal' and b.value == d.value then
			-- Same value
			return true
		end

		return b.tag == 'number'
	end

	if d.tag == 'string_literal' then
		if b.tag == 'string_literal' and b.str_contents == d.str_contents then
			-- Same value
			return true
		end

		return b.tag == 'string'
	end


	if b.tag == 'table' then
		return d.tag == 'table'
		    or d.tag == 'list'
		    or d.tag == 'map'
		    or d.tag == 'object'
	end

	if T.is_empty_table(d) then
		-- TODO: remove
		return b.tag == 'list' or b.tag == 'map' or b.tag == 'table' or
		       (b.tag == 'object' and U.table_empty(b.members) and b.derived == nil and b.metatable == nil)
	end

	if d.tag == 'false' then
		return b.tag == 'false'
	elseif d.tag == 'true' then
		return b.tag == 'true'
	elseif d.tag == 'nil' then
		return b.tag == 'nil'
	elseif d.tag == 'string' then
		return b.tag == 'string'
	elseif d.tag == 'number' then
		return b.tag == 'number'
	elseif d.tag == 'int' then
		return b.tag == 'number'
		    or b.tag == 'int'
	elseif d.tag == 'table' then
		return false -- Already covered
	elseif d.tag == 'extern' then
		return d == b  -- Same extern!
	elseif d.tag == 'list' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'list'
		  and  T.isa(d.type, b.type, problem_rope) -- [int] isa [num]  -- FIXME: make strictly equal?
	elseif d.tag == 'map' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'map'
		  and  T.isa(d.key_type,   b.key_type, problem_rope)    -- {int, string}  isa  {num, string}  -- FIXME: make strictly equal?
		  and  T.isa(d.value_type, b.value_type, problem_rope)  -- {string, int}  isa  {string, num}  -- FIXME: make strictly equal?
	elseif d.tag == 'object' then
		if b.tag == 'object' then
			return T.is_obj_obj(d, b, problem_rope)
		else
			return false
		end
	elseif d.tag == 'function' then
		if b.tag ~= 'function' then
			return false
		end

		-- TODO: allow different arg count WRT vararg
		if #d.args ~= #b.args then
			if problem_rope then problem_rope #= "Differing number of arguments" end
			return false
		end

		for i = 1, #d.args do
			if not T.isa(d.args[i].type, b.args[i].type, problem_rope) then
				if problem_rope then problem_rope #= "Argument "..i.." differs" end
				return false
			end
		end

		if b.rets then
			if not T.isa_typelists(d.rets, b.rets, problem_rope) then
				if problem_rope then problem_rope #= "Return types differs" end
				return false
			end
		end

		if (d.vararg==nil) ~= (b.vararg==nil) then
			if problem_rope then problem_rope #= "One function has var-args" end
			return false
		end

		if d.vararg and b.vararg then
			if not T.isa(d.vararg, b.vararg, problem_rope) then
				if problem_rope then problem_rope #= "Var-arg types differ" end
				return false
			end
		end

		return true
	elseif d.tag == 'varargs' and b.tag == 'varargs' then
		return T.isa(d.type, b.type)
	else
		--error('isa failed: derived: ' .. U.pretty(d) .. ', base: ' .. U.pretty(b))
		return error('isa failed: derived: ' .. T.name(d) .. ', base: ' .. T.name(b))
	end
end


-- Accepts typelists
function T.isa_typelists(d: [T.Type]?, b: [T.Type]?, problem_rope: [string]?) -> bool
	if d==nil and b==nil then return true  end
	if d==nil or  b==nil then return false end

	if d == T.AnyTypeList or b == T.AnyTypeList then
		return true
	end

	if #d ~= #b then return false end

	for i = 1,#d do
		if not T.isa(d[i], b[i], problem_rope) then
			return false
		end
	end

	return true
end


function T.is_nilable(a: T.Type) -> bool
	a = T.follow_identifiers(a)
	if a == T.Any then return true end
	if a == T.Nil then return false end

	var has_nil     = false
	var has_non_nil = false

	local function recurse(t: T.Type)
		if t.tag == 'variant' then
			for _,v in ipairs(t.variants) do
				recurse(v)
			end
		elseif t == T.Any then
			has_nil = true
			has_non_nil = true
		elseif t == T.Nil then
			has_nil = true
		else
			has_non_nil = true
		end
	end
	recurse(a)

	--return T.could_be(a, T.Nil)
	return has_nil and has_non_nil
end


function T.make_nilable(a: T.Type) -> T.Type
	if false then
		if T.is_nilable(a) then
			return a
		else
			return T.variant(a, T.Nil)
		end
	else
		--return T.make_variant(a, T.Nil)  -- FIXME: produces  Foo or nil or nil
		return T.variant(a, T.Nil)
	end
end


function T.is_any(a: T.Type) -> bool
	local forgiving = true
	a = T.follow_identifiers(a, forgiving)

	if a.tag == 'any' then
		return true

	elseif a.tag == 'variant' then
		for _,v in ipairs(a.variants) do
			if T.is_any(v) then
				return true
			end
		end
	end

	return false
end


-- Can it be used in boolean expression?
function T.is_bool(a: T.Type) -> bool
	a = T.follow_identifiers(a)
	return T.is_any(a) or T.isa(a, T.Bool) or T.is_nilable(a)
end


function T.has_tag(t: T.Type, target: string) -> bool
	t = T.follow_identifiers(t)

	if t.tag == target then
		return true

	elseif T.is_variant(t) then
		for _,v in ipairs(t.variants) do
			--print("Find: searching variant " .. T.name(v))
			if T.has_tag(v, target) then
				return true
			end
		end
	end
	return false
end

-- Memoization:
-- true   -> yes, it is
-- false  -> no, and no error string generated yet
-- string -> no, and here's the error string
var could_be_memo = {} : {T.Type => {T.Type => true or false or string or [string]}}

function T.could_be(d: T.Type, b: T.Type, problem_rope: [string]?) -> bool
	D.assert(d)
	D.assert(b)
	local res = could_be_memo[d] and could_be_memo[d][b]
	D.assert(res ~= RECURSION)

	if res == true then
		return true
	end

	if problem_rope then
		if res == false or res == nil then
			-- We need to generate a problem description:
			could_be_memo[d] = could_be_memo[d] or {}
			could_be_memo[d][b] = RECURSION

			local could_be_rope = {}
			T.could_be_raw(d, b, could_be_rope)
			res = table.concat(could_be_rope, '\n')

			could_be_memo[d][b] = res
		end
		assert(type(res) == 'string')
		problem_rope #= res
		return false
	else
		-- No problem description needed
		if res==nil then
			could_be_memo[d] = could_be_memo[d] or {}
			could_be_memo[d][b] = RECURSION

			res = T.could_be_raw(d, b)

			could_be_memo[d][b] = res
		end

		return res
	end
end



-- is a variant of 'a' a 'b' ?
-- T.could_be(T.Bool, T.False)  == true
-- T.could_be(some_nilable, T.Nil)  == true
-- T.could_be(int or bool, string or bool)  == true
-- T.could_be(int or nil, string or nil)  == false
function T.could_be_raw(a: T.Type, b: T.Type, problem_rope: [string]?) -> bool
	if a==b then
		-- Early out:
		return true
	end

	D.assert( T.is_type(a) )
	D.assert( T.is_type(b) )

	a = T.follow_identifiers(a)
	b = T.follow_identifiers(b)

	if a == b then
		return true -- Early out optimization
	end

	if a.tag == 'any' then return true end
	if b.tag == 'any' then return true end

	if a.tag == 'variant' then
		for _,v in ipairs(a.variants) do
			if v==b then
				return true
			elseif v~=T.Nil and T.could_be(v, b, problem_rope) then
				return true
			end
		end
		return false
	elseif b.tag == 'variant' then
		for _,v in ipairs(b.variants) do
			if v==a then
				return true
			elseif v~=T.Nil and T.could_be(a, v, problem_rope) then
				return true
			end
		end
		return false

	elseif b.tag == 'table' then
		return a.tag == 'table'
		    or a.tag == 'list'
		    or a.tag == 'map'
		    or a.tag == 'object'

	elseif a.tag == 'list' then
		return b.tag == 'list'
		   and T.could_be(a.type, b.type, problem_rope)

	elseif a.tag == 'map' then
		return b.tag == 'map'
		   and T.could_be(a.key_type,   b.key_type,   problem_rope)
		   and T.could_be(a.value_type, b.value_type, problem_rope)

	elseif a.tag == 'object' then
		if b.tag ~= 'object' then return false end

		for id, b_type in pairs(b.members) do
			local a_type = a.members[id]
			if a_type and not T.could_be(a_type, b_type, problem_rope) then
				if problem_rope then
					problem_rope #=
						string.format("member '%s' of wrong type (got: %s, expected: %s)",
						              id, U.quote_or_indent(T.name(a_type)), U.quote_or_indent(T.name(b_type)))
				end
				return false
			end
		end

		-- TODO: check metatables, super-classes etc?

		return true

	else
		if T.isa(a, b, problem_rope) then
			return true
		elseif T.isa(b, a, problem_rope) then
			return true
		else
			return false
		end
	end
end

function T.could_be_tl(al: T.Typelist, bl: T.Typelist, problem_rope: [string]?) -> bool
	if al == T.AnyTypeList or bl == T.AnyTypeList then
		return true
	end

	if #al ~= #bl then
		if problem_rope then
			problem_rope #= "typelists of unequal length"
		end

		return false
	end

	for i = 1,#al do
		if not T.could_be(al[i], bl[i], problem_rope) then
			return false
		end
	end

	return true
end


-- Tests if a type has the potential to be true and/or false
function T.could_be_true_false(a: T.Type) -> bool, bool
	a = T.follow_identifiers(a)
	if a == T.Any then
		return true, true
	elseif a == T.Nil or a == T.False then
		return false, true
	elseif T.is_variant(a) then
		var t,f = false,false
		for _,v in ipairs(a.variants) do
			var vt,vf = T.could_be_true_false(v)
			t = t or vt
			f = f or vf
			if t and f then
				return true,true
			end
		end
		return t,f
	else
		return true, false
	end
end


-- is 'a' a boolean expresson that could be evaluates as either true and false?
-- If not, we are doing something like    if always_true then ...
-- Which is almost certainly wrong
function T.is_useful_boolean(a: T.Type) -> bool
	var t,f = T.could_be_true_false(a)
	return t and f
end


----------------------------------------------


function T.is_atomic(t: T.Type) -> bool
	return ATOMIC_TAGS[t.tag]-- or t.tag == 'identifier'
end

--[=[
function T.is_simple(t: T.Type) -> bool
	--[[
	if T.is_atomic(t) then return true end
	if t.tag == 'list' then return T.is_simple(t.type) end
	if t.tag == 'variant' then
		for _,v in ipairs(t.variants) do
			if not T.is_simple(v) then
				return false
			end
		end
		return true
	end

	return false
	--]]
	return t.tag ~= 'object'
end
--]=]

function T.table_id(t: table) -> string
	return tostring(t):gsub("table: ", "")
end

function T.format_type(root: T.Type, verbose: bool?) -> string
	if verbose == nil then verbose = false end

	var written_objs = {} : {T.Object}
	local output_types, output_obj

	local function output(typ: T.Type, indent: string) -> string
		local next_indent = indent .. U.INDENTATION

		if typ.tag == 'any' then
			return 'any'

		elseif typ.tag == 'variant' then
			local function output_packaged(typ: T.Type, indent: string) -> string
				if typ.tag == 'function' and typ.rets then
					return '('..output(typ, indent)..')'
				else
					return output(typ, indent)
				end
			end

			if #typ.variants == 0 then
				D.break_()
				return "void [EMPTY VARIANTS]"
			elseif #typ.variants == 1 then
				return output(typ.variants[1], indent)
			else
				if #typ.variants == 2
					and typ.variants[2] == T.Nil 
					and typ.variants[1].tag ~= 'variant'
					and typ.variants[1].tag ~= 'function'
				then
					return output_packaged(typ.variants[1], next_indent) .. '?'
				end

				if #typ.variants == 2
					and typ.variants[1] == T.True
					and typ.variants[2] == T.False
				then
					return 'bool'
				end

				if #typ.variants == 2
					and typ.variants[1] == T.False
					and typ.variants[2] == T.True
				then
					return 'bool'
				end

				local str = ''
				for i,t in ipairs(typ.variants) do
					str ..= output_packaged(t, next_indent)
					if i ~= #typ.variants then
						str ..= ' or '
					end
				end
				return str
			end

		elseif typ.tag == 'object' then
			--verbose = false -- FIXME 

			var obj = typ : T.Object

			if written_objs[obj] then
				return '<RECURSION '..T.table_id(obj)..'>'
			end

			written_objs[obj] = true
			var ret = output_obj(obj, indent)
			written_objs[obj] = nil

			return ret

		elseif typ.tag == 'list' then
			return '[' .. output(typ.type, next_indent) .. ']'

		elseif typ.tag == 'map' then
			if typ.value_type == T.True then
				-- A set
				return '{' .. output(typ.key_type, next_indent) .. '}'
			else
				-- A map
				return '{' .. output(typ.key_type, next_indent) .. ' => ' .. output(typ.value_type, next_indent) .. '}'
			end

		elseif typ.tag == 'function' then
			local str = 'function('
			for i,arg in ipairs(typ.args) do
				if arg.name then
					str ..= arg.name
				end
				if arg.type and not T.is_any(arg.type) then
					if arg.name ~= 'self' then -- Potential recursion (object has function taking object as arg...)
						str ..= ": " .. output(arg.type, next_indent)
					end
				end
				if i ~= #typ.args or typ.vararg then
					str ..= ", "
				end
			end
			if typ.vararg then
				str ..= "..."
				if not T.is_any(typ.vararg) then
					str ..= " : " .. output(typ.vararg.type, next_indent)
				end
			end
			str ..= ')'
			if typ.rets then
				str ..= ' -> ' .. output_types(typ.rets, next_indent)
			else
				--str ..= ' -> ...'
			end
			return str

		elseif typ.tag == 'int_literal' or typ.tag == 'num_literal' then
			return '' .. typ.value

		elseif typ.tag == 'string_literal' then
			return typ.str_quoted

		elseif typ.tag == 'identifier' then
			if (verbose or _G.g_spam) and typ.type then
			--if typ.type then
				return string.format('%s (%s)', typ.name, output(typ.type, next_indent))
			else
				return string.format('%s', typ.name)
			end

		elseif typ.tag == 'extern' then
			if typ.name then
				return typ.name .. '<extern>'
			else
				return '<extern>'
			end
		else
			return typ.tag
		end
	end


	output_obj = function(obj: T.Object, indent: string) -> string
		local next_indent = indent .. U.INDENTATION

		local str = ''
		if obj.namespace then
			str ..= next_indent .. '-- Types:\n'

			var type_list = {} : T.Typelist
			for k,v in pairs(obj.namespace) do
				type_list #= {name = k, type = v}
			end
			table.sort(type_list, function(a,b) return a.name < b.name end)
			--table.sort(type_list, function(a,b) return a.type.where < b.type.where end)
			for _,m in ipairs(type_list) do
				str ..= next_indent .. 'typedef ' .. m.name .. " = " .. output(m.type, next_indent) .. ";\n"
			end
		end

		if not U.table_empty(obj.members) then
			if str ~= '' then
				str ..= '\n' .. next_indent .. '-- Members:\n'
			end

			var mem_list = {} : [{name:string, type:T.Type}]
			var widest_name = 0
			for k,v in pairs(obj.members) do
				mem_list #= {name = k, type = v}
				widest_name = math.max(widest_name, #k)
			end
			table.sort(mem_list, function(a,b) return a.name < b.name end)

			var type_indent = next_indent
			for i = 1,widest_name+2 do
				type_indent = type_indent..' '
			end

			for _,m in ipairs(mem_list) do
				str ..= next_indent .. m.name .. ": "

				-- Align:
				for i = #m.name, widest_name - 1 do
					str ..= ' '
				end

				str ..= output(m.type, type_indent) .. ";\n"
			end
		end

		if obj.metatable then
			if str ~= '' then
				--str ..= '\n' .. next_indent .. '-- metatable:\n'
				str ..= '\n'
			end

			str ..= next_indent .. "!! metatable:     " .. output(obj.metatable, next_indent) .. '\n'
		end

		if obj.class_type then
			if str ~= '' then str ..= '\n' end
			str ..= next_indent .. "!! class_type:    " .. output(obj.class_type, next_indent) .. '\n'
		end

		if obj.instance_type then
			if str ~= '' then str ..= '\n' end
			str ..= next_indent .. "!! instance_type: " .. output(obj.instance_type, next_indent) .. '\n'
		end

		var str_timmed = U.trim(str)

		var full = ''

		if str_timmed == '' then
			full = '{ }'
		elseif U.count_line_breaks(str_timmed) == 0 then
			-- One-liner - e.g.   { foo: int }
			full = '{ ' .. str_timmed ..' }'
		else
			local shortened = str_timmed:gsub('%s%s+', '  ')
			shortened = shortened:gsub(":%s+", ': ')

			if #shortened < 50 then
				-- One-line - e.g.  { x: number  y: number }
				full = '{ ' .. shortened ..' }'
			else
				full = '{\n' .. str .. indent ..'}'
			end
		end

		--full = '<'..T.table_id(obj)..'>'..full -- great for debugging

		if obj.class_type then
			return '<instance>' .. full
		elseif obj.instance_type then
			return '<class>' .. full
		else
			return full
		end
	end


	output_types = function(typelist: [T.Type], indent: string)
		if #typelist == 0 then
			return "void"
		elseif #typelist == 1 then
			return output(typelist[1], indent)
		else
			local str=''
			for i,t in ipairs(typelist) do
				str ..= output(t, indent)
				if i ~= #typelist then
					str ..= ', '
				end
			end
			return str
		end
	end

	return output(root, "")
end


function T.names(typ: [T.Type], verbose: bool?) -> string
	if #typ == 0 then
		return "void"
	else
		local str=''
		for i,t in ipairs(typ) do
			str ..= T.name(t, verbose)
			if i ~= #typ then
				str ..= ', '
			end
		end
		return str
	end
end


function T.name(typ: T.Type or [T.Type] or nil, verbose: bool?) -> string
	if verbose == nil then verbose = false end

	if typ == nil then
		--D.error_()
		return 'NIL'
	end
	
	if typ == T.AnyTypeList then
		return "..."

	elseif T.is_type_list(typ) then
		--D.error_()	
		return T.names(typ, verbose)
	end

	D.assert( T.is_type(typ) )

	return T.format_type(typ, verbose)
end


function T.name_verbose(typ: T.Type or [T.Type] or nil) -> string
	return T.name(typ, true)
end

function T.is_variant(t: T.Type) -> T.Variant?
	t = T.follow_identifiers(t)
	if t.tag == 'variant' then
		return t
	else
		return nil
	end
end


function T.variant_has(v: T.Variant, e: T.Type) -> bool
	for _,t in ipairs(v.variants) do
		if T.isa(e, t) then
			return true
		end
	end
	return false
end


function T.extend_variant_one(v: T.Variant, e: T.Type) -> T.Variant
	--if #v.variants > 15 then
	--	U.printf("WARNING: extremely long variant: %s", T.name(v))
	--end

	if e == T.Any then
		return {
			tag      = 'variant',
			variants = { T.Any },
		}
	else
		var ev = T.is_variant(e)
		if ev then
			for _,et in ipairs(ev.variants) do
				v = T.extend_variant_one(v, et)
			end
		elseif not T.variant_has(v, e) then
			v = T.clone_variant(v) -- else we confuse memoized isa
			v.variants #= e
		end
		return v
	end
end


function T.extend_variant(v: T.Variant, ...) -> T.Variant
	assert( T.is_variant(v) )

	for _,e in ipairs{...} do
		v = T.extend_variant_one(v, e)

		if e == T.Any then
			-- Early out
			break
		end
	end

	return v
end


-- Remove a type from a variant
function T.variant_remove(t: T.Type, remove_this_type: T.Type) -> T.Type
	t = T.follow_identifiers(t)

	assert(not T.is_any(remove_this_type))

	if T.is_any(t) then
		return t
	end

	var v = T.make_variant(t)
	assert(v ~= t)

	local i = 1
	while i <= #v.variants do
		if T.is_variant(v.variants[i]) then
			v.variants[i] = T.variant_remove(v.variants[i], remove_this_type)
			i +=  1
		elseif T.isa(v.variants[i], remove_this_type) then
			table.remove( v.variants, i )
		else
			i +=  1
		end
	end

	return v
end


function T.make_variant(...) -> T.Variant
	local v = {
		tag = "variant",
		variants = { }
	}
	v = T.extend_variant(v, ...)
	return v
end


function T.clone_variant(v: T.Variant) -> T.Variant
	assert( T.is_variant(v) )
	return {
		tag      = 'variant',
		variants = U.shallow_clone(v.variants),
	}
end


-- Return a or b
function T.variant(a: T.Type?, b: T.Type?) -> T.Type?
	if a == b   then return a end
	if a == nil then return b end
	if b == nil then return a end
	a = T.follow_identifiers(a) -- FIXME
	b = T.follow_identifiers(b) -- FIXME
	if a == T.Any then return T.Any end
	if b == T.Any then return T.Any end

	if T.isa(a, b) then return b end
	if T.isa(b, a) then return a end

	local a_is_variant = T.is_variant(a)
	local b_is_variant = T.is_variant(b)

	if a_is_variant and b_is_variant then
		for _,e in ipairs(b.variants) do
			a = T.extend_variant_one( a, e )
		end
		return a
	elseif a_is_variant then
		return T.extend_variant_one(a, b)
	elseif b_is_variant then
		return T.extend_variant_one(b, a)
	else
		return T.make_variant(a, b)
	end
end


local function un_literal(t: T.Type) -> T.Type
	if t.tag == 'int_literal' then return T.Int end
	if t.tag == 'num_literal' then return T.Num end
	return t
end

-- used for expressions like "a + b"
-- works for tables, or numerics, i.e.   num+int == num
function T.combine_num_int(a: T.Type, b: T.Type) -> T.Num or T.Int
	if T.is_any(a)                  then return T.Num end
	if T.has_tag(a, 'number')       then return T.Num end
	if T.has_tag(a, 'num_literal')  then return T.Num end
	if T.is_any(a)                  then return T.Num end
	if T.has_tag(b, 'number')       then return T.Num end
	if T.has_tag(b, 'num_literal')  then return T.Num end
	return T.Int
end


function T.combine_type_lists(a: T.Typelist?, b: T.Typelist?, forgiving: bool?) -> T.Typelist?
	--forgiving = forgiving or true
	if forgiving == nil then
		forgiving = true
	end

	if _G.g_spam then
		--U.printf('combine_type_lists(%s, %s)', T.name(a), T.name(b))
	end

	if a == nil then return b end
	if b == nil then return a end

	if a == T.AnyTypeList then return T.AnyTypeList end
	if b == T.AnyTypeList then return T.AnyTypeList end	

	if forgiving then
		if #a < #b  then
			a = U.shallow_clone(a)
			while #a < #b do
				a #= T.Nil
			end
		end

		if #b < #a  then
			b = U.shallow_clone(b)
			while #b < #a do
				b #= T.Nil
			end
		end
	end

	if #a ~= #b then
		local msg = string.format("Return statement with different number of values than the previous: %s vs %s", T.name(a), T.name(b))
		return error( msg )
	else
		var ret = {} : T.Typelist
		for i = 1, #a do
			ret[i] = T.variant( a[i], b[i] )
			if _G.g_spam then
				U.printf('variant(%s, %s) = %s', T.name(a[i]), T.name(b[i]), T.name(ret[i]))
			end
		end
		return ret
	end
end

function T.broaden_non_nil(t: T.Type) -> T.Type
	if t.tag == 'int_literal' then
		return T.Int
	elseif t.tag == 'num_literal' then
		return T.Num
	elseif t.tag == 'string_literal' then
		return T.String
	elseif t == T.True or t == T.False then
		return T.Bool
	elseif t.tag == 'list' then
		return { tag = 'list', type = T.broaden_non_nil(t.type) }
	elseif t.tag == 'map' then
		return {
			tag        = 'map',
			key_type   = T.broaden_non_nil(t.key_type),
			value_type = T.broaden_non_nil(t.value_type),
		}
	elseif t.tag == 'variant' then
		-- false?   ->  bool?
		var ret = {
			tag      = 'variant',
			variants = {} : [T.Variant]
		}
		for ix,v in ipairs(t.variants) do
			ret.variants[ix] = T.broaden_non_nil(v)
		end
		return ret
	else
		return t
	end
end


-- For assigning type to a variable
function T.broaden(t: T.Type?) -> T.Type?
	if t == nil then
		return nil
	elseif t == T.Nil then
		--[[
		obj.member = nil
		if obj.member then  -- should not warn!
		end
		obj.member = 42
		--]]
		return T.Nilable
	else
		return T.broaden_non_nil(t)
	end
end


function T.simplify(t: T.Type) -> T.Type
	t = T.follow_identifiers(t)

	if t.tag == 'variant' then
		if false then
			-- Quick
			if #t.variants == 1 then
				return t.variants[1]
			else
				return t
			end
		else
			local v = T.make_variant()

			for _,variant in ipairs(t.variants) do
				variant = T.simplify(variant)
				--v = T.variant(v, variant)
				v = T.extend_variant_one(v, variant)

				if #v.variants == 2 and v.variants[1] == v.variants[2] then
					D.break_()
				end
			end

			--U.printf("Simplified '%s' to '%s'", T.name(t), T.name(v))

			if #v.variants == 1 then
				return v.variants[1]
			else
				--D.assert(v.variants[1] ~= v.variants[2], "Simplified variant has duplicates")
				return v
			end
		end
	else
		return t
	end
end


-- Usage: for v in T.all_variants(some_type) do ... end
function T.all_variants(typ: T.Type) -> function() -> T.Type?
	local function all_vars(t: T.Type)
		if t.tag == 'variant' then
			for _,v in ipairs(t.variants) do
				all_vars(v)
			end
		else
			coroutine.yield(t)
		end
	end

	return coroutine.wrap(
		function()
			all_vars(typ)
		end)
end


function T.is_instance(typ: T.Object) -> bool
	-- If we are associated with a class, we are an instance of that class
	return typ.class_type ~= nil
end

function T.is_class(typ: T.Object) -> bool
	return typ.instance_type ~= nil
end

function T.should_extend_in_situ(typ: T.Type) -> bool
	return T.is_instance(typ)
end

function T.find_meta_method(t: T.Type, name: string) -> T.Type?
	t = T.follow_identifiers(t)
	if t.tag == 'variant' then
		for _,v in ipairs(t.variants) do
			var mm = T.find_meta_method(v, name)
			if mm then return mm end
		end
	elseif t.tag == 'object' then
		if t.metatable then
			return t.metatable.members[name]
		end
	end
	return nil
end

-- Recurses on variants and calls lambda on all non-variants.
-- It combines the results into a variant.
--typedef TypeVisitor = function(T.Type)->T.Type?
--function T.visit_and_combine(t: T.Type, lambda: TypeVisitor) -> T.Type?
function T.visit_and_combine(t: T.Type, lambda: function(T.Type)->T.Type?) -> T.Type?
	D.assert(T.is_type(t))
	t = T.follow_identifiers(t)
	D.assert(T.is_type(t))

	if t.tag == 'variant' then
		var ret = nil : T.Type?
		for _,v in ipairs(t.variants) do
			D.assert(T.is_type(v))
			local tmp = T.visit_and_combine(v, lambda)
			ret = T.variant(ret, tmp)
		end
		return ret

	else
		local ret = lambda(t)
		return ret
	end
end

function T.visit(t: T.Type, lambda: function(T.Type))
	t = T.follow_identifiers(t)

	if t.tag == 'variant' then
		for _,v in ipairs(t.variants) do
			T.visit(v, lambda)
		end

	else
		lambda(t)
	end
end


return T
