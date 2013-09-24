
----------------------------------------------------------------------------------
-- Namespaces: 

global Application = { }
global Script      = { }
global Material    = { }
global Math	        = { }
global Mesh        = { }
global Unit        = { }
global Profiler    = { }


----------------------------------------------------------------------------------
-- Types:

global class Vector3 = extern

Vector3.length      = extern : function(Vector3)->number
Vector3.normalize   = extern : function(Vector3)->Vector3
Vector3.zero        = extern : function()->Vector3
Vector3.to_elements = extern : function(Vector3)->number,number,number

setmetatable(Vector3, {
	__call = extern : function(self: Vector3, x: number, y: number, z: number) -> Vector3;
})

-----------------------------------------

global class Quaternion = extern

setmetatable(Quaternion, {
	__call = extern : function(self: Quaternion, ...) -> Quaternion;
})

global typedef Color = Quaternion
global Color = Quaternion

-----------------------------------------

global class Matrix4x4 = extern
