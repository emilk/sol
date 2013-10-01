local Singleton = { routers = {} }

local receiver_meta = {
	__index = function(_, _)
		return function(_ : 'argument')
		end
	end,
}
setmetatable(Singleton, receiver_meta)

function Singleton.some_member()
end

Singleton.routers['key'] = nil
