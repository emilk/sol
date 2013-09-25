
----------------------------------------------------------------------------------
-- Namespaces: 

global Actor       = { }
global Application = { }
global Camera      = { }
global Gui         = { }
global Keyboard    = { }
global Light       = { }
global Material    = { }
global Math        = { }
global Mesh        = { }
global Profiler    = { }
global Script      = { }
global Unit        = { }
global World       = { }


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
	--__index = extern : function(Vector3, 'x' or 'y' or 'z') -> number;
	__index = extern : { x: number, y: number, z: number }
})

-----------------------------------------

global Vector2 = extern : function(number, number) -> Vector3

-----------------------------------------

global class Quaternion = extern

Quaternion.to_elements   = extern : function(Quaternion)->number,number,number,number
Quaternion.from_elements = extern : function(number,number,number,number)->Quaternion
Quaternion.multiply      = extern : function(Quaternion,Quaternion)->Quaternion
Quaternion.axis_angle    = extern : function(Vector3,number)->Quaternion

setmetatable(Quaternion, {
	__call  = extern : function(Quaternion, ...) -> Quaternion;
	--__index = extern : function(Quaternion, 'x' or 'y' or 'z' or 'w') -> number;
	__index = extern : { x: number, y: number, z: number, w: number }
})

global typedef Color = Quaternion
global Color = Quaternion

-----------------------------------------

global class Matrix4x4 = extern
