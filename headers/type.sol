-- Compiled from sol/type.sol

return {
	-- Types:
	typedef Any = {
		pre_analyzed: bool?;
		tag:          'any';
		where:        string?;
	};
	typedef Extern = {
		name:         string?;
		pre_analyzed: bool?;
		tag:          'extern';
		where:        string;
	};
	typedef False = {
		pre_analyzed: bool?;
		tag:          'false';
		where:        string?;
	};
	typedef Function = {
		args:           [{ name: string?;  type: Type?; }];
		intrinsic_name: string?;
		name:           string;
		pre_analyzed:   bool?;
		rets:           [Type]?;
		tag:            'function';
		vararg:         VarArgs?;
		where:          string?;
	};
	typedef Identifier = {
		first_usage:  string?;
		name:         string;
		pre_analyzed: bool?;
		scope:        Scope;
		tag:          'identifier';
		type:         Type?;
		var_name:     string?;
		where:        string;
	};
	typedef Int = {
		pre_analyzed: bool?;
		tag:          'int';
		where:        string?;
	};
	typedef IntLiteral = {
		pre_analyzed: bool?;
		tag:          'int_literal';
		value:        int;
		where:        string?;
	};
	typedef List = {
		pre_analyzed: bool?;
		tag:          'list';
		type:         Type;
		where:        string?;
	};
	typedef Map = {
		key_type:     Type;
		pre_analyzed: bool?;
		tag:          'map';
		value_type:   Type;
		where:        string?;
	};
	typedef Nil = {
		pre_analyzed: bool?;
		tag:          'nil';
		where:        string?;
	};
	typedef Num = {
		pre_analyzed: bool?;
		tag:          'number';
		where:        string?;
	};
	typedef NumLiteral = {
		pre_analyzed: bool?;
		tag:          'num_literal';
		value:        number;
		where:        string?;
	};
	typedef Object = {
		class_type:    Object?;
		derived:       [Identifier]?;
		instance_type: Object?;
		members:       {string => Type};
		metatable:     Object?;
		namespace:     {string => Identifier}?;
		pre_analyzed:  bool?;
		tag:           'object';
		where:         string?;
	};
	typedef String = {
		pre_analyzed: bool?;
		tag:          'string';
		where:        string?;
	};
	typedef StringLiteral = {
		pre_analyzed: bool?;
		str_contents: string;
		str_quoted:   string;
		tag:          'string_literal';
		where:        string?;
	};
	typedef Table = {
		pre_analyzed: bool?;
		tag:          'table';
		where:        string?;
	};
	typedef True = {
		pre_analyzed: bool?;
		tag:          'true';
		where:        string?;
	};
	typedef Type = {
		pre_analyzed: bool?;
		tag:          TypeID;
		where:        string?;
	};
	typedef TypeID = 'any' or 'int_literal' or 'num_literal' or 'string_literal' or 'nil' or 'true' or 'false' or 'int' or 'number' or 'string' or 'table' or 'list' or 'map' or 'object' or 'function' or 'variant' or 'identifier' or 'varargs' or 'extern';
	typedef Typelist = [Type];
	typedef VarArgs = {
		pre_analyzed: bool?;
		tag:          'varargs';
		type:         Type;
		where:        string?;
	};
	typedef Variant = {
		pre_analyzed: bool?;
		tag:          'variant';
		variants:     [Type];
		where:        string?;
	};

	-- Members:
	Any:                   { tag: 'any'; };
	AnyTypeList:           table;
	Bool:                  {
	                       	tag:      'variant';
	                       	variants: [{ tag: 'true'; } or { tag: 'false'; }];
	                       };
	False:                 { tag: 'false'; };
	Int:                   { tag: 'int'; };
	List:                  { tag: 'list';  type: { tag: 'any'; }; };
	Map:                   {
	                       	key_type:   { tag: 'any'; };
	                       	tag:        'map';
	                       	value_type: { tag: 'any'; };
	                       };
	Nil:                   { tag: 'nil'; };
	Nilable:               { tag: 'any'; };
	Num:                   { tag: 'number'; };
	Object:                { members: table;  tag: 'object'; };
	String:                { tag: 'string'; };
	Table:                 { tag: 'table'; };
	True:                  { tag: 'true'; };
	Uint:                  { tag: 'int'; };
	Void:                  table;
	_empty_table:          { tag: 'table'; };
	all_variants:          function(typ: Type) -> function() -> Type?;
	broaden:               function(t: Type?) -> Type?;
	broaden_non_nil:       function(t: Type) -> Type;
	clone_variant:         function(v: Variant) -> Variant;
	combine_num_int:       function(a: Type, b: Type) -> Num or Int;
	combine_type_lists:    function(a: Typelist?, b: Typelist?, forgiving: bool?) -> Typelist?;
	could_be:              function(d: Type, b: Type, problem_rope: [string]?) -> bool;
	could_be_raw:          function(a: Type, b: Type, problem_rope: [string]?) -> bool;
	could_be_tl:           function(al: Typelist, bl: Typelist, problem_rope: [string]?) -> bool;
	could_be_true_false:   function(a: Type) -> bool, bool;
	create_empty_table:    function() -> Type;
	extend_variant:        function(v: Variant, ... : any) -> Variant;
	extend_variant_one:    function(v: Variant, e: Type) -> Variant;
	find_meta_method:      function(t: Type, name: string) -> Type?;
	follow_identifiers:    function(t: Type, forgiving: bool?) -> Type;
	format_type:           function(root: Type, verbosity: Verbosity) -> string;
	from_num_literal:      function(str: string) -> IntLiteral or NumLiteral?;
	from_string_literal:   function(str: string) -> StringLiteral;
	has_tag:               function(t: Type, target: string) -> bool;
	is_any:                function(a: Type) -> bool;
	is_atomic:             function(t: Type) -> bool;
	is_bool:               function(a: Type) -> bool;
	is_class:              function(typ: Object) -> bool;
	is_empty_table:        function(t: Type) -> bool;
	is_instance:           function(typ: Object) -> bool;
	is_integral:           function(str: string) -> bool;
	is_nilable:            function(a: Type) -> bool;
	is_obj_obj:            function(d: Object, b: Object, problem_rope: [string]?) -> bool;
	is_table:              function(t: Type) -> bool;
	is_type:               function(x) -> bool;
	is_type_list:          function(list) -> bool;
	is_variant:            function(t: Type) -> Variant?;
	is_void:               function(ts: Typelist) -> bool;
	isa:                   function(d: Type, b: Type, problem_rope: [string]?) -> bool;
	isa_raw:               function(d: Type, b: Type, problem_rope: [string]?) -> bool;
	isa_typelists:         function(d: [Type]?, b: [Type]?, problem_rope: [string]?) -> bool;
	make_nilable:          function(a: Type) -> Type;
	make_variant:          function(... : any) -> Variant;
	name:                  function(typ: Type or [Type]?, verbosity: 'verbose' or 'concise'?) -> string;
	names:                 function(typ: [Type], verbosity: 'verbose' or 'concise'?) -> string;
	on_error:              function(fmt, ... : any) -> void;
	should_extend_in_situ: function(typ: Type) -> bool;
	simplify:              function(t: Type) -> Type;
	table_id:              function(t: table) -> string;
	variant:               function(a: Type?, b: Type?) -> Type?;
	variant_has:           function(v: Variant, e: Type) -> bool;
	variant_remove:        function(t: Type, remove_this_type: Type) -> Type;
	visit:                 function(t: Type, lambda: function(: Type) -> void) -> void;
	visit_and_combine:     function(t: Type, lambda: function(: Type) -> Type?) -> Type?;
}