global class Vector3 = extern : object

Vector3.zero = extern : function()->Vector3

--[[
-- FAILS :(
setmetatable(Vector3, {
	__call  = extern : function(Vector3, x: number, y: number, z: number) -> Vector3;
	--__index = extern : function(Vector3, 'x' or 'y' or 'z') -> number;
	__index = extern : { x: number, y: number, z: number };

	__add = extern : function(Vector3, Vector3) -> Vector3;
	__sub = extern : function(Vector3, Vector3) -> Vector3;
})
--]]
Vector3.__call  = extern : function(Vector3, x: number, y: number, z: number) -> Vector3
Vector3.__index = extern : { x: number, y: number, z: number }

Vector3.__add = extern : function(Vector3, Vector3) -> Vector3
Vector3.__sub = extern : function(Vector3, Vector3) -> Vector3

local function add(a: Vector3)
	return a + a
end