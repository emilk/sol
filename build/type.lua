--[[ DO NOT MODIFY - COMPILED FROM sol/type.sol on 2013 Oct 12  03:46:48 --]] --[[
A type can either be a particular value (number or string) or one of the following.
--]]

local U = require 'util' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 

--[[
FIXME: recursive dependency
local S = require 'scope'
--]]
local T = {} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 



T
















.on_error = function(fmt, ...)
	local msg = string.format(fmt, ...) --[[SOL OUTPUT--]] 
	U.printf_err( "%s", msg ) --[[SOL OUTPUT--]] 
	--error(msg, 2)
end --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  -- TODO: implement fully

local ATOMIC_TAGS 









= U.set{'any', 'int_literal', 'num_literal', 'string_literal',
                        'nil', 'true', 'false', 'int', 'number', 'string'} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 

------------------------------------------------------------------
-- Prototypes for common stuff:


-- Any: implicit convert to and from anything.
-- Used for interaction with Lua code.
T
















































































.Any  = { tag = 'any'  } --[[SOL OUTPUT--]]   -- Single unknown value
T.AnyTypeList = {} --[[SOL OUTPUT--]]    -- Unkown number of unknown values
--T.AnyTypeList = { { tag = 'varargs', type = T.Any } }  -- TODO

T.Nil      = { tag = 'nil'    } --[[SOL OUTPUT--]] 
T.True     = { tag = 'true'   } --[[SOL OUTPUT--]] 
T.False    = { tag = 'false'  } --[[SOL OUTPUT--]] 
T.String   = { tag = 'string' } --[[SOL OUTPUT--]] 
T.Num      = { tag = 'number'    } --[[SOL OUTPUT--]] 
T.Int      = { tag = 'int'    } --[[SOL OUTPUT--]] 
--T.Empty    = { tag = 'variant', variants = {} }

--T.Void     = T.Empty
T.Void     = {} --[[SOL OUTPUT--]]  -- empty type-list
T.Nilable  = T.Any --[[SOL OUTPUT--]]   -- TODO

T.Uint = T.Int --[[SOL OUTPUT--]]                -- TODO
T.Bool = { tag = 'variant',  variants = { T.True, T.False } } --[[SOL OUTPUT--]] 


-- General table - could be an object, list or map:
T.Table = { tag = 'table' } --[[SOL OUTPUT--]] 

-- Supertype of all objects:
T.Object = { tag = 'object', members = {} } --[[SOL OUTPUT--]] 

-- Supertype of all lists:
T.List = { tag = 'list', type = T.Any } --[[SOL OUTPUT--]] 

-- Supertype of all maps:
T.Map = { tag = 'map', key_type = T.Any, value_type = T.Any } --[[SOL OUTPUT--]] 

------------------------------------------------------------------

function T.is_type(x)
	return type(x) == 'table' and type(x.tag) == 'string' --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

T._empty_table = { tag = 'table' } --[[SOL OUTPUT--]] 

-- TODO: disallow=
function T.create_empty_table()
	--return { tag='object', members={} }
	--return T.Table
	return T._empty_table --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

-- TODO: remove
function T.is_empty_table(t)
	--return t.tag == 'object' and next(t.members) == nil
	--return t.tag == 'table'
	--return T.follow_identifiers(t).tag == 'table'
	return t == T._empty_table --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.is_void(ts)
	return T.is_type_list(ts) and #ts == 0 --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.follow_identifiers(t, forgiving)
	D.assert(t) --[[SOL OUTPUT--]] 

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
		
		assert( t.scope ) --[[SOL OUTPUT--]] 
		local scope = t.scope --[[SOL OUTPUT--]] 

		if t.var_name then
			-- TODO: var (when we can break cyclic depndency)
			local var_ = scope:get_var( t.var_name ) --[[SOL OUTPUT--]]   -- A namespace is always a variable
			if not var_ then
				T.on_error("%s: Failed to find namespace variable %q", t.first_usage, t.var_name) --[[SOL OUTPUT--]] 
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
				var_.num_reads = var_.num_reads + 1 --[[SOL OUTPUT--]] 
				if not t.type then
					T.on_error("%s: type %s not found in namespace '%s'", t.first_usage, t.name, var_.name) --[[SOL OUTPUT--]] 
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
					string.format("member '%s' of wrong type (got: %s, expected: %s)",
					              id, U.quote_or_indent(T.name(d_type)), U.quote_or_indent(T.name(b_type)))) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	-- TODO: check metatables, super-classes etc?

	return true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


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
local RECURSION = {'RECURSION'} --[[SOL OUTPUT--]] 
local isa_memo = {} --[[SOL OUTPUT--]] 

