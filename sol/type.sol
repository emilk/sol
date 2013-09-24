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
	scope      : Scope,
	name       : string,
	type       : T.Type?,
	is_global  : bool,
	references : int,
	namespace  : { string => T.Type } ?,
}

typedef Scope = {
	parent   : Scope?,
	locals   : [Variable],
	globals  : [Variable],
	typedefs : { string => T.Type },
	vararg   : Variable?,  -- if non-nil, points to a variable named '...' with the type of T.VarArgs

	--get_scoped_type : function(self, name: string) -> T.Type?
}



T.on_error = function(fmt, ...)
	local msg = string.format(fmt, ...)
	U.printf_err( "%s", msg )
	error(msg, 2)
end


-- Types:
typedef T.TypeID = 'any'
                 or 'int_literal' or 'num_literal' or 'string_literal'
                 or 'nil' or 'true' or 'false' or 'int' or 'number' or 'string'
                 or 'table' or 'list' or 'map' or 'object' or 'function'
                 or 'variant' or 'identifier'
                 or 'varargs'

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
typedef T.StringLiteral : T.Type = { tag : 'string_literal', value : string }
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
T.Bool = { tag = 'variant',  variants = { T.False, T.True } }


-- General table - could be an object, list or map:
T.Table = { tag = 'table' }

-- Supertype of all objects:
T.Object = { tag = 'object', members = {} }

-- Supertype of all lists:
T.List = { tag = 'list', type = T.Any }

-- Supertype of all maps:
T.Map = { tag = 'map', key_type = T.Any, value_type = T.Any }

------------------------------------------------------------------

function T.is_type(x) -> bool
	return type(x) == 'table' and type(x.tag) == 'string'
end

--T._empty_table = { tag = 'table' }

-- TODO: disallow=
function T.create_empty_table() -> T.Type
	--return { tag='object', members={} }
	return T.Table
	--return T._empty_table
end

-- TODO: remove
function T.is_empty_table(t: T.Type) -> bool
	--return t.tag == 'object' and next(t.members) == nil
	--return t.tag == 'table'
	return T.follow_identifiers(t).tag == 'table'
	--return t == T._empty_table
end


function T.follow_identifiers(t : T.Type, forgiving: bool?) -> T.Type
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

		if t.var_name then
			local var_ = t.scope:get_var( t.var_name )  -- A namespace is always a variable
			if not var_ then
				T.on_error("Failed to find namespace variable %q", t.var_name)
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


local function unquote(str: string) -> string
	-- FIXME: unquote is unsafe
	return loadstring("return "..str)()
end


function T.from_string_literal(str: string) -> T.StringLiteral
	return {
		tag   = 'string_literal',
		value = unquote( str)   -- No quotes
	}
end


function T.is_type_list(list)
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
					table.insert(problem_rope, string.format("member '%s' missing", id))
				end

				return false
			end
		elseif not T.isa(d_type, b_type, problem_rope) then
			if problem_rope then
				table.insert(problem_rope,
					string.format("member '%s' of wrong type (got: %s, expected: %s)",
					              id, U.quote_or_indent(T.name(d_type)), U.quote_or_indent(T.name(b_type))))
			end
			return false
		end
	end
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
var<{T.Type => {T.Type => true or false or string}}> isa_memo = {}

