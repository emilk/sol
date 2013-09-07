--[[ DO NOT MODIFY - COMPILED FROM sol/type.sol --]] --[[
A type can either be a particular value (number or string) or one of the following.
--]]

local U = require 'util'
local D = require 'sol_debug'

--[[
FIXME: recursive dependency
local S    = require 'scope'
typedef Scope    = S.Scope
typedef Variable = S.Variable
--]]
local S = {}
local T = {}




T





















.on_error = function(fmt, ...)
	local msg = string.format(fmt, ...)
	U.printf_err( "%s", msg )
	error(msg, 2)
end


-- Any: implicit convert to and from anything.
-- Used for interaction with Lua code.
T













































































.Any  = { tag = 'any'  }  -- Single unknown value
T.AnyTypeList = {}   -- Unkown number of unknown values

T.Nil      = { tag = 'nil'    }
T.True     = { tag = 'true'   }
T.False    = { tag = 'false'  }
T.String   = { tag = 'string' }
T.Num      = { tag = 'num'    }
T.Int      = { tag = 'int'    }
T.Empty    = { tag = 'variant', variants = {} }
--T.Void     = T.Empty
T.Void     = {} -- empty type-list
T.Nilable  = T.Any  -- TODO

T.Uint = T.Int               -- TODO
T.Bool = { tag = 'variant',  variants = { T.False, T.True } }

--[[
T.EmptyTable = {
	tag      = 'object',
	members = {}
}
--]]
function T.is_empty_table(t)
	return t.tag == 'object' and next(t.members) == nil
end

-- General table - could be an object, list or map:
T.Table = { tag = 'table' }

-- Supertype of all objects:
T.Object = { tag = 'object', members = {} }

-- Supertype of all lists:
T.List = { tag = 'list', type = T.Any }

-- Supertype of all maps:
T.Map = { tag = 'map', key_type = T.Any, value_type = T.Any }


function T.is_type(x)
	return type(x) == 'table' and type(x.tag) == 'string'
end


function T.follow_identifiers(t, forgiving)
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
					T.on_error("%s: type '%s' not found in namespace '%s'", t.first_usage, t.name, var_.name)
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
		U.write_protect_table(t) -- TODO
	end

	return T.follow_identifiers(t.type)
end


-- Helper:
function T.is_integral(str)
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


function T.from_num_literal(str)
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


local function unquote(str)
	-- FIXME: unquote is unsafe
	return loadstring("return "..str)()
end


function T.from_string_literal(str)
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


function T.is_obj_obj(d, b, problem_rope)
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
					string.format("member '%s' of wrong type (got %s, expected %s)",
						id, d_type, b_type))
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
local isa_memo = {}

function T.isa(d, b, problem_rope)
	local res = isa_memo[d] and isa_memo[d][b]
	if res==nil then
		local rope = {}
		res = T.isa_raw(d, b, rope)
		if not res then
			res = table.concat(rope, '\n')
		end
		isa_memo[d] = isa_memo[d] or {}
		isa_memo[d][b] = res
	end
	if res == true then
		return true
	else
		assert(type(res) == 'string')
		if problem_rope then
			problem_rope[#problem_rope +1 ] = res
		end
		return false
	end	
end


function T.isa_raw(d, b, problem_rope)
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


	if b.tag == 'table' then
		return d.tag == 'table'
		    or d.tag == 'list'
		    or d.tag == 'map'
		    or d.tag == 'object'
	end


	if d.tag == 'int_literal' then
		if (b.tag == 'int_literal' or b.tag == 'num_literal') and b.value == d.value then
			-- Same value
			return true
		end

		return b.tag == 'num' or b.tag == 'int'
	end

	if d.tag == 'num_literal' then
		if b.tag == 'num_literal' and b.value == d.value then
			-- Same value
			return true
		end

		return b.tag == 'num'
	end

	if d.tag == 'string_literal' then
		if b.tag == 'string_literal' and b.value == d.value then
			-- Same value
			return true
		end

		return b.tag == 'string'
	end

	if T.is_empty_table(d) then
		return b.tag == 'list' or b.tag == 'map'
	end

	if d.tag == 'false' then
		return b.tag == 'false'
	elseif d.tag == 'true' then
		return b.tag == 'true'
	elseif d.tag == 'nil' then
		return b.tag == 'nil'
	elseif d.tag == 'string' then
		return b.tag == 'string'
	elseif d.tag == 'num' then
		return b.tag == 'num'
	elseif d.tag == 'int' then
		return b.tag == 'num'
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
function T.isa_typelists(d, b, problem_rope)
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


function T.is_nilable(a)
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


function T.is_any(a)
	local forgiving = true
	a = T.follow_identifiers(a, forgiving)
	return a == T.AnyTypeList
	    or a == T.Any
	    or a.tag == 'variant' and #a.variants == 1 and T.is_any(a.variants[1])
end


-- Can it be used in boolean expression?
function T.is_bool(a)
	a = T.follow_identifiers(a)
	return T.is_any(a) or T.isa(a, T.Bool) or T.is_nilable(a)
end


-- Will look through a way for a type to match a given type
function T.find(t, target)
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
function T.could_be(a, b, problem_rope)
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

function T.could_be_tl(al, bl, problem_rope)
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


function T.could_be_false(a)
	a = T.follow_identifiers(a)
	return T.is_any(a) or T.could_be(a, T.Nil) or T.could_be(a, T.False)
end


function T.could_be_true(a)
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
function T.is_useful_boolean(a)
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



function T.as_type_list(t)
	if T.is_type_list( t ) then
		return t
	else
		return { t }
	end
end


-- indent      - indent on any _subsequent_ line
function T.name(typ, indent, verbose)
	indent     = indent or ""
	if verbose == nil then verbose = false end

	local next_indent = indent .. '   '

	if typ == nil then
		return 'NIL'
	end
	
	if typ == T.AnyTypeList then
		return "..."

	elseif T.is_type_list(typ) then
		if #typ == 0 then
			return "void [EMPTY TYPE-LIST]"
		else
			local str=''
			for i,t in ipairs(typ) do
				str = str .. T.name(t, next_indent, verbose)
				if i ~= #typ then
					str = str .. ', '
				end
			end
			return str
		end
	end

	D.assert( T.is_type(typ) )

	if typ.tag == 'any' then
		return 'any'

	elseif typ.tag == 'variant' then
		if #typ.variants == 0 then
			return "void"
		else
			if #typ.variants == 2
				and typ.variants[2] == T.Nil 
				and typ.variants[1].tag ~= 'variant'
			then
				return T.name(typ.variants[1], next_indent, verbose) .. '?'
			end

			local str = ''
			for i,t in ipairs(typ.variants) do
				str = str .. T.name(t, next_indent, verbose)
				if i ~= #typ.variants then
					--str = str .. '|'
					str = str .. ' or '
				end
			end
			return str
		end

	elseif typ.tag == 'object' then
		local obj = typ

		if not obj.namespace
		   and not obj.metatable
		   and U.table_empty(obj.members)
		then
			return '{ }'
		else
			local str = ''
			if obj.namespace then
				str = str .. next_indent .. '-- Types:\n'

				local type_list = {}
				for k,v in pairs(obj.namespace) do
					table.insert(type_list, {name = k, type = v})
				end
				table.sort(type_list, function(a,b) return a.name < b.name end)
				--table.sort(type_list, function(a,b) return a.type.where < b.type.where end)
				for _,m in ipairs(type_list) do
					str = str .. next_indent .. 'typedef ' .. m.name .. " = " .. T.name(m.type, next_indent, verbose) .. ",\n"
				end
			end

			if not U.table_empty(obj.members) then
				if str ~= '' then
					str = str .. '\n' .. next_indent .. '-- Members:\n'
				end

				local mem_list = {}
				local widest_name = 0
				for k,v in pairs(obj.members) do
					table.insert(mem_list, {name = k, type = v})
					widest_name = math.max(widest_name, #k)
				end
				table.sort(mem_list, function(a,b) return a.name < b.name end)
				for _,m in ipairs(mem_list) do
					str = str .. next_indent .. m.name .. ": "

					-- Align:
					for i = #m.name, widest_name - 1 do
						str = str .. ' '
					end

					str = str .. T.name(m.type, next_indent, verbose) .. ",\n"
				end
			end

			if obj.metatable then
				if str ~= '' then
					--str = str .. '\n' .. next_indent .. '-- metatable:\n'
					str = str .. '\n'
				end

				str = str .. next_indent .. "!! metatable: " .. T.name(obj.metatable, next_indent, verbose) .. '\n'
			end

			return '{\n' .. str .. indent ..'}'
		end

	elseif typ.tag == 'list' then
		return '[' .. T.name(typ.type, next_indent, verbose) .. ']'

	elseif typ.tag == 'map' then
		return '{' .. T.name(typ.key_type, next_indent, verbose) .. ' => ' .. T.name(typ.value_type, next_indent, verbose) .. '}'

	elseif typ.tag == 'function' then
		local str = 'function('
		for i,arg in ipairs(typ.args) do
			if arg.name then
				str = str .. arg.name
			end
			if arg.type and not T.is_any(arg.type) then
				if arg.name ~= 'self' then -- Potential recursion (object has function taking object as arg...)
					str = str .. ": " .. T.name(arg.type, next_indent, verbose)
				end
			end
			if i ~= #typ.args or typ.vararg then
				str = str .. ", "
			end
		end
		if typ.vararg then
			str = str .. "..."
			if not T.is_any(typ.vararg) then
				str = str .. " : " .. T.name(typ.vararg, next_indent, verbose)
			end
		end
		str = str .. ')'
		if typ.rets then
			str = str .. ' -> ' .. T.name(typ.rets, next_indent, verbose)
		end
		return str

	elseif typ.tag == 'int_literal' or typ.tag == 'num_literal' then
		return '' .. typ.value

	elseif typ.tag == 'string_literal' then
		return string.format('%q', typ.value)

	elseif typ.tag == 'identifier' then
		if verbose and typ.type then
			return string.format('%s (%s)', typ.name, T.name(typ.type, next_indent, verbose))
		else
			return string.format('%s', typ.name)
		end

	--elseif typ.tag then
	elseif true then
		return typ.tag

	else
		return string.format("[UNKNOWN TYPE: %q]", U.pretty(typ))
	end
end


function T.name_verbose(typ)
	return T.name(typ, '', true)
end


function T.is_variant(v)
	v = T.follow_identifiers(v)
	return v and type(v) == 'table' and v.tag == 'variant'
end


function T.extend_variant_one(v, e)
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
function T.variant_remove(t, remove_this_type)
	t = T.follow_identifiers(t)

	assert(not T.is_any(remove_this_type))

	if T.is_any(t) then
		return t
	end

	local v = T.make_variant(t)
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


function T.make_variant(...)
	local v = {
		tag = "variant",
		variants = { }
	}
	v = T.extend_variant(v, ...)
	return v
end


function T.clone_variant(v)
	v = T.follow_identifiers(v)
	assert( T.is_variant(v) )
	return T.make_variant( unpack(v.variants) )
end


-- Return a or b
function T.variant(a, b)
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
function T.combine(a, b)
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
function T.combine_type_lists(a, b, forgiving)
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
		local ret = {}
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
function T.broaden(t)
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
	else
		return t
	end
end


function T.simplify(t)
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
function T.all_variants(typ)
	local function all_vars(t)
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


return T
