-- Compiled from sol/type.sol at 2013 Sep 16  22:07:43

return <0x017ccc50>{
	-- Types:
	typedef Any = <0x01263358>{
		pre_analyzed: bool?;
		tag:          "any";
	};
	typedef False = <0x013cd948>{
		pre_analyzed: bool?;
		tag:          "false";
	};
	typedef Function = <0x0150d870>{
		args:           [<0x0150d958>{
		                		name: string?;
		                		type: Type?;
		                	}];
		intrinsic_name: string?;
		name:           string;
		pre_analyzed:   bool?;
		rets:           [Type]?;
		tag:            "function";
		vararg:         VarArgs?;
	};
	typedef Identifier = <0x0150efa8>{
		first_usage:  string?;
		name:         string;
		pre_analyzed: bool?;
		scope:        Scope;
		tag:          "identifier";
		type:         Type?;
		var_:         Variable?;
		where:        string;
	};
	typedef Int = <0x011476a0>{
		pre_analyzed: bool?;
		tag:          "int";
	};
	typedef IntLiteral = <0x01146ff0>{
		pre_analyzed: bool?;
		tag:          "int_literal";
		value:        int;
	};
	typedef List = <0x011549c0>{
		pre_analyzed: bool?;
		tag:          "list";
		type:         Type;
	};
	typedef Map = <0x01157cc8>{
		key_type:     Type;
		pre_analyzed: bool?;
		tag:          "map";
		value_type:   Type;
	};
	typedef Nil = <0x005a3e80>{
		pre_analyzed: bool?;
		tag:          "nil";
	};
	typedef Num = <0x01145308>{
		pre_analyzed: bool?;
		tag:          "num";
	};
	typedef NumLiteral = <0x012e4a20>{
		pre_analyzed: bool?;
		tag:          "num_literal";
		value:        number;
	};
	typedef Object = <0x01245900>{
		derived:      [Identifier]?;
		members:      {string => Type};
		metatable:    Object?;
		namespace:    {string => Identifier}?;
		pre_analyzed: bool?;
		tag:          "object";
	};
	typedef String = <0x01147a08>{
		pre_analyzed: bool?;
		tag:          "string";
	};
	typedef StringLiteral = <0x005a2bf8>{
		pre_analyzed: bool?;
		tag:          "string_literal";
		value:        string;
	};
	typedef Table = <0x0114db78>{
		pre_analyzed: bool?;
		tag:          "table";
	};
	typedef True = <0x005b27f8>{
		pre_analyzed: bool?;
		tag:          "true";
	};
	typedef Type = <0x013a2570>{
		pre_analyzed: bool?;
		tag:          TypeID;
	};
	typedef TypeID = "any" or "int_literal" or "num_literal" or "string_literal" or "nil" or "true" or "false" or "int" or "num" or "string" or "table" or "list" or "map" or "object" or "function" or "variant" or "identifier" or "varargs";
	typedef Typelist = [Type];
	typedef VarArgs = <0x0150d1c8>{
		pre_analyzed: bool?;
		tag:          "varargs";
		type:         Type;
	};
	typedef Variant = <0x0150e8a0>{
		pre_analyzed: bool?;
		tag:          "variant";
		variants:     [Type];
	};

	-- Members:
	Any:                   <0x016b36f8>{
	                       	tag: "any";
	                       };
	AnyTypeList:           table;
	Bool:                  <0x016cbce8>{
	                       	tag:      "variant";
	                       	variants: [<0x016bd038>{
	                       	          			tag: "false";
	                       	          		} or <0x016bb700>{
	                       	          			tag: "true";
	                       	          		}];
	                       };
	False:                 <0x016bd038>{
	                       	tag: "false";
	                       };
	Int:                   <0x016c2e98>{
	                       	tag: "int";
	                       };
	List:                  <0x016d37f0>{
	                       	tag:  "list";
	                       	type: <0x016b36f8>{
	                       	      	tag: "any";
	                       	      };
	                       };
	Map:                   <0x016d6e98>{
	                       	key_type:   <0x016b36f8>{
	                       	            	tag: "any";
	                       	            };
	                       	tag:        "map";
	                       	value_type: <0x016b36f8>{
	                       	            	tag: "any";
	                       	            };
	                       };
	Nil:                   <0x016b9918>{
	                       	tag: "nil";
	                       };
	Nilable:               <0x016b36f8>{
	                       	tag: "any";
	                       };
	Num:                   <0x016c14c0>{
	                       	tag: "num";
	                       };
	Object:                <0x016d1028>{
	                       	members: table;
	                       	tag:     "object";
	                       };
	String:                <0x016be9c0>{
	                       	tag: "string";
	                       };
	Table:                 <0x016ce3b0>{
	                       	tag: "table";
	                       };
	True:                  <0x016bb700>{
	                       	tag: "true";
	                       };
	Uint:                  <0x016c2e98>{
	                       	tag: "int";
	                       };
	Void:                  table;
	all_variants:          function(typ: Type) -> function() -> Type?;
	as_type_list:          function(t: Type or [Type]) -> Type or [Type] or [<0x013a2570>{
	                       					pre_analyzed: bool?;
	                       					tag:          TypeID;
	                       				} or [Type]];
	broaden:               function(t: Type?) -> Type?;
	clone_variant:         function(v) -> Variant;
	combine:               function(a: Type, b: Type) -> <0x013a2570>{
	                       		pre_analyzed: bool?;
	                       		tag:          TypeID;
	                       	};
	combine_type_lists:    function(a, b, forgiving: bool?) -> Typelist?;
	could_be:              function(a: Type, b: Type, problem_rope: [string]?) -> true or false or true or false or true or false or true;
	could_be_false:        function(a: Type) -> true or false or true or false or true or false or true;
	could_be_tl:           function(al, bl, problem_rope: [string]?) -> bool;
	could_be_true:         function(a: Type) -> true or false or true or false or true;
	create_empty_table:    function() -> Type;
	extend_variant:        function(v, ... : varargs) -> any;
	extend_variant_one:    function(v: Variant, e: Type) -> Variant;
	find:                  function(t: Type, target: Type) -> <0x013a2570>{
	                       			pre_analyzed: bool?;
	                       			tag:          TypeID;
	                       		}?;
	follow_identifiers:    function(t: Type, forgiving: bool?) -> Type;
	format_type:           function(root: Type, verbose: bool?) -> string;
	from_num_literal:      function(str: string) -> IntLiteral or NumLiteral?;
	from_string_literal:   function(str: string) -> StringLiteral;
	is_any:                function(a: Type) -> any;
	is_atomic:             function(t: Type) -> bool;
	is_bool:               function(a: Type) -> false or true;
	is_class:              function(typ: Object) -> bool;
	is_empty_table:        function(t: Type) -> bool;
	is_instance:           function(typ: Object) -> bool;
	is_integral:           function(str: string) -> bool;
	is_nilable:            function(a: Type) -> bool;
	is_obj_obj:            function(d: Object, b: Object, problem_rope: [string]?) -> bool;
	is_type:               function(x) -> bool;
	is_type_list:          function(list) -> false or true;
	is_useful_boolean:     function(a: Type) -> true or false or true or false or true or false;
	is_variant:            function(v) -> false or true or nil;
	isa:                   function(d: Type, b: Type, problem_rope: [string]?) -> bool;
	isa_raw:               function(d: Type, b: Type, problem_rope: [string]?) -> bool;
	isa_typelists:         function(d: [Type]?, b: [Type]?, problem_rope: [string]?) -> bool;
	make_nilable:          function(a: Type) -> Type;
	make_variant:          function(... : varargs) -> Variant;
	name:                  function(typ: Type or [Type]?, verbose: bool?) -> string;
	name_verbose:          function(typ: Type or [Type]?) -> string;
	names:                 function(typ: [Type], verbose: bool?) -> string;
	on_error:              function(fmt, ... : varargs) -> void;
	should_extend_in_situ: function(typ: Type) -> bool;
	simplify:              function(t: Type) -> Type;
	table_id:              function(t: table) -> string;
	variant:               function(a: Type?, b: Type?) -> Type?;
	variant_remove:        function(t: Type, remove_this_type: Type) -> <0x013a2570>{
	                       		pre_analyzed: bool?;
	                       		tag:          TypeID;
	                       	};
}