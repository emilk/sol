local functor = {}

setmetatable(functor, {
	__call = function(self, x: int)
		assert(self == functor)
		return 2*x
	end
})

local d = functor(42)
assert(d == 84)
