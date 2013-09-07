var Class = {}

function Class:get()
	return 42
end

var obj = {}
var mt = { __index = Class }
setmetatable(obj, mt)
var x = obj:get()
assert(x == 42)
