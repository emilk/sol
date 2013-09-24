
global Math = {
	
}

-----------------------------------------

global class Vector3 = extern

Vector3.length    = extern : function(Vector3)->number
Vector3.normalize = extern : function(Vector3)->Vector3
Vector3.zero      = extern : function()->Vector3

setmetatable(Vector3, {
	__call = extern : function(x: number, y: number, z: number) -> Vector3;
})

-----------------------------------------

global class Quaternion = extern

setmetatable(Quaternion, {
	__call = extern : function(...) -> Quaternion;
})

global typedef Color = Quaternion
global Color = Quaternion

-----------------------------------------

global class Matrix4x4 = extern

setmetatable(Matrix4x4, {
	__call = extern : function(...) -> Matrix4x4;
})

-----------------------------------------

global Script   = { }
global Material = { }
global Unit     = { }
global Profiler = { }
