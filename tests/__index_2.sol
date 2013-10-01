local Singleton = { list = {} }

local receiver_meta = {
	__index = function(_, _)
		return function(_ : 'argument')
		end
	end,
}
setmetatable(Singleton, receiver_meta)

function Singleton.fun()
end

Singleton.list['key'] = nil
