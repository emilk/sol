-- Compiled from sol/lua_intrinsics.sol at 2013 Sep 25  21:46:56

global typedef Variable = <0x0128fbf0>{
	forward_declared: bool?;
	is_global:        bool;
	name:             string;
	namespace:        {string => Type}?;
	num_reads:        int;
	num_writes:       int;
	scope:            Scope;
	type:             Type?;
	where:            string;
}

global typedef Scope = <instance><0x012e2ba8>{
	children:        any;
	fixed:           any;
	global_typedefs: any;
	globals:         any;
	locals:          any;
	parent:          any;
	typedefs:        any;
	vararg:          any;
	where:           any;

	!! class_type:    <class><0x012e2b20>{
		add_global:          (function(self, v) -> void) or nil;
		add_global_type:     (function(self, name: string, typ: Type) -> void) or nil;
		create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
		create_global_scope: (function() -> Scope) or nil;
		create_local:        (function(self, name: string, where: string) -> Variable) or nil;
		create_module_scope: (function() -> Scope) or nil;
		declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void) or nil;
		get_global:          (function(self, name: string, options: VarOptions) -> Variable?) or nil;
		get_global_scope:    (function() -> Scope) or nil;
		get_global_type:     (function(self, name: string) -> Type?) or nil;
		get_global_typedefs: (function(self) -> {string => Type}) or nil;
		get_global_vars:     (function(self, list: [Variable]?) -> [Variable]) or nil;
		get_local:           (function(self, name: string, options: VarOptions) -> Variable?) or nil;
		get_local_type:      (function(self, name: string) -> Type?) or nil;
		get_scoped:          (function(self, name: string, options: VarOptions) -> Variable?) or nil;
		get_scoped_global:   (function(self, name: string, options: VarOptions) -> Variable?) or nil;
		get_scoped_type:     (function(self, name: string) -> Type?) or nil;
		get_scoped_var:      (function(self, name: string, options: VarOptions) -> Variable?) or nil;
		get_type:            (function(self, name: string) -> Type?) or nil;
		get_var:             (function(self, name: string, options: VarOptions) -> Variable?) or nil;
		global_scope:        any;
		init:                (function(self, where: string, parent: Scope?) -> void) or nil;
		is_module_level:     (function(self) -> bool) or nil;
		locals_iterator:     (function(self) -> function(... : varargs) -> int, any) or nil;
		new:                 (function(where: string, parent: Scope?) -> Scope) or nil;

		!! instance_type: <RECURSION 0x012e2ba8>
	}
}

global Scope : <class><0x012e2b20>{
	add_global:          (function(self, v) -> void) or nil;
	add_global_type:     (function(self, name: string, typ: Type) -> void) or nil;
	create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
	create_global_scope: (function() -> Scope) or nil;
	create_local:        (function(self, name: string, where: string) -> Variable) or nil;
	create_module_scope: (function() -> Scope) or nil;
	declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void) or nil;
	get_global:          (function(self, name: string, options: VarOptions) -> Variable?) or nil;
	get_global_scope:    (function() -> Scope) or nil;
	get_global_type:     (function(self, name: string) -> Type?) or nil;
	get_global_typedefs: (function(self) -> {string => Type}) or nil;
	get_global_vars:     (function(self, list: [Variable]?) -> [Variable]) or nil;
	get_local:           (function(self, name: string, options: VarOptions) -> Variable?) or nil;
	get_local_type:      (function(self, name: string) -> Type?) or nil;
	get_scoped:          (function(self, name: string, options: VarOptions) -> Variable?) or nil;
	get_scoped_global:   (function(self, name: string, options: VarOptions) -> Variable?) or nil;
	get_scoped_type:     (function(self, name: string) -> Type?) or nil;
	get_scoped_var:      (function(self, name: string, options: VarOptions) -> Variable?) or nil;
	get_type:            (function(self, name: string) -> Type?) or nil;
	get_var:             (function(self, name: string, options: VarOptions) -> Variable?) or nil;
	global_scope:        any;
	init:                (function(self, where: string, parent: Scope?) -> void) or nil;
	is_module_level:     (function(self) -> bool) or nil;
	locals_iterator:     (function(self) -> function(... : varargs) -> int, any) or nil;
	new:                 (function(where: string, parent: Scope?) -> Scope) or nil;

	!! instance_type: <instance><0x012e2ba8>{
		children:        any;
		fixed:           any;
		global_typedefs: any;
		globals:         any;
		locals:          any;
		parent:          any;
		typedefs:        any;
		vararg:          any;
		where:           any;

		!! class_type:    <RECURSION 0x012e2b20>
	}
}

return <0x024a6af0>{
	add_intrinsics_to_global_scope: function() -> void;
}