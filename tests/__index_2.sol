--	©2013 Arrowhead Game Studios AB
--	This file is part of the Arrowhead Foundation.

local FlowCallbackRouter = { routers = {} }

local receiver_meta = {
	__index = function(t, key)
		return function(...)
			for _, router in pairs(FlowCallbackRouter.routers) do
				router:trigger(key, ...)
			end
		end
	end,
}
setmetatable(FlowCallbackRouter, receiver_meta)

function FlowCallbackRouter.register_router(key, router)
	FlowCallbackRouter.routers[key] = router
end
function FlowCallbackRouter.unregister_router(key)
	FlowCallbackRouter.routers[key] = nil
end

return FlowCallbackRouter
