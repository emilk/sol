
----------------------------------------------------------------------------------
-- Namespaces: 

global Application = { }
global Script      = { }
global Material    = { }
global Math        = { }
global Mesh        = { }
global Unit        = { }
global Profiler    = { }


----------------------------------------------------------------------------------
-- Types:

global class Vector3 = extern

Vector3.zero           = extern : function()->Vector3
Vector3.up             = extern : function()->Vector3
Vector3.length         = extern : function(Vector3)->number
Vector3.length_squared = extern : function(Vector3)->number
Vector3.normalize      = extern : function(Vector3)->Vector3
Vector3.to_elements    = extern : function(Vector3)->number,number,number
Vector3.lerp           = extern : function(Vector3,Vector3,number)->Vector3
Vector3.dot            = extern : function(Vector3,Vector3)->number

setmetatable(Vector3, {
	__call  = extern : function(Vector3, x: number, y: number, z: number) -> Vector3;
	__index = extern : function(Vector3, 'x' or 'y' or 'z') -> number;
})

-----------------------------------------

global class Quaternion = extern

Quaternion.to_elements   = extern : function(Quaternion)->number,number,number,number
Quaternion.from_elements = extern : function(number,number,number,number)->Quaternion
Quaternion.multiply      = extern : function(Quaternion,Quaternion)->Quaternion
Quaternion.axis_angle    = extern : function(Vector3,number)->Quaternion

setmetatable(Quaternion, {
	__call  = extern : function(Quaternion, ...) -> Quaternion;
	__index = extern : function(Quaternion, 'x' or 'y' or 'z' or 'w') -> number;
})

global typedef Color = Quaternion
global Color = Quaternion

-----------------------------------------

global class Matrix4x4 = extern
