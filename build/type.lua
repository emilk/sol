--[[ DO NOT MODIFY - COMPILED FROM sol/type.sol --]] --[[
A type can either be a particular value (number or string) or one of the following.
--]]

local U = require 'util' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 

local const = U.const --[[SOL OUTPUT--]] 

--[[
FIXME: recursive dependency
local S    = require 'scope'
typedef Scope    = S.Scope
typedef Variable = S.Variable
--]]
local S = {} --[[SOL OUTPUT--]] 
local T = {} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 




T





















.on_error = function(fmt, ...)
	local msg = string.format(fmt, ...) --[[SOL OUTPUT--]] 
	U.printf_err( "%s", msg ) --[[SOL OUTPUT--]] 
	error(msg, 2) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 

------------------------------------------------------------------
-- Prototypes for commong stuff:


-- Any: implicit convert to and from anything.
-- Used for interaction with Lua code.
T













































































.Any  = { tag = 'any'  } --[[SOL OUTPUT--]]   -- Single unknown value
T.AnyTypeList = {} --[[SOL OUTPUT--]]    -- Unkown number of unknown values

T.Nil      = const{ tag = 'nil'    } --[[SOL OUTPUT--]] 
T.True     = const{ tag = 'true'   } --[[SOL OUTPUT--]] 
T.False    = const{ tag = 'false'  } --[[SOL OUTPUT--]] 
T.String   = const{ tag = 'string' } --[[SOL OUTPUT--]] 
T.Num      = const{ tag = 'num'    } --[[SOL OUTPUT--]] 
T.Int      = const{ tag = 'int'    } --[[SOL OUTPUT--]] 
T.Empty    = const{ tag = 'variant', variants = {} } --[[SOL OUTPUT--]] 

--T.Void     = T.Empty
T.Void     = {} --[[SOL OUTPUT--]]  -- empty type-list
T.Nilable  = T.Any --[[SOL OUTPUT--]]   -- TODO

T.Uint = T.Int --[[SOL OUTPUT--]]                -- TODO
T.Bool = const{ tag = 'variant',  variants = { T.False, T.True } } --[[SOL OUTPUT--]] 


-- General table - could be an object, list or map:
T.Table = const{ tag = 'table' } --[[SOL OUTPUT--]] 

-- Supertype of all objects:
T.Object = const{ tag = 'object', members = {} } --[[SOL OUTPUT--]] 

-- Supertype of all lists:
T.List = const{ tag = 'list', type = T.Any } --[[SOL OUTPUT--]] 

-- Supertype of all maps:
T.Map = const{ tag = 'map', key_type = T.Any, value_type = T.Any } --[[SOL OUTPUT--]] 

------------------------------------------------------------------

function T.is_type(x)
	return type(x) == 'table' and type(x.tag) == 'string' --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

T._empty_table = { tag = 'table' } --[[SOL OUTPUT--]] 

-- TODO: disallow=
function T.create_empty_table()
	--return { tag='object', members={} }
	return T.Table --[[SOL OUTPUT--]] 
	--return T._empty_table
end --[[SOL OUTPUT--]] 

-- TODO: remove
function T.is_empty_table(t)
	--return t.tag == 'object' and next(t.members) == nil
	--return t.tag == 'table'
	return T.follow_identifiers(t).tag == 'table' --[[SOL OUTPUT--]] 
	--return t == T._empty_table
end --[[SOL OUTPUT--]] 


