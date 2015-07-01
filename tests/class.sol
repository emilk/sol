class Klass = {}

function Klass.new() -> Klass
	local obj = {}
	setmetatable(obj, { __index = Klass })
	obj:init()
	return obj
end

function Klass:init()
	self.foo = 42
end