function T.isa(d, b, problem_rope)
	D.assert(d) --[[SOL OUTPUT--]] 
	D.assert(b) --[[SOL OUTPUT--]] 
	local res = isa_memo[d] and isa_memo[d][b] --[[SOL OUTPUT--]] 
	D.assert(res ~= RECURSION) --[[SOL OUTPUT--]] 

	if res == true then
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if problem_rope then
		if res == false or res == nil then
			-- We need to generate a problem description:
			isa_memo[d] = isa_memo[d] or {} --[[SOL OUTPUT--]] 
			isa_memo[d][b] = RECURSION --[[SOL OUTPUT--]] 

			local isa_rope = {} --[[SOL OUTPUT--]] 
			T.isa_raw(d, b, isa_rope) --[[SOL OUTPUT--]] 
			res = table.concat(isa_rope, '\n') --[[SOL OUTPUT--]] 

			isa_memo[d][b] = res --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		assert(type(res) == 'string') --[[SOL OUTPUT--]] 
		problem_rope[#problem_rope + 1] = res --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 
	else
		-- No problem description needed
		if res==nil then
			isa_memo[d] = isa_memo[d] or {} --[[SOL OUTPUT--]] 
			isa_memo[d][b] = RECURSION --[[SOL OUTPUT--]] 

			res = T.isa_raw(d, b) --[[SOL OUTPUT--]] 

			isa_memo[d][b] = res --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return res --[[SOL OUTPUT--]] 
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


	if b.tag == 'any' or d.tag == 'any' then
		-- 'any' can become anything
		-- Anything can become 'any'
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if b.tag == 'variant' then
		for _,v in ipairs(b.variants) do
			if T.isa(d, v, problem_rope) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if d.tag == 'variant' then
		local function all_are_b()
			for _,v in ipairs(d.variants) do
				if not T.isa(v, b, problem_rope) then
					return false --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return all_are_b() --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	if d.tag == 'int_literal' then
		if (b.tag == 'int_literal' or b.tag == 'num_literal') and b.value == d.value then
			-- Same value
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return b.tag == 'number' or b.tag == 'int' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if d.tag == 'num_literal' then
		if b.tag == 'num_literal' and b.value == d.value then
			-- Same value
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return b.tag == 'number' --[[SOL OUTPUT--]] 
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
	elseif d.tag == 'number' then
		return b.tag == 'number' --[[SOL OUTPUT--]] 
	elseif d.tag == 'int' then
		return b.tag == 'number'
		    or b.tag == 'int' --[[SOL OUTPUT--]] 
	elseif d.tag == 'table' then
		return false --[[SOL OUTPUT--]]  -- Already covered
	elseif d.tag == 'extern' then
		return d == b --[[SOL OUTPUT--]]   -- Same extern!
	elseif d.tag == 'list' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'list'
		  and  T.isa(d.type, b.type, problem_rope) --[[SOL OUTPUT--]]  -- [int] isa [num]  -- FIXME: make strictly equal?
	elseif d.tag == 'map' then
		--if b == T.EmptyTable then return true end
		return b.tag == 'map'
		  and  T.isa(d.key_type,   b.key_type, problem_rope)    -- {int, string}  isa  {num, string}  -- FIXME: make strictly equal?
		  and  T.isa(d.value_type, b.value_type, problem_rope) --[[SOL OUTPUT--]]   -- {string, int}  isa  {string, num}  -- FIXME: make strictly equal?
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
			if problem_rope then problem_rope[#problem_rope+1] = "Differing number of arguments" --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for i = 1, #d.args do
			if not T.isa(d.args[i].type, b.args[i].type, problem_rope) then
				if problem_rope then problem_rope[#problem_rope+1] = "Argument "..i.." differs" --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if b.rets then
			if not T.isa_typelists(d.rets, b.rets, problem_rope) then
				if problem_rope then problem_rope[#problem_rope+1] = "Return types differs" --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if (d.vararg==nil) ~= (b.vararg==nil) then
			if problem_rope then problem_rope[#problem_rope+1] = "One fuction has var-args" --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if d.vararg and b.vararg then
			if not T.isa(d.vararg, b.vararg, problem_rope) then
				if problem_rope then problem_rope[#problem_rope+1] = "Var-arg types differ" --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return true --[[SOL OUTPUT--]] 
	elseif d.tag == 'varargs' and b.tag == 'varargs' then
		return T.isa(d.type, b.type) --[[SOL OUTPUT--]] 
	else
		--error('isa failed: derived: ' .. U.pretty(d) .. ', base: ' .. U.pretty(b))
		return error('isa failed: derived: ' .. T.name(d) .. ', base: ' .. T.name(b)) --[[SOL OUTPUT--]] 
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

	local has_nil     = false --[[SOL OUTPUT--]] 
	local has_non_nil = false --[[SOL OUTPUT--]] 

	local function recurse(t)
		if t.tag == 'variant' then
			for _,v in ipairs(t.variants) do
				recurse(v) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		elseif t == T.Any then
			has_nil = true --[[SOL OUTPUT--]] 
			has_non_nil = true --[[SOL OUTPUT--]] 
		elseif t == T.Nil then
			has_nil = true --[[SOL OUTPUT--]] 
		else
			has_non_nil = true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	recurse(a) --[[SOL OUTPUT--]] 

	--return T.could_be(a, T.Nil)
	return has_nil and has_non_nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.make_nilable(a)
	if false then
		if T.is_nilable(a) then
			return a --[[SOL OUTPUT--]] 
		else
			return T.variant(a, T.Nil) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	else
		--return T.make_variant(a, T.Nil)  -- FIXME: produces  Foo or nil or nil
		return T.variant(a, T.Nil) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.is_any(a)
	local forgiving = true --[[SOL OUTPUT--]] 
	a = T.follow_identifiers(a, forgiving) --[[SOL OUTPUT--]] 

	if a.tag == 'any' then
		return true --[[SOL OUTPUT--]] 

	elseif a.tag == 'variant' then
		for _,v in ipairs(a.variants) do
			if T.is_any(v) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return false --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- Can it be used in boolean expression?
function T.is_bool(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	return T.is_any(a) or T.isa(a, T.Bool) or T.is_nilable(a) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.has_tag(t, target)
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 

	if t.tag == target then
		return true --[[SOL OUTPUT--]] 

	elseif T.is_variant(t) then
		for _,v in ipairs(t.variants) do
			--print("Find: searching variant " .. T.name(v))
			if T.has_tag(v, target) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return false --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

-- Memoization:
-- true   -> yes, it is
-- false  -> no, and no error string generated yet
-- string -> no, and here's the error string
local could_be_memo = {} --[[SOL OUTPUT--]] 

function T.could_be(d, b, problem_rope)
	D.assert(d) --[[SOL OUTPUT--]] 
	D.assert(b) --[[SOL OUTPUT--]] 
	local res = could_be_memo[d] and could_be_memo[d][b] --[[SOL OUTPUT--]] 
	D.assert(res ~= RECURSION) --[[SOL OUTPUT--]] 

	if res == true then
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if problem_rope then
		if res == false or res == nil then
			-- We need to generate a problem description:
			could_be_memo[d] = could_be_memo[d] or {} --[[SOL OUTPUT--]] 
			could_be_memo[d][b] = RECURSION --[[SOL OUTPUT--]] 

			local could_be_rope = {} --[[SOL OUTPUT--]] 
			T.could_be_raw(d, b, could_be_rope) --[[SOL OUTPUT--]] 
			res = table.concat(could_be_rope, '\n') --[[SOL OUTPUT--]] 

			could_be_memo[d][b] = res --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		assert(type(res) == 'string') --[[SOL OUTPUT--]] 
		problem_rope[#problem_rope + 1] = res --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 
	else
		-- No problem description needed
		if res==nil then
			could_be_memo[d] = could_be_memo[d] or {} --[[SOL OUTPUT--]] 
			could_be_memo[d][b] = RECURSION --[[SOL OUTPUT--]] 

			res = T.could_be_raw(d, b) --[[SOL OUTPUT--]] 

			could_be_memo[d][b] = res --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return res --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 



-- is a variant of 'a' a 'b' ?
-- T.could_be(T.Bool, T.False)  == true
-- T.could_be(some_nilable, T.Nil)  == true
-- T.could_be(int or bool, string or bool)  == true
-- T.could_be(int or nil, string or nil)  == false
function T.could_be_raw(a, b, problem_rope)
	if a==b then
		-- Early out:
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	D.assert( T.is_type(a) ) --[[SOL OUTPUT--]] 
	D.assert( T.is_type(b) ) --[[SOL OUTPUT--]] 

	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	b = T.follow_identifiers(b) --[[SOL OUTPUT--]] 

	if a == b then
		return true --[[SOL OUTPUT--]]  -- Early out optimization
	end --[[SOL OUTPUT--]] 

	if a.tag == 'any' then return true --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b.tag == 'any' then return true --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if a.tag == 'variant' then
		for _,v in ipairs(a.variants) do
			if v==b then
				return true --[[SOL OUTPUT--]] 
			elseif v~=T.Nil and T.could_be(v, b, problem_rope) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 
	elseif b.tag == 'variant' then
		for _,v in ipairs(b.variants) do
			if v==a then
				return true --[[SOL OUTPUT--]] 
			elseif v~=T.Nil and T.could_be(a, v, problem_rope) then
				return true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return false --[[SOL OUTPUT--]] 

	elseif b.tag == 'table' then
		return a.tag == 'table'
		    or a.tag == 'list'
		    or a.tag == 'map'
		    or a.tag == 'object' --[[SOL OUTPUT--]] 

	elseif a.tag == 'list' then
		return b.tag == 'list'
		   and T.could_be(a.type, b.type, problem_rope) --[[SOL OUTPUT--]] 

	elseif a.tag == 'map' then
		return b.tag == 'map'
		   and T.could_be(a.key_type,   b.key_type,   problem_rope)
		   and T.could_be(a.value_type, b.value_type, problem_rope) --[[SOL OUTPUT--]] 

	elseif a.tag == 'object' then
		if b.tag ~= 'object' then return false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

		for id, b_type in pairs(b.members) do
			local a_type = a.members[id] --[[SOL OUTPUT--]] 
			if a_type and not T.could_be(a_type, b_type, problem_rope) then
				if problem_rope then
					table.insert(problem_rope,
						string.format("member '%s' of wrong type (got: %s, expected: %s)",
						              id, U.quote_or_indent(T.name(a_type)), U.quote_or_indent(T.name(b_type)))) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				return false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		-- TODO: check metatables, super-classes etc?

		return true --[[SOL OUTPUT--]] 

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
	if al == T.AnyTypeList or bl == T.AnyTypeList then
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

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


-- Tests if a type has the potential to be true and/or false
function T.could_be_true_false(a)
	a = T.follow_identifiers(a) --[[SOL OUTPUT--]] 
	if a == T.Any then
		return true, true --[[SOL OUTPUT--]] 
	elseif a == T.Nil or a == T.False then
		return false, true --[[SOL OUTPUT--]] 
	elseif T.is_variant(a) then
		local t,f = false,false --[[SOL OUTPUT--]] 
		for _,v in ipairs(a.variants) do
			local vt,vf = T.could_be_true_false(v) --[[SOL OUTPUT--]] 
			t = t or vt --[[SOL OUTPUT--]] 
			f = f or vf --[[SOL OUTPUT--]] 
			if t and f then
				return true,true --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return t,f --[[SOL OUTPUT--]] 
	else
		return true, false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- is 'a' a boolean expresson that could be evaluates as either true and false?
-- If not, we are doing something like    if always_true then ...
-- Which is almost certainly wrong
function T.is_useful_boolean(a)
	local t,f = T.could_be_true_false(a) --[[SOL OUTPUT--]] 
	return t and f --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


----------------------------------------------


function T.is_atomic(t)
	return ATOMIC_TAGS[t.tag] --[[SOL OUTPUT--]] -- or t.tag == 'identifier'
end --[[SOL OUTPUT--]] 

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

function T.table_id(t)
	return tostring(t):gsub("table: ", "") --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.format_type(root, verbose)
	if verbose == nil then verbose = false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	local written_objs = {} --[[SOL OUTPUT--]] 
	local output_types, output_obj --[[SOL OUTPUT--]] 

	local function output(typ, indent)
		local next_indent = indent .. U.INDENTATION --[[SOL OUTPUT--]] 

		if typ.tag == 'any' then
			return 'any' --[[SOL OUTPUT--]] 

		elseif typ.tag == 'variant' then
			local function output_packaged(typ, indent)
				if typ.tag == 'function' and typ.rets then
					return '('..output(typ, indent)..')' --[[SOL OUTPUT--]] 
				else
					return output(typ, indent) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if #typ.variants == 0 then
				D.break_() --[[SOL OUTPUT--]] 
				return "void [EMPTY VARIANTS]" --[[SOL OUTPUT--]] 
			elseif #typ.variants == 1 then
				return output(typ.variants[1], indent) --[[SOL OUTPUT--]] 
			else
				if #typ.variants == 2
					and typ.variants[2] == T.Nil 
					and typ.variants[1].tag ~= 'variant'
					and typ.variants[1].tag ~= 'function'
				then
					return output_packaged(typ.variants[1], next_indent) .. '?' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local str = '' --[[SOL OUTPUT--]] 
				for i,t in ipairs(typ.variants) do
					str = str .. output_packaged(t, next_indent) --[[SOL OUTPUT--]] 
					if i ~= #typ.variants then
						str = str .. ' or ' --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				return str --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif typ.tag == 'object' then
			--verbose = false -- FIXME 

			local obj = typ --[[SOL OUTPUT--]] 

			if written_objs[obj] then
				return '<RECURSION '..T.table_id(obj)..'>' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			written_objs[obj] = true --[[SOL OUTPUT--]] 
			local ret = output_obj(obj, indent) --[[SOL OUTPUT--]] 
			written_objs[obj] = nil --[[SOL OUTPUT--]] 

			return ret --[[SOL OUTPUT--]] 

		elseif typ.tag == 'list' then
			return '[' .. output(typ.type, next_indent) .. ']' --[[SOL OUTPUT--]] 

		elseif typ.tag == 'map' then
			if typ.value_type == T.True then
				-- A set
				return '{' .. output(typ.key_type, next_indent) .. '}' --[[SOL OUTPUT--]] 
			else
				-- A map
				return '{' .. output(typ.key_type, next_indent) .. ' => ' .. output(typ.value_type, next_indent) .. '}' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif typ.tag == 'function' then
			local str = 'function(' --[[SOL OUTPUT--]] 
			for i,arg in ipairs(typ.args) do
				if arg.name then
					str = str .. arg.name --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if arg.type and not T.is_any(arg.type) then
					if arg.name ~= 'self' then -- Potential recursion (object has function taking object as arg...)
						str = str .. ": " .. output(arg.type, next_indent) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if i ~= #typ.args or typ.vararg then
					str = str .. ", " --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			if typ.vararg then
				str = str .. "..." --[[SOL OUTPUT--]] 
				if not T.is_any(typ.vararg) then
					str = str .. " : " .. output(typ.vararg.type, next_indent) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			str = str .. ')' --[[SOL OUTPUT--]] 
			if typ.rets then
				str = str .. ' -> ' .. output_types(typ.rets, next_indent) --[[SOL OUTPUT--]] 
			else
				--str = str .. ' -> ...'
			end --[[SOL OUTPUT--]] 
			return str --[[SOL OUTPUT--]] 

		elseif typ.tag == 'int_literal' or typ.tag == 'num_literal' then
			return '' .. typ.value --[[SOL OUTPUT--]] 

		elseif typ.tag == 'string_literal' then
			return string.format('%q', typ.value) --[[SOL OUTPUT--]] 

		elseif typ.tag == 'identifier' then
			if (verbose or _G.g_spam) and typ.type then
			--if typ.type then
				return string.format('%s (%s)', typ.name, output(typ.type, next_indent)) --[[SOL OUTPUT--]] 
			else
				return string.format('%s', typ.name) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif typ.tag == 'extern' then
			if typ.name then
				return typ.name .. '<extern>' --[[SOL OUTPUT--]] 
			else
				return '<extern>' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			return typ.tag --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	output_obj = function(obj, indent)
		local next_indent = indent .. U.INDENTATION --[[SOL OUTPUT--]] 

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
				str = str .. next_indent .. 'typedef ' .. m.name .. " = " .. output(m.type, next_indent) .. ";\n" --[[SOL OUTPUT--]] 
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

			local type_indent = next_indent --[[SOL OUTPUT--]] 
			for i = 1,widest_name+2 do
				type_indent = type_indent..' ' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			for _,m in ipairs(mem_list) do
				str = str .. next_indent .. m.name .. ": " --[[SOL OUTPUT--]] 

				-- Align:
				for i = #m.name, widest_name - 1 do
					str = str .. ' ' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				str = str .. output(m.type, type_indent) .. ";\n" --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if obj.metatable then
			if str ~= '' then
				--str = str .. '\n' .. next_indent .. '-- metatable:\n'
				str = str .. '\n' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			str = str .. next_indent .. "!! metatable:     " .. output(obj.metatable, next_indent) .. '\n' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if obj.class_type then
			if str ~= '' then str = str .. '\n' --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			str = str .. next_indent .. "!! class_type:    " .. output(obj.class_type, next_indent) .. '\n' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if obj.instance_type then
			if str ~= '' then str = str .. '\n' --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			str = str .. next_indent .. "!! instance_type: " .. output(obj.instance_type, next_indent) .. '\n' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local str_timmed = U.trim(str) --[[SOL OUTPUT--]] 

		local full = '' --[[SOL OUTPUT--]] 

		if str_timmed == '' then
			full = '{ }' --[[SOL OUTPUT--]] 
		elseif U.count_line_breaks(str_timmed) == 0 then
			-- One-liner - e.g.   { foo: int }
			full = '{ ' .. str_timmed ..' }' --[[SOL OUTPUT--]] 
		else
			local shortened = str_timmed:gsub('%s%s+', '  ') --[[SOL OUTPUT--]] 
			shortened = shortened:gsub(":%s+", ': ') --[[SOL OUTPUT--]] 

			if #shortened < 50 then
				-- One-line - e.g.  { x: number  y: number }
				full = '{ ' .. shortened ..' }' --[[SOL OUTPUT--]] 
			else
				full = '{\n' .. str .. indent ..'}' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--full = '<'..T.table_id(obj)..'>'..full -- great for debugging

		if obj.class_type then
			return '<instance>' .. full --[[SOL OUTPUT--]] 
		elseif obj.instance_type then
			return '<class>' .. full --[[SOL OUTPUT--]] 
		else
			return full --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	output_types = function(typelist, indent)
		if #typelist == 0 then
			return "void" --[[SOL OUTPUT--]] 
		elseif #typelist == 1 then
			return output(typelist[1], indent) --[[SOL OUTPUT--]] 
		else
			local str='' --[[SOL OUTPUT--]] 
			for i,t in ipairs(typelist) do
				str = str .. output(t, indent) --[[SOL OUTPUT--]] 
				if i ~= #typelist then
					str = str .. ', ' --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return str --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return output(root, "") --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.names(typ, verbose)
	if #typ == 0 then
		return "void" --[[SOL OUTPUT--]] 
	else
		local str='' --[[SOL OUTPUT--]] 
		for i,t in ipairs(typ) do
			str = str .. T.name(t, verbose) --[[SOL OUTPUT--]] 
			if i ~= #typ then
				str = str .. ', ' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return str --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.name(typ, verbose)
	if verbose == nil then verbose = false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if typ == nil then
		--D.error_()
		return 'NIL' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	
	if typ == T.AnyTypeList then
		return "..." --[[SOL OUTPUT--]] 

	elseif T.is_type_list(typ) then
		--D.error_()	
		return T.names(typ, verbose) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	D.assert( T.is_type(typ) ) --[[SOL OUTPUT--]] 

	return T.format_type(typ, verbose) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.name_verbose(typ)
	return T.name(typ, true) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.is_variant(t)
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 
	if t.tag == 'variant' then
		return t --[[SOL OUTPUT--]] 
	else
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.extend_variant_one(v, e)
	--if #v.variants > 15 then
	--	U.printf("WARNING: extremely long variant: %s", T.name(v))
	--end

	if e == T.Any then
		v.variants = { T.Any } --[[SOL OUTPUT--]] 	
	else
		if not T.isa(e, v) then
			local ev = T.is_variant(e) --[[SOL OUTPUT--]] 
			if ev then
				for _,et in ipairs(ev.variants) do
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

		if e == T.Any then
			-- Early out
			break --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
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


local function un_literal(t)
	if t.tag == 'int_literal' then return T.Int --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if t.tag == 'num_literal' then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	return t --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

-- used for expressions like "a + b"
-- works for tables, or numerics, i.e.   num+int == num
function T.combine_num_int(a, b)
	if T.is_any(a)                  then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.has_tag(a, 'number')       then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.has_tag(a, 'num_literal')  then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.is_any(a)                  then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.has_tag(b, 'number')       then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if T.has_tag(b, 'num_literal')  then return T.Num --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	return T.Int --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function T.combine_type_lists(a, b, forgiving)
	--forgiving = forgiving or true
	if forgiving == nil then
		forgiving = true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if _G.g_spam then
		--U.printf('combine_type_lists(%s, %s)', T.name(a), T.name(b))
	end --[[SOL OUTPUT--]] 

	if a == nil then return b --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b == nil then return a --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

	if a == T.AnyTypeList then return T.AnyTypeList --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	if b == T.AnyTypeList then return T.AnyTypeList --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 	

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
		return error( msg ) --[[SOL OUTPUT--]] 
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

function T.broaden_non_nil(t)
	if t.tag == 'int_literal' then
		return T.Int --[[SOL OUTPUT--]] 
	elseif t.tag == 'num_literal' then
		return T.Num --[[SOL OUTPUT--]] 
	elseif t.tag == 'string_literal' then
		return T.String --[[SOL OUTPUT--]] 
	elseif t == T.True or t == T.False then
		return T.Bool --[[SOL OUTPUT--]] 
	elseif t.tag == 'list' then
		return { tag = 'list', type = T.broaden_non_nil(t.type) } --[[SOL OUTPUT--]] 
	elseif t.tag == 'map' then
		return {
			tag        = 'map',
			key_type   = T.broaden_non_nil(t.key_type),
			value_type = T.broaden_non_nil(t.value_type),
		} --[[SOL OUTPUT--]] 
	elseif t.tag == 'variant' then
		-- false?   ->  bool?
		local ret = {
			tag      = 'variant',
			variants = {}
		} --[[SOL OUTPUT--]] 
		for ix,v in ipairs(t.variants) do
			ret.variants[ix] = T.broaden_non_nil(v) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return ret --[[SOL OUTPUT--]] 
	else
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- For assigning type to a variable
function T.broaden(t)
	if t == nil then
		return nil --[[SOL OUTPUT--]] 
	elseif t == T.Nil then
		--[[
		obj.member = nil
		if obj.member then  -- should not warn!
		end
		obj.member = 42
		--]]
		return T.Nilable --[[SOL OUTPUT--]] 
	else
		return T.broaden_non_nil(t) --[[SOL OUTPUT--]] 
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


function T.is_instance(typ)
	-- If we are associated with a class, we are an instance of that class
	return typ.class_type ~= nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.is_class(typ)
	return typ.instance_type ~= nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.should_extend_in_situ(typ)
	return T.is_instance(typ) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.find_meta_method(t, name)
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 
	if t.tag == 'variant' then
		for _,v in ipairs(t.variants) do
			local mm = T.find_meta_method(v, name) --[[SOL OUTPUT--]] 
			if mm then return mm --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	elseif t.tag == 'object' then
		if t.metatable then
			return t.metatable.members[name] --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

-- Recurses on variants and calls lambda on all non-variants.
-- It combines the results into a variant.
--typedef TypeVisitor = function(T.Type)->T.Type?
--function T.visit_and_combine(t: T.Type, lambda: TypeVisitor) -> T.Type?
function T.visit_and_combine(t, lambda)
	D.assert(T.is_type(t)) --[[SOL OUTPUT--]] 
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 
	D.assert(T.is_type(t)) --[[SOL OUTPUT--]] 

	if t.tag == 'variant' then
		local ret = nil --[[SOL OUTPUT--]] 
		for _,v in ipairs(t.variants) do
			D.assert(T.is_type(v)) --[[SOL OUTPUT--]] 
			local tmp = T.visit_and_combine(v, lambda) --[[SOL OUTPUT--]] 
			ret = T.variant(ret, tmp) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return ret --[[SOL OUTPUT--]] 

	else
		local ret = lambda(t) --[[SOL OUTPUT--]] 
		return ret --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function T.visit(t, lambda)
	t = T.follow_identifiers(t) --[[SOL OUTPUT--]] 

	if t.tag == 'variant' then
		for _,v in ipairs(t.variants) do
			T.visit(v, lambda) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

	else
		lambda(t) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


return T --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 