function T.isa(d: T.Type, b: T.Type, problem_rope: [string]?) -> bool
	local res = isa_memo[d] and isa_memo[d][b]
	if res == true then
		return true
	end

	if problem_rope then
		if res == false or res == nil then
			-- We need to generate a problem description:
			local isa_rope = {}
			T.isa_raw(d, b, isa_rope)
			res = table.concat(isa_rope, '\n')
			isa_memo[d] = isa_memo[d] or {}
			isa_memo[d][b] = res
		end
		assert(type(res) == 'string')
		problem_rope[#problem_rope + 1] = res
		return false
	else
		-- No problem description needed
		if res==nil then
			res = T.isa_raw(d, b)
			isa_memo[d] = isa_memo[d] or {}
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

	if b.tag == 'variant' then
		for _,v in ipairs(b.variants) do
			if T.isa(d, v) then
				return true
			end
		end
	end

	if d.tag == 'variant' then
		local function all_are_b()
			for _,v in ipairs(d.variants) do
				if not T.isa(v, b) then
					return false
				end
			end
			return true
		end
		return all_are_b()
	end


	if b.tag == 'any' or d.tag == 'any' then
		-- 'any' can become anything
		-- Anything can become 'any'
		return true
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
		if b.tag == 'string_literal' and b.value == d.value then
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
	elseif d.tag == 'list' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'list'
		  and  T.isa(d.type, b.type) -- [int] isa [num]  -- FIXME: make strictly equal?
	elseif d.tag == 'map' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'map'
		  and  T.isa(d.key_type,   b.key_type)    -- {int, string}  isa  {num, string}  -- FIXME: make strictly equal?
		  and  T.isa(d.value_type, b.value_type)  -- {string, int}  isa  {string, num}  -- FIXME: make strictly equal?
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
			return false
		end

		for i = 1, #d.args do
			if not T.isa(d.args[i].type, b.args[i].type) then
				return false
			end
		end

		if b.rets then
			if not T.isa_typelists(d.rets, b.rets) then
				return false
			end
		end

		if (d.vararg==nil) ~= (b.vararg==nil) then
			return false
		end

		if d.vararg and b.vararg then
			if not T.isa(d.vararg, b.vararg) then
				return false
			end
		end

		return true
	elseif d.tag == 'varargs' and b.tag == 'varargs' then
		return T.isa(d.type, b.type)
	else
		--error('isa failed: derived: ' .. U.pretty(d) .. ', base: ' .. U.pretty(b))
		error('isa failed: derived: ' .. T.name(d) .. ', base: ' .. T.name(b))
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
	return T.could_be(a, T.Nil)
	--[[
	if a.tag == 'variant' then
		if #a.variants < 2 then
			-- It has to be able to be either nil or somethign else
			return false
		end

		for _,t in pairs(a.variants) do
			if T.isa(t, T.Nil) or T.is_nilable(a) then
				return true
			end
		end

		return false
	end

	return false
	--]]
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


function T.is_any(a: T.Type)
	local forgiving = true
	a = T.follow_identifiers(a, forgiving)
	return a == T.AnyTypeList
	    or a == T.Any
	    or a.tag == 'variant' and #a.variants == 1 and T.is_any(a.variants[1])
end


-- Can it be used in boolean expression?
function T.is_bool(a: T.Type)
	a = T.follow_identifiers(a)
	return T.is_any(a) or T.isa(a, T.Bool) or T.is_nilable(a)
end


-- Will look through a way for a type to match a given type
function T.find(t: T.Type, target: T.Type)
	--U.printf("T.find(%s, %s)", T.name(t), T.name(target))
	D.assert( T.is_type(t) )
	D.assert( T.is_type(target) )

	t = T.follow_identifiers(t)

	if T.isa(t, target) then
		return t
	elseif T.is_variant(t) then
		for _,v in ipairs(t.variants) do
			--print("Find: searching variant " .. T.name(v))
			if T.find(v, target) then
				return v
			end
		end
	end
	return nil
end


-- is a variant of 'a' a 'b' ?
-- T.could_be(T.Bool, T.False)  == true
-- T.could_be(some_nilable, T.Nil)  == true
-- T.could_be(int or bool, string or bool)  == true
-- T.could_be(int or nil, string or nil)  == false
function T.could_be(a: T.Type, b: T.Type, problem_rope: [string]?)
	if a==b then
		-- Early out:
		return true
	end

	D.assert( T.is_type(a) )
	D.assert( T.is_type(b) )

	a = T.follow_identifiers(a)
	b = T.follow_identifiers(b)

	if T.is_variant(a) then
		for _,v in ipairs(a.variants) do
			if T.could_be(v, b, problem_rope) then
				return true
			end
		end
		return false
	elseif T.is_variant(b) then
		for _,v in ipairs(b.variants) do
			if T.could_be(a, v, problem_rope) then
				return true
			end
		end
		return false
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

function T.could_be_tl(al, bl, problem_rope: [string]?) -> bool
	assert(al and bl)

	if al == T.AnyTypeList or bl == T.AnyTypeList then
		return true
	end

	if not T.is_type_list(al) and not T.is_type_list(bl) then
		return T.could_be(al, bl, problem_rope)
	end

	assert(al and bl)
	al = T.as_type_list(al)
	bl = T.as_type_list(bl)

	if #al ~= #bl then
		if problem_rope then
			table.insert(problem_rope, "typelists of unequal length")
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


function T.could_be_false(a: T.Type)
	a = T.follow_identifiers(a)
	return T.is_any(a) or T.could_be(a, T.Nil) or T.could_be(a, T.False)
end


function T.could_be_true(a: T.Type)
	a = T.follow_identifiers(a)
	if T.is_any(a) then
		return true
	elseif a == T.Nil or a == T.False then
		return false
	elseif T.is_variant(a) then
		--[[
		and #a.variants == 2
		and T.could_be(a, T.Nil) 
		and T.could_be(a, T.False) then
		return false   --  false or nil
		--]]
		for _,v in ipairs(a.variants) do
			if T.could_be_true(v) then
				return true
			end
		end
		return false   --  e.g. false or nil
	else
		return true
	end
end


-- is 'a' a boolean expresson that could be evaluates as either true and false?
-- If not, we are doing somethinglike    if always_true then ...
-- Which is almost certainly wrong
function T.is_useful_boolean(a: T.Type)
	a = T.follow_identifiers(a)

	--[[
	if a.tag == 'variant' then
		for _,v in pairs(a.variants) do
			if T.follow_identifiers(v) == T.Any then
				return true
			end
		end
	end
	--]]

	return T.could_be_false(a) and T.could_be_true(a)
end



function T.as_type_list(t: T.Type or [T.Type])
	if T.is_type_list( t ) then
		return t
	else
		return { t }
	end
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

function T.format_type(root: T.Type, verbose: bool?)
	if verbose == nil then verbose = false end

	var written_objs = {} : {T.Object}
	local output_types, output_obj

	local function output(typ: T.Type, indent: string) -> string
		local next_indent = indent .. U.INDENTATION

		if typ.tag == 'any' then
			return 'any'

		elseif typ.tag == 'variant' then
			local function output_packaged(typ: T.Type, indent: string)
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

				local str = ''
				for i,t in ipairs(typ.variants) do
					str = str .. output_packaged(t, next_indent)
					if i ~= #typ.variants then
						str = str .. ' or '
					end
				end
				return str
			end

		elseif typ.tag == 'object' then
			--verbose = false -- FIXME 

			var<T.Object> obj = typ

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
					str = str .. arg.name
				end
				if arg.type and not T.is_any(arg.type) then
					if arg.name ~= 'self' then -- Potential recursion (object has function taking object as arg...)
						str = str .. ": " .. output(arg.type, next_indent)
					end
				end
				if i ~= #typ.args or typ.vararg then
					str = str .. ", "
				end
			end
			if typ.vararg then
				str = str .. "..."
				if not T.is_any(typ.vararg) then
					str = str .. " : " .. output(typ.vararg, next_indent)
				end
			end
			str = str .. ')'
			if typ.rets then
				str = str .. ' -> ' .. output_types(typ.rets, next_indent)
			else
				--str = str .. ' -> ...'
			end
			return str

		elseif typ.tag == 'int_literal' or typ.tag == 'num_literal' then
			return '' .. typ.value

		elseif typ.tag == 'string_literal' then
			return string.format('%q', typ.value)

		elseif typ.tag == 'identifier' then
			if (verbose or _G.g_spam) and typ.type then
			--if typ.type then
				return string.format('%s (%s)', typ.name, output(typ.type, next_indent))
			else
				return string.format('%s', typ.name)
			end

		else
			return typ.tag
		end
	end


	output_obj = function(obj: T.Object, indent: string) -> string
		local next_indent = indent .. U.INDENTATION

		if not obj.namespace
		   and not obj.metatable
		   and U.table_empty(obj.members)
		then
			return '{ }'
			--return '['..T.table_id(obj)..'] { }' -- great for debugging
		else
			local str = ''
			if obj.namespace then
				str = str .. next_indent .. '-- Types:\n'

				var<T.Typelist> type_list = {}
				for k,v in pairs(obj.namespace) do
					table.insert(type_list, {name = k, type = v})
				end
				table.sort(type_list, function(a,b) return a.name < b.name end)
				--table.sort(type_list, function(a,b) return a.type.where < b.type.where end)
				for _,m in ipairs(type_list) do
					str = str .. next_indent .. 'typedef ' .. m.name .. " = " .. output(m.type, next_indent) .. ";\n"
				end
			end

			if not U.table_empty(obj.members) then
				if str ~= '' then
					str = str .. '\n' .. next_indent .. '-- Members:\n'
				end

				var<[{name:string, type:T.Type}]> mem_list = {}
				var widest_name = 0
				for k,v in pairs(obj.members) do
					table.insert(mem_list, {name = k, type = v})
					widest_name = math.max(widest_name, #k)
				end
				table.sort(mem_list, function(a,b) return a.name < b.name end)

				var type_indent = next_indent
				for i = 1,widest_name+2 do
					type_indent = type_indent..' '
				end

				for _,m in ipairs(mem_list) do
					if m.name == 'Bool' then
						D.break_()
					end

					str = str .. next_indent .. m.name .. ": "

					-- Align:
					for i = #m.name, widest_name - 1 do
						str = str .. ' '
					end

					str = str .. output(m.type, type_indent) .. ";\n"
				end
			end

			if obj.metatable then
				if str ~= '' then
					--str = str .. '\n' .. next_indent .. '-- metatable:\n'
					str = str .. '\n'
				end

				str = str .. next_indent .. "!! metatable:     " .. output(obj.metatable, next_indent) .. '\n'
			end

			if obj.class_type then
				if str ~= '' then str = str .. '\n' end
				str = str .. next_indent .. "!! class_type:    " .. output(obj.class_type, next_indent) .. '\n'
			end

			if obj.instance_type then
				if str ~= '' then str = str .. '\n' end
				str = str .. next_indent .. "!! instance_type: " .. output(obj.instance_type, next_indent) .. '\n'
			end

			local full = '{\n' .. str .. indent ..'}'

			full = '<'..T.table_id(obj)..'>'..full -- great for debugging

			if obj.class_type then
				return '<instance>' .. full
			elseif obj.instance_type then
				return '<class>' .. full
			else
				return full
			end
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
				str = str .. output(t, indent)
				if i ~= #typelist then
					str = str .. ', '
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
			str = str .. T.name(t, verbose)
			if i ~= #typ then
				str = str .. ', '
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


function T.name_verbose(typ: T.Type or [T.Type] or nil)
	return T.name(typ, true)
end


function T.is_variant(v)
	v = T.follow_identifiers(v)
	return v and type(v) == 'table' and v.tag == 'variant'
end


function T.extend_variant_one(v: T.Variant, e: T.Type) -> T.Variant
	--if #v.variants > 15 then
	--	U.printf("WARNING: extremely long variant: %s", T.name(v))
	--end

	if e == T.Any then
		v.variants = { T.Any }	
	else
		if not T.isa(e, v) then
			if T.is_variant(e) then
				e = T.follow_identifiers(e)
				for _,et in ipairs(e.variants) do
					v = T.extend_variant_one(v, et)
				end
			else
				table.insert(v.variants, e)
			end
		end
	end
	return v
end


function T.extend_variant(v, ...)
	assert( T.is_variant(v) )

	for _,e in ipairs{...} do
		v = T.extend_variant_one(v, e)
	end

	return v
end


-- Remove a type from a variant
function T.variant_remove(t: T.Type, remove_this_type: T.Type)
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
			i = i + 1
		elseif T.isa(v.variants[i], remove_this_type) then
			table.remove( v.variants, i )
		else
			i = i + 1
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


function T.clone_variant(v) -> T.Variant
	v = T.follow_identifiers(v)
	assert( T.is_variant(v) )
	return T.make_variant( unpack(v.variants) )
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
		local v = T.clone_variant( a )
		for _,e in ipairs(b.variants) do
			v = T.extend_variant_one( v, e )
		end
		return v
	elseif a_is_variant then
		local v = T.clone_variant( a )
		v = T.extend_variant_one(v, b)
		return v
	elseif b_is_variant then
		local v = T.clone_variant( b )
		v = T.extend_variant_one(v, a)
		return v
	else
		return T.make_variant(a, b)
	end
end


-- used for expressions like "a + b"
-- works for tables, or numerics, i.e.   num+int == num
function T.combine(a: T.Type, b: T.Type)
	if T.isa(a, b) then return b end
	if T.isa(b, a) then return a end

	if a.tag == 'int_literal' and b.tag == 'int_literal' then
		return T.Int
	end

	local function is_num_literal(t)
		return t.tag == 'int_literal' or t.tag == 'num_literal'
	end

	if is_num_literal(a) and is_num_literal(b) then
		return T.Num
	end

	-- A true super-type
	U.printf_err('TODO: T.combine(%s, %s)', T.name(a), T.name(b))
	return T.Any
end


-- TODO: make arguments : T.Typelist?
function T.combine_type_lists(a, b, forgiving: bool?) -> T.Typelist?
	--forgiving = forgiving or true
	if forgiving == nil then
		forgiving = true
	end

	if _G.g_spam then
		U.printf('combine_type_lists(%s, %s)', T.name(a), T.name(b))
	end

	if a == nil then return b end
	if b == nil then return a end

	if a == T.AnyTypeList then return T.AnyTypeList end
	if b == T.AnyTypeList then return T.AnyTypeList end

	D.assert(T.is_type_list(a))
	D.assert(T.is_type_list(b))

	if forgiving then
		if #a < #b  then
			a = U.shallow_clone(a)
			while #a < #b do
				table.insert(a, T.Nil)
			end
		end

		if #b < #a  then
			b = U.shallow_clone(b)
			while #b < #a do
				table.insert(b, T.Nil)
			end
		end
	end

	if #a ~= #b then
		local msg = string.format("Return statement with different number of values than the previous: %s vs %s", T.name(a), T.name(b))
		error( msg )
	else
		var<T.Typelist> ret = {}
		for i = 1, #a do
			ret[i] = T.variant( a[i], b[i] )
			if _G.g_spam then
				U.printf('variant(%s, %s) = %s', T.name(a[i]), T.name(b[i]), T.name(ret[i]))
			end
		end
		return ret
	end
end


-- For assigning type to a variable
function T.broaden(t: T.Type?) -> T.Type?
	if not t then return t end

	if t.tag == 'int_literal' then
		return T.Int
	elseif t.tag == 'num_literal' then
		return T.Num
	elseif t.tag == 'string_literal' then
		return T.String
	elseif t == T.True or t == T.False then
		return T.Bool
	elseif t.tag == 'list' then
		return { tag = 'list', type = T.broaden(t.type) }
	elseif t.tag == 'map' then
		return {
			tag        = 'map',
			key_type   = T.broaden(t.key_type),
			value_type = T.broaden(t.value_type),
		}
	elseif t.tag == 'variant' then
		-- false?   ->  bool?
		var<T.Variant> ret = { tag='variant', variants={} }
		for ix,v in ipairs(t.variants) do
			ret.variants[ix] = T.broaden(v)
		end
		return ret
	else
		return t
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
			end

			--U.printf("Simplified '%s' to '%s'", T.name(t), T.name(v))

			if #v.variants == 1 then
				return v.variants[1]
			else
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

return T
