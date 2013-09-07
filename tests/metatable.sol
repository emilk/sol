local Class = {}
--[[
function Class:init()
end
--]]
function Class:get()
	return 42
end


local obj={}
local mt = { __index = Class }
setmetatable(obj, mt)
--obj:init()
var x = obj:get()
