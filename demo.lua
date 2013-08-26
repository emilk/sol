--[[ DO NOT MODIFY - COMPILED FROM demo.sol --]] -----------------------------------------------------
--[[
# SOL IS:
* Lua + static typing
* Flexible, plausible typing


# SOL IS NOT:
* Waterproof
* More than Lua (yet!)

--]]



-----------------------------------------------------
-- Undefined globals

 x = 1337
local  a = x



-----------------------------------------------------
-- Argument checking

local Foo = {}

--Foo.member()
Foo:member()
Foo.member(Foo)
--Foo:member(Foo)

-- Note - no forward-declare needed!
function Foo:member()
	--self.member()
	self:member()
	self.member(self)
	--self:member(self)
end



-----------------------------------------------------
-- pairs/ipairs

do
	local list = { "one", "two", "three" }
	for i,v in ipairs(list) do
		print(i .. ': ' .. v)
	end

	local map = { ['one'] = 1, ['two'] = 2, ['three'] = 3 }
	for k,v in pairs(map) do
		k = k .. '42'
		v = v + 42
	end
end



-----------------------------------------------------
-- Add a type annotation to the function

local function int_to_string(arg)
	return '' .. arg
end

local function string_to_int(arg)
	if arg then
		return tonumber(arg)
	else
		return 0
	end
end

local i = string_to_int("42")
i = i + 42


local function cmp(a, b)
	--return a == b
	--return true
	return nil
end



-----------------------------------------------------
-- What is the return type of this?
local function win_or_fail()
	if math.random() < 0.5 then
		return true, nil
	else
		return false, "bad luck"
	end
end

local win, err_msg = win_or_fail()





-----------------------------------------------------
-- var vs local

local     local_can_be_anything = require 'unfindable'
--var       var_must_be_deducible = some_lua_function()
local  var_can_be_explicit   = require 'unfindable'



-----------------------------------------------------
-- Maps and lists:

do
	local list = {1, 2, 3}
	list[1] = 42 
	local map 


= {}
	map[1] = 'one'
	map[2] = 'two'
	--map['three'] = 3
end

local ok  






= 'yes'
--var<Tribool> bad = 'wrong'

local function do_stuff(how)

end

do_stuff("quickly")








local function filter_number(fp, doWhat)
	for i=1,42 do
		if fp(i) then
			doWhat(i)
		end
	end
end

filter_number(
	function(i)  return i%2==1          end,
	function(i)  print(i .. " is odd")  end
	)





















local function work_on_node(n)
	if n.tag == 'Foo' then
		local f = n
	end

	local a = n.wild
end


work_on_node({
	tag  = 'Foo';
	korv = 32
	})

--[[
work_on_node({
	tag  = 'Baz'
	})
--]]