function T.follow_identifiers(t, forgiving)
	if t.tag ~= 'identifier' then
		-- Early out
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if forgiving == nil then forgiving = false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if _G.g_local_parse then
		forgiving = true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	D.assert(T.is_type(t)) --[[SOL OUTPUT--]] 

	if not t.type then
		--[[
		if t.type == T.Any then
			-- Maybe a local parse
			forgiving = true
		end
		--]]

		if t.var_name then
			local var_ = t.scope:get_var( t.var_name ) --[[SOL OUTPUT--]]   -- A namespace is always a variable
			if not var_ then
				T.on_error("Failed to find namespace variable %q", t.var_name) --[[SOL OUTPUT--]] 
				t.type = T.Any --[[SOL OUTPUT--]] 
			elseif not var_.namespace then
				if forgiving then
					return T.Any --[[SOL OUTPUT--]] 
				else
					T.on_error("%s: Variable '%s' is not a namespace (looking up '%s')", t.first_usage, var_.name, t.name) --[[SOL OUTPUT--]] 
					t.type = T.Any --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				t.type = var_.namespace[t.name] --[[SOL OUTPUT--]] 
				if not t.type then
					T.on_error("%s: type '%s' not found in namespace '%s'", t.first_usage, t.name, var_.name) --[[SOL OUTPUT--]] 
					t.type = T.Any --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			t.type = t.scope:get_type( t.name ) --[[SOL OUTPUT--]] 
			if not t.type then
				T.on_error("%s: typename '%s' not found", t.first_usage, t.name) --[[SOL OUTPUT--]] 
				t.type = T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		-- No more need to write to it:
		U.make_const(t) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return T.follow_identifiers(t.type) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Helper:
function T.is_integral(str)
	if str:match('0x%w+') then
		-- Hex is intregral
		return true --[[SOL OUTPUT--]] 
	elseif str:match('%D') then -- (%d == digit, %D == non-digit)
		-- Non-digits == real
		return false --[[SOL OUTPUT--]] 
	else
		-- All digits == integral
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.from_num_literal(str)
	local n = tonumber(str) --[[SOL OUTPUT--]] 

	if n then
		if T.is_integral(str) then
			return {
				tag   = 'int_literal',
				value = n
			} --[[SOL OUTPUT--]] 
		else
			return {
				tag   = 'num_literal',
				value = n
			} --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	else
		return nil --[[SOL OUTPUT--]]  -- Fail
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function unquote(str)
	-- FIXME: unquote is unsafe
	return loadstring("return "..str)() --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.from_string_literal(str)
	return {
		tag   = 'string_literal',
		value = unquote( str)   -- No quotes
	} --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.is_type_list(list)
	--return U.is_array(list)
	if not U.is_array(list) then return false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	for _,v in pairs(list) do
		if not T.is_type(v) then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.is_obj_obj(d, b, problem_rope)
	assert(d.tag == 'object') --[[SOL OUTPUT--]] 
	assert(b.tag == 'object') --[[SOL OUTPUT--]] 

	for id, b_type in pairs(b.members) do
		local d_type = d.members[id] --[[SOL OUTPUT--]] 
		if not d_type then
			if not T.is_nilable(b_type) then
				if problem_rope then
					table.insert(problem_rope, string.format("member '%s' missing", id)) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		elseif not T.isa(d_type, b_type, problem_rope) then
			if problem_rope then
				table.insert(problem_rope,
					string.format("member '%s' of wrong type (got %s, expected %s)",
					              id, T.name(d_type), T.name(b_type))) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- i.e., is type 'd' a subset of type 'b' ?
--[[
True:
T.isa(T.Int, T.Num)
T.isa(T.False, T.Bool)
--]]

-- Memoization:
local isa_memo = {} --[[SOL OUTPUT--]] 

