-----------------------------------------------------
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

--global x = 1337
local  a = x



-----------------------------------------------------
-- Argument checking

local Foo = {}

Foo.member()
Foo:member()
Foo.member(Foo)
Foo:member(Foo)

-- Note - no forward-declare needed!
function Foo:member()
	self.member()
	self:member()
	self.member(self)
	self:member(self)
end




-----------------------------------------------------
-- pairs/ipairs

do
	local list = { "one", "two", "three" }
	for i,v in pairs(list) do
		print(i .. ': ' .. v)
	end

	local map = { ['one'] = 1, ['two'] = 2, ['three'] = 3 }
	for k,v in ipairs(map) do
		k = k + '42'
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

var i = int_to_string("42")
i = i + 42


local function cmp(a: int?, b: string?) -> bool?
	return a == b
	--return true
	--return nil
end



typedef fmt_string = string -- TODO

local function foo(fmt: fmt_string, ...)
end

foo("hello", 1, 2, 3, 3.14)




-----------------------------------------------------
-- What is the return type of this?
local function win_or_fail()
	if math.random() < 0.5 then
		return true
	else
		return false, "bad luck"
	end
end

local win, err_msg, too_many = win_or_fail()





-----------------------------------------------------
-- var vs local

local     local_can_be_anything = require 'unfindable'
var       var_must_be_deducible = some_lua_function()
var<int>  var_can_be_explicit   = require 'unfindable'



-----------------------------------------------------
-- Maps and lists:

do
	var<[int]> list = {1, 2, 3}
	list[1] = 42
	list[2] = '1337'

	typedef Int2str = {int => string} 
	var<Int2str> map = {}
	map[1] = 'one'
	map[2] = 'two'
	map['three'] = 3
end



-----------------------------------------------------
-- Enums

typedef Tribool = 'yes' or 'no' or 'maybe'

var<Tribool> ok  = 'yes'
var<Tribool> bad = 'wrong'

local function do_stuff(how: "quickly" or "slowly")

end

do_stuff("quickly")
do_stuff("sakta")


-----------------------------------------------------
-- Function pointers

typedef IntFilter = function(int) -> bool

local function filter_number(fp: IntFilter, doWhat: function(int))
	for i=1,42 do
		if fp(i) then
			doWhat(i)
		end
	end
end

filter_number(
	function(i: int)  return i%2==1          end,
	function(i: int)  print(i .. " is odd")  end
	)


-----------------------------------------------------
-- Objects and inheritence
typedef Node = {
	tag: 'Foo' or 'Bar';
	korv: int;
}

typedef FooNode : Node = {
	tag:   'Foo';
	int:   int;
	wild:  int;
}

typedef BarNode : Node = {
	tag:    'Bar';
	string: string;
	wild:   string;
}

local function work_on_node(n: Node)
	if n.tag == 'Foo' then
		var<FooNode> f = n
	end

	var<[string]> a = n.wild
end

work_on_node({
	tag  = 'Foo';
	korv = 32
	})


work_on_node({
	tag  = 'Baz'
	})

