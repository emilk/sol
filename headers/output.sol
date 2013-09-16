-- Compiled from sol/output.sol at 2013 Sep 16  22:23:02

global typedef Variable = <0x0131f920>{
	is_global:  bool;
	name:       string;
	namespace:  {string => Type}?;
	references: int;
	scope:      Scope;
	type:       Type?;
	where:      string;
}

global typedef Scope = <instance><0x018686c8>{
	children:        [Scope]?;
	fixed:           true?;
	global_typedefs: {string => Type}?;
	globals:         [Variable]?;
	locals:          [Variable]?;
	parent:          Scope?;
	typedefs:        {string => Type}?;
	vararg:          Variable?;

	!! class_type:    <class><0x01868640>{
		add_global:          (function(self, v) -> void) or nil;
		add_global_type:     (function(self, name: string, typ: Type) -> void) or nil;
		create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
		create_global_scope: (function() -> Scope) or nil;
		create_local:        (function(self, name: string, where: string) -> Variable) or nil;
		create_module_scope: (function() -> Scope) or nil;
		declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void) or nil;
		get_global:          (function(self, name: string) -> Variable?) or nil;
		get_global_scope:    (function() -> Scope) or nil;
		get_global_type:     (function(self, name: string) -> Type?) or nil;
		get_global_typedefs: (function(self, list: [Variable]?) -> [Variable]) or nil;
		get_global_vars:     (function(self, list: [Variable]?) -> [Variable]) or nil;
		get_local:           (function(self, name: string) -> Variable?) or nil;
		get_local_type:      (function(self, name: string) -> Type?) or nil;
		get_scoped:          (function(self, name: string) -> Variable?) or nil;
		get_scoped_global:   (function(self, name: string) -> Variable?) or nil;
		get_scoped_type:     (function(self, name: string) -> Type?) or nil;
		get_scoped_var:      (function(self, name: string) -> Variable?) or nil;
		get_type:            (function(self, name: string) -> Type?) or nil;
		get_var:             (function(self, name: string) -> Variable?) or nil;
		get_var_args:        (function(self) -> Type?) or nil;
		global_scope:        any;
		init:                (function(self, parent: Scope?) -> void) or nil;
		is_module_level:     (function(self) -> bool) or nil;
		new:                 (function(parent: Scope?) -> Scope) or nil;

		!! instance_type: <RECURSION 0x018686c8>
	}
}

global Scope : <class><0x01868640>{
	add_global:          (function(self, v) -> void) or nil;
	add_global_type:     (function(self, name: string, typ: Type) -> void) or nil;
	create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
	create_global_scope: (function() -> Scope) or nil;
	create_local:        (function(self, name: string, where: string) -> Variable) or nil;
	create_module_scope: (function() -> Scope) or nil;
	declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void) or nil;
	get_global:          (function(self, name: string) -> Variable?) or nil;
	get_global_scope:    (function() -> Scope) or nil;
	get_global_type:     (function(self, name: string) -> Type?) or nil;
	get_global_typedefs: (function(self, list: [Variable]?) -> [Variable]) or nil;
	get_global_vars:     (function(self, list: [Variable]?) -> [Variable]) or nil;
	get_local:           (function(self, name: string) -> Variable?) or nil;
	get_local_type:      (function(self, name: string) -> Type?) or nil;
	get_scoped:          (function(self, name: string) -> Variable?) or nil;
	get_scoped_global:   (function(self, name: string) -> Variable?) or nil;
	get_scoped_type:     (function(self, name: string) -> Type?) or nil;
	get_scoped_var:      (function(self, name: string) -> Variable?) or nil;
	get_type:            (function(self, name: string) -> Type?) or nil;
	get_var:             (function(self, name: string) -> Variable?) or nil;
	get_var_args:        (function(self) -> Type?) or nil;
	global_scope:        any;
	init:                (function(self, parent: Scope?) -> void) or nil;
	is_module_level:     (function(self) -> bool) or nil;
	new:                 (function(parent: Scope?) -> Scope) or nil;

	!! instance_type: <instance><0x018686c8>{
		children:        [Scope]?;
		fixed:           true?;
		global_typedefs: {string => Type}?;
		globals:         [Variable]?;
		locals:          [Variable]?;
		parent:          Scope?;
		typedefs:        {string => Type}?;
		vararg:          Variable?;

		!! class_type:    <RECURSION 0x01868640>
	}
}

return function(ast, filename: string, insert_new_lines: bool?) -> string