function T.isa(d, b, problem_rope)
	local res = isa_memo[d] and isa_memo[d][b] --[[SOL OUTPUT--]] 
	if res==nil then
		local rope = {} --[[SOL OUTPUT--]] 
		res = T.isa_raw(d, b, rope) --[[SOL OUTPUT--]] 
		if not res then
			res = table.concat(rope, '\n') --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		isa_memo[d] = isa_memo[d] or {} --[[SOL OUTPUT--]] 
		isa_memo[d][b] = res --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	if res == true then
		return true --[[SOL OUTPUT--]] 
	else
		assert(type(res) == 'string') --[[SOL OUTPUT--]] 
		if problem_rope then
			problem_rope[#problem_rope +1 ] = res --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 	
end --[[SOL OUTPUT--]] 


function T.isa_raw(d, b, problem_rope)
	if d == b then
		return true --[[SOL OUTPUT--]]  -- Early out optimization
	end --[[SOL OUTPUT--]] 

	D.assert(T.is_type(d)) --[[SOL OUTPUT--]] 
	D.assert(T.is_type(b)) --[[SOL OUTPUT--]] 
	d = T.follow_identifiers(d) --[[SOL OUTPUT--]] 
	b = T.follow_identifiers(b) --[[SOL OUTPUT--]] 

	--U.printf("isa, b: %s, d: %s", T.name(b), T.name(d))
	if d == b then
		return true --[[SOL OUTPUT--]]  -- Early out optimization
	end --[[SOL OUTPUT--]] 

	if b.tag == 'variant' then
		for _,v in ipairs(b.variants) do
			if T.isa(d, v) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if d.tag == 'variant' then
		local function all_are_b()
			for _,v in ipairs(d.variants) do
				if not T.isa(v, b) then
					return false --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return all_are_b() --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	if b.tag == 'any' or d.tag == 'any' then
		-- 'any' can become anything
		-- Anything can become 'any'
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	if d.tag == 'int_literal' then
		if (b.tag == 'int_literal' or b.tag == 'num_literal') and b.value == d.value then
			-- Same value
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return b.tag == 'num' or b.tag == 'int' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if d.tag == 'num_literal' then
		if b.tag == 'num_literal' and b.value == d.value then
			-- Same value
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return b.tag == 'num' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if d.tag == 'string_literal' then
		if b.tag == 'string_literal' and b.value == d.value then
			-- Same value
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return b.tag == 'string' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	if b.tag == 'table' then
		return d.tag == 'table'
		    or d.tag == 'list'
		    or d.tag == 'map'
		    or d.tag == 'object' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if T.is_empty_table(d) then
		-- TODO: remove
		return b.tag == 'list' or b.tag == 'map' or b.tag == 'table' or
		       (b.tag == 'object' and U.table_empty(b.members) and b.derived == nil and b.metatable == nil) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if d.tag == 'false' then
		return b.tag == 'false' --[[SOL OUTPUT--]] 
	elseif d.tag == 'true' then
		return b.tag == 'true' --[[SOL OUTPUT--]] 
	elseif d.tag == 'nil' then
		return b.tag == 'nil' --[[SOL OUTPUT--]] 
	elseif d.tag == 'string' then
		return b.tag == 'string' --[[SOL OUTPUT--]] 
	elseif d.tag == 'num' then
		return b.tag == 'num' --[[SOL OUTPUT--]] 
	elseif d.tag == 'int' then
		return b.tag == 'num'
		    or b.tag == 'int' --[[SOL OUTPUT--]] 
	elseif d.tag == 'table' then
		return false --[[SOL OUTPUT--]]  -- Already covered
	elseif d.tag == 'list' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'list'
		  and  T.isa(d.type, b.type) --[[SOL OUTPUT--]]  -- [int] isa [num]  -- FIXME: make strictly equal?
	elseif d.tag == 'map' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'map'
		  and  T.isa(d.key_type,   b.key_type)    -- {int, string}  isa  {num, string}  -- FIXME: make strictly equal?
		  and  T.isa(d.value_type, b.value_type) --[[SOL OUTPUT--]]   -- {string, int}  isa  {string, num}  -- FIXME: make strictly equal?
	elseif d.tag == 'object' then
		if b.tag == 'object' then
			return T.is_obj_obj(d, b, problem_rope) --[[SOL OUTPUT--]] 
		else
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	elseif d.tag == 'function' then
		if b.tag ~= 'function' then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		-- TODO: allow different arg count WRT vararg
		if #d.args ~= #b.args then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for i = 1, #d.args do
			if not T.isa(d.args[i].type, b.args[i].type) then
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if b.rets then
			if not T.isa_typelists(d.rets, b.rets) then
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if (d.vararg==nil) ~= (b.vararg==nil) then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if d.vararg and b.vararg then
			if not T.isa(d.vararg, b.vararg) then
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return true --[[SOL OUTPUT--]] 
	elseif d.tag == 'varargs' and b.tag == 'varargs' then
		return T.isa(d.type, b.type) --[[SOL OUTPUT--]] 
	else
		--error('isa failed: derived: ' .. U.pretty(d) .. ', base: ' .. U.pretty(b))
		error('isa failed: derived: ' .. T.name(d) .. ', base: ' .. T.name(b)) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Accepts typelists
function T.isa_typelists(d, b, problem_rope)
	if d==nil and b==nil then return true --[[SOL OUTPUT--]]   end --[[SOL OUTPUT--]] 
	if d==nil or  b==nil then return false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if d == T.AnyTypeList or b == T.AnyTypeList then
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if #d ~= #b then return false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	for i = 1,#d do
		if not T.isa(d[i], b[i], problem_rope) then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.is_nilable(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	if a == T.Any then return true --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if a == T.Nil then return false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	return T.could_be(a, T.Nil) --[[SOL OUTPUT--]] 
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
end --[[SOL OUTPUT--]] 


function T.is_any(a)
	local forgiving = true --[[SOL OUTPUT--]] 
	a = T.follow_identifiers(a, forgiving) --[[SOL OUTPUT--]] 
	return a == T.AnyTypeList
	    or a == T.Any
	    or a.tag == 'variant' and #a.variants == 1 and T.is_any(a.variants[1]) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Can it be used in boolean expression?
function T.is_bool(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	return T.is_any(a) or T.isa(a, T.Bool) or T.is_nilable(a) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Will look through a way for a type to match a given type
function T.find(t, target)
	--U.printf("T.find(%s, %s)", T.name(t), T.name(target))
	D.assert( T.is_type(t) ) --[[SOL OUTPUT--]] 
	D.assert( T.is_type(target) ) --[[SOL OUTPUT--]] 

	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 

	if T.isa(t, target) then
		return t --[[SOL OUTPUT--]] 
	elseif T.is_variant(t) then
		for _,v in ipairs(t.variants) do
			--print("Find: searching variant " .. T.name(v))
			if T.find(v, target) then
				return v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- is a variant of 'a' a 'b' ?
-- T.could_be(T.Bool, T.False)  == true
-- T.could_be(some_nilable, T.Nil)  == true
-- T.could_be(int or bool, string or bool)  == true
-- T.could_be(int or nil, string or nil)  == false
function T.could_be(a, b, problem_rope)
	D.assert( T.is_type(a) ) --[[SOL OUTPUT--]] 
	D.assert( T.is_type(b) ) --[[SOL OUTPUT--]] 

	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	b = T.follow_identifiers(b) --[[SOL OUTPUT--]] 

	if T.is_variant(a) then
		for _,v in ipairs(a.variants) do
			if T.could_be(v, b, problem_rope) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 
	elseif T.is_variant(b) then
		for _,v in ipairs(b.variants) do
			if T.could_be(a, v, problem_rope) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 
	else
		if T.isa(a, b, problem_rope) then
			return true --[[SOL OUTPUT--]] 
		elseif T.isa(b, a, problem_rope) then
			return true --[[SOL OUTPUT--]] 
		else
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.could_be_tl(al, bl, problem_rope)
	assert(al and bl) --[[SOL OUTPUT--]] 

	if al == T.AnyTypeList or bl == T.AnyTypeList then
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if not T.is_type_list(al) and not T.is_type_list(bl) then
		return T.could_be(al, bl, problem_rope) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	assert(al and bl) --[[SOL OUTPUT--]] 
	al = T.as_type_list(al) --[[SOL OUTPUT--]] 
	bl = T.as_type_list(bl) --[[SOL OUTPUT--]] 

	if #al ~= #bl then
		if problem_rope then
			table.insert(problem_rope, "typelists of unequal length") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	for i = 1,#al do
		if not T.could_be(al[i], bl[i], problem_rope) then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.could_be_false(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	return T.is_any(a) or T.could_be(a, T.Nil) or T.could_be(a, T.False) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.could_be_true(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	if T.is_any(a) then
		return true --[[SOL OUTPUT--]] 
	elseif a == T.Nil or a == T.False then
		return false --[[SOL OUTPUT--]] 
	elseif T.is_variant(a) then
		--[[
		and #a.variants == 2
		and T.could_be(a, T.Nil) 
		and T.could_be(a, T.False) then
		return false   --  false or nil
		--]]
		for _,v in ipairs(a.variants) do
			if T.could_be_true(v) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]]    --  e.g. false or nil
	else
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- is 'a' a boolean expresson that could be evaluates as either true and false?
-- If not, we are doing somethinglike    if always_true then ...
-- Which is almost certainly wrong
function T.is_useful_boolean(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 

	--[[
	if a.tag == 'variant' then
		for _,v in pairs(a.variants) do
			if T.follow_identifiers(v) == T.Any then
				return true
			end
		end
	end
	--]]

	return T.could_be_false(a) and T.could_be_true(a) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 



function T.as_type_list(t)
	if T.is_type_list( t ) then
		return t --[[SOL OUTPUT--]] 
	else
		return { t } --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- indent - indent on any _subsequent_ line
function T.name(typ, indent, verbose)
	indent     = indent or "" --[[SOL OUTPUT--]] 
	if verbose == nil then verbose = false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	local next_indent = indent .. '   ' --[[SOL OUTPUT--]] 

	if typ == nil then
		return 'NIL' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	
	if typ == T.AnyTypeList then
		return "..." --[[SOL OUTPUT--]] 

	elseif T.is_type_list(typ) then
		if #typ == 0 then
			return "void [EMPTY TYPE-LIST]" --[[SOL OUTPUT--]] 
		elseif #typ == 1 then
			return T.name(typ[1], indent, verbose) --[[SOL OUTPUT--]] 
		else
			local str='' --[[SOL OUTPUT--]] 
			for i,t in ipairs(typ) do
				str = str .. T.name(t, next_indent, verbose) --[[SOL OUTPUT--]] 
				if i ~= #typ then
					str = str .. ', ' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return str --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	D.assert( T.is_type(typ) ) --[[SOL OUTPUT--]] 

	if typ.tag == 'any' then
		return 'any' --[[SOL OUTPUT--]] 

	elseif typ.tag == 'variant' then
		if #typ.variants == 0 then
			return "void" --[[SOL OUTPUT--]] 
		elseif #typ.variants == 1 then
			return T.name(typ.variants[1], indent, verbose) --[[SOL OUTPUT--]] 
		else
			if #typ.variants == 2
				and typ.variants[2] == T.Nil 
				and typ.variants[1].tag ~= 'variant'
			then
				return T.name(typ.variants[1], next_indent, verbose) .. '?' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local str = '' --[[SOL OUTPUT--]] 
			for i,t in ipairs(typ.variants) do
				str = str .. T.name(t, next_indent, verbose) --[[SOL OUTPUT--]] 
				if i ~= #typ.variants then
					--str = str .. '|'
					str = str .. ' or ' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return str --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

	elseif typ.tag == 'object' then
		verbose = false --[[SOL OUTPUT--]]  -- FIXME 

		local obj = typ --[[SOL OUTPUT--]] 

		if not obj.namespace
		   and not obj.metatable
		   and U.table_empty(obj.members)
		then
			return '{ }' --[[SOL OUTPUT--]] 
		else
			local str = '' --[[SOL OUTPUT--]] 
			if obj.namespace then
				str = str .. next_indent .. '-- Types:\n' --[[SOL OUTPUT--]] 

				local type_list = {} --[[SOL OUTPUT--]] 
				for k,v in pairs(obj.namespace) do
					table.insert(type_list, {name = k, type = v}) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				table.sort(type_list, function(a,b) return a.name < b.name --[[SOL OUTPUT--]]  end) --[[SOL OUTPUT--]] 
				--table.sort(type_list, function(a,b) return a.type.where < b.type.where end)
				for _,m in ipairs(type_list) do
					str = str .. next_indent .. 'typedef ' .. m.name .. " = " .. T.name(m.type, next_indent, verbose) .. ",\n" --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if not U.table_empty(obj.members) then
				if str ~= '' then
					str = str .. '\n' .. next_indent .. '-- Members:\n' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local mem_list = {} --[[SOL OUTPUT--]] 
				local widest_name = 0 --[[SOL OUTPUT--]] 
				for k,v in pairs(obj.members) do
					table.insert(mem_list, {name = k, type = v}) --[[SOL OUTPUT--]] 
					widest_name = math.max(widest_name, #k) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				table.sort(mem_list, function(a,b) return a.name < b.name --[[SOL OUTPUT--]]  end) --[[SOL OUTPUT--]] 
				for _,m in ipairs(mem_list) do
					str = str .. next_indent .. m.name .. ": " --[[SOL OUTPUT--]] 

					-- Align:
					for i = #m.name, widest_name - 1 do
						str = str .. ' ' --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					str = str .. T.name(m.type, next_indent, verbose) .. ",\n" --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if obj.metatable then
				if str ~= '' then
					--str = str .. '\n' .. next_indent .. '-- metatable:\n'
					str = str .. '\n' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				str = str .. next_indent .. "!! metatable:     " .. T.name(obj.metatable, next_indent, verbose) .. '\n' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if obj.class_type then
				if str ~= '' then str = str .. '\n' --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				str = str .. next_indent .. "!! class_type:    " .. T.name(obj.class_type, next_indent, verbose) .. '\n' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if obj.instance_type then
				if str ~= '' then str = str .. '\n' --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				str = str .. next_indent .. "!! instance_type: " .. T.name(obj.instance_type, next_indent, verbose) .. '\n' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local full = '{\n' .. str .. indent ..'}' --[[SOL OUTPUT--]] 

			if obj.class_type then
				return '[instance] ' .. full --[[SOL OUTPUT--]] 
			elseif obj.instance_type then
				return '[class] ' .. full --[[SOL OUTPUT--]] 
			else
				return full --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

	elseif typ.tag == 'list' then
		return '[' .. T.name(typ.type, next_indent, verbose) .. ']' --[[SOL OUTPUT--]] 

	elseif typ.tag == 'map' then
		if typ.value_type == T.True then
			-- A set
			return '{' .. T.name(typ.key_type, next_indent, verbose) .. '}' --[[SOL OUTPUT--]] 
		else
			-- A map
			return '{' .. T.name(typ.key_type, next_indent, verbose) .. ' => ' .. T.name(typ.value_type, next_indent, verbose) .. '}' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

	elseif typ.tag == 'function' then
		local str = 'function(' --[[SOL OUTPUT--]] 
		for i,arg in ipairs(typ.args) do
			if arg.name then
				str = str .. arg.name --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			if arg.type and not T.is_any(arg.type) then
				if arg.name ~= 'self' then -- Potential recursion (object has function taking object as arg...)
					str = str .. ": " .. T.name(arg.type, next_indent, verbose) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			if i ~= #typ.args or typ.vararg then
				str = str .. ", " --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		if typ.vararg then
			str = str .. "..." --[[SOL OUTPUT--]] 
			if not T.is_any(typ.vararg) then
				str = str .. " : " .. T.name(typ.vararg, next_indent, verbose) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		str = str .. ')' --[[SOL OUTPUT--]] 
		if typ.rets then
			str = str .. ' -> ' .. T.name(typ.rets, next_indent, verbose) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return str --[[SOL OUTPUT--]] 

	elseif typ.tag == 'int_literal' or typ.tag == 'num_literal' then
		return '' .. typ.value --[[SOL OUTPUT--]] 

	elseif typ.tag == 'string_literal' then
		return string.format('%q', typ.value) --[[SOL OUTPUT--]] 

	elseif typ.tag == 'identifier' then
		if verbose and typ.type then
			return string.format('%s (%s)', typ.name, T.name(typ.type, next_indent, verbose)) --[[SOL OUTPUT--]] 
		else
			return string.format('%s', typ.name) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

	else
		return typ.tag --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.name_verbose(typ)
	return T.name(typ, '', true) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.is_variant(v)
	v = T.follow_identifiers(v) --[[SOL OUTPUT--]] 
	return v and type(v) == 'table' and v.tag == 'variant' --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.extend_variant_one(v, e)
	--if #v.variants > 15 then
	--	U.printf("WARNING: extremely long variant: %s", T.name(v))
	--end

	if e == T.Any then
		v.variants = { T.Any } --[[SOL OUTPUT--]] 	
	else
		if not T.isa(e, v) then
			if T.is_variant(e) then
				e = T.follow_identifiers(e) --[[SOL OUTPUT--]] 
				for _,et in ipairs(e.variants) do
					v = T.extend_variant_one(v, et) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				table.insert(v.variants, e) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.extend_variant(v, ...)
	assert( T.is_variant(v) ) --[[SOL OUTPUT--]] 

	for _,e in ipairs{...} do
		v = T.extend_variant_one(v, e) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Remove a type from a variant
function T.variant_remove(t, remove_this_type)
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 

	assert(not T.is_any(remove_this_type)) --[[SOL OUTPUT--]] 

	if T.is_any(t) then
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local v = T.make_variant(t) --[[SOL OUTPUT--]] 
	assert(v ~= t) --[[SOL OUTPUT--]] 

	local i = 1 --[[SOL OUTPUT--]] 
	while i <= #v.variants do
		if T.is_variant(v.variants[i]) then
			v.variants[i] = T.variant_remove(v.variants[i], remove_this_type) --[[SOL OUTPUT--]] 
			i = i + 1 --[[SOL OUTPUT--]] 
		elseif T.isa(v.variants[i], remove_this_type) then
			table.remove( v.variants, i ) --[[SOL OUTPUT--]] 
		else
			i = i + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.make_variant(...)
	local v = {
		tag = "variant",
		variants = { }
	} --[[SOL OUTPUT--]] 
	v = T.extend_variant(v, ...) --[[SOL OUTPUT--]] 
	return v --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.clone_variant(v)
	v = T.follow_identifiers(v) --[[SOL OUTPUT--]] 
	assert( T.is_variant(v) ) --[[SOL OUTPUT--]] 
	return T.make_variant( unpack(v.variants) ) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Return a or b
function T.variant(a, b)
	if a == b   then return a --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if a == nil then return b --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b == nil then return a --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]]  -- FIXME
	b = T.follow_identifiers(b) --[[SOL OUTPUT--]]  -- FIXME
	if a == T.Any then return T.Any --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b == T.Any then return T.Any --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if T.isa(a, b) then return b --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.isa(b, a) then return a --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	local a_is_variant = T.is_variant(a) --[[SOL OUTPUT--]] 
	local b_is_variant = T.is_variant(b) --[[SOL OUTPUT--]] 

	if a_is_variant and b_is_variant then
		local v = T.clone_variant( a ) --[[SOL OUTPUT--]] 
		for _,e in ipairs(b.variants) do
			v = T.extend_variant_one( v, e ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return v --[[SOL OUTPUT--]] 
	elseif a_is_variant then
		local v = T.clone_variant( a ) --[[SOL OUTPUT--]] 
		v = T.extend_variant_one(v, b) --[[SOL OUTPUT--]] 
		return v --[[SOL OUTPUT--]] 
	elseif b_is_variant then
		local v = T.clone_variant( b ) --[[SOL OUTPUT--]] 
		v = T.extend_variant_one(v, a) --[[SOL OUTPUT--]] 
		return v --[[SOL OUTPUT--]] 
	else
		return T.make_variant(a, b) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- used for expressions like "a + b"
-- works for tables, or numerics, i.e.   num+int == num
function T.combine(a, b)
	if T.isa(a, b) then return b --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.isa(b, a) then return a --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if a.tag == 'int_literal' and b.tag == 'int_literal' then
		return T.Int --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function is_num_literal(t)
		return t.tag == 'int_literal' or t.tag == 'num_literal' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if is_num_literal(a) and is_num_literal(b) then
		return T.Num --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	-- A true super-type
	U.printf_err('TODO: T.combine(%s, %s)', T.name(a), T.name(b)) --[[SOL OUTPUT--]] 
	return T.Any --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- TODO: make arguments : T.Typelist?
function T.combine_type_lists(a, b, forgiving)
	--forgiving = forgiving or true
	if forgiving == nil then
		forgiving = true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if _G.g_spam then
		U.printf('combine_type_lists(%s, %s)', T.name(a), T.name(b)) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if a == nil then return b --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b == nil then return a --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if a == T.AnyTypeList then return T.AnyTypeList --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b == T.AnyTypeList then return T.AnyTypeList --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	D.assert(T.is_type_list(a)) --[[SOL OUTPUT--]] 
	D.assert(T.is_type_list(b)) --[[SOL OUTPUT--]] 

	if forgiving then
		if #a < #b  then
			a = U.shallow_clone(a) --[[SOL OUTPUT--]] 
			while #a < #b do
				table.insert(a, T.Nil) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if #b < #a  then
			b = U.shallow_clone(b) --[[SOL OUTPUT--]] 
			while #b < #a do
				table.insert(b, T.Nil) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if #a ~= #b then
		local msg = string.format("Return statement with different number of values than the previous: %s vs %s", T.name(a), T.name(b)) --[[SOL OUTPUT--]] 
		error( msg ) --[[SOL OUTPUT--]] 
	else
		local ret = {} --[[SOL OUTPUT--]] 
		for i = 1, #a do
			ret[i] = T.variant( a[i], b[i] ) --[[SOL OUTPUT--]] 
			if _G.g_spam then
				U.printf('variant(%s, %s) = %s', T.name(a[i]), T.name(b[i]), T.name(ret[i])) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return ret --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- For assigning type to a variable
function T.broaden(t)
	if not t then return t --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if t.tag == 'int_literal' then
		return T.Int --[[SOL OUTPUT--]] 
	elseif t.tag == 'num_literal' then
		return T.Num --[[SOL OUTPUT--]] 
	elseif t.tag == 'string_literal' then
		return T.String --[[SOL OUTPUT--]] 
	elseif t == T.True or t == T.False then
		return T.Bool --[[SOL OUTPUT--]] 
	elseif t.tag == 'list' then
		return { tag = 'list', type = T.broaden(t.type) } --[[SOL OUTPUT--]] 
	elseif t.tag == 'map' then
		return {
			tag        = 'map',
			key_type   = T.broaden(t.key_type),
			value_type = T.broaden(t.value_type),
		} --[[SOL OUTPUT--]] 
	else
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.simplify(t)
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 

	if t.tag == 'variant' then
		if false then
			-- Quick
			if #t.variants == 1 then
				return t.variants[1] --[[SOL OUTPUT--]] 
			else
				return t --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			local v = T.make_variant() --[[SOL OUTPUT--]] 

			for _,variant in ipairs(t.variants) do
				variant = T.simplify(variant) --[[SOL OUTPUT--]] 
				--v = T.variant(v, variant)
				v = T.extend_variant_one(v, variant) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--U.printf("Simplified '%s' to '%s'", T.name(t), T.name(v))

			if #v.variants == 1 then
				return v.variants[1] --[[SOL OUTPUT--]] 
			else
				return v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	else
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Usage: for v in T.all_variants(some_type) do ... end
function T.all_variants(typ)
	local function all_vars(t)
		if t.tag == 'variant' then
			for _,v in ipairs(t.variants) do
				all_vars(v) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			coroutine.yield(t) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return coroutine.wrap(
		function()
			all_vars(typ) --[[SOL OUTPUT--]] 
		end) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


return T --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 