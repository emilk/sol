-- Compiled from sol/type.sol at 2013 Sep 17  22:58:25

return <0x017db580>{
	-- Types:
	typedef Any = <0x013d0238>{
		pre_analyzed: bool?;
		tag:          "any";
	};
	typedef False = <0x0133c850>{
		pre_analyzed: bool?;
		tag:          "false";
	};
	typedef Function = <0x007b3b58>{
		args:           [<0x013608c0>{
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
	typedef Identifier = <0x01420e38>{
		first_usage:  string?;
		name:         string;
		pre_analyzed: bool?;
		scope:        Scope;
		tag:          "identifier";
		type:         Type?;
		var_name:     string?;
		where:        string;
	};
	typedef Int = <0x01326480>{
		pre_analyzed: bool?;
		tag:          "int";
	};
	typedef IntLiteral = <0x0107af50>{
		pre_analyzed: bool?;
		tag:          "int_literal";
		value:        int;
	};
	typedef List = <0x01248cf0>{
		pre_analyzed: bool?;
		tag:          "list";
		type:         Type;
	};
	typedef Map = <0x007f9158>{
		key_type:     Type;
		pre_analyzed: bool?;
		tag:          "map";
		value_type:   Type;
	};
	typedef Nil = <0x007c9568>{
		pre_analyzed: bool?;
		tag:          "nil";
	};
	typedef Num = <0x0124a618>{
		pre_analyzed: bool?;
		tag:          "num";
	};
	typedef NumLiteral = <0x010ae410>{
		pre_analyzed: bool?;
		tag:          "num_literal";
		value:        number;
	};
	typedef Object = <0x010b2638>{
		class_type:    Object?;
		derived:       [Identifier]?;
		instance_type: Object?;
		members:       {string => Type};
		metatable:     Object?;
		namespace:     {string => Identifier}?;
		pre_analyzed:  bool?;
		tag:           "object";
	};
	typedef String = <0x010156a8>{
		pre_analyzed: bool?;
		tag:          "string";
	};
	typedef StringLiteral = <0x01465970>{
		pre_analyzed: bool?;
		tag:          "string_literal";
		value:        string;
	};
	typedef Table = <0x006e3870>{
		pre_analyzed: bool?;
		tag:          "table";
	};
	typedef True = <0x004d3cc8>{
		pre_analyzed: bool?;
		tag:          "true";
	};
	typedef Type = <0x01408e98>{
		pre_analyzed: bool?;
		tag:          TypeID;
	};
	typedef TypeID = "any" or "int_literal" or "num_literal" or "string_literal" or "nil" or "true" or "false" or "int" or "num" or "string" or "table" or "list" or "map" or "object" or "function" or "variant" or "identifier" or "varargs";
	typedef Typelist = [Type];
	typedef VarArgs = <0x013ad670>{
		pre_analyzed: bool?;
		tag:          "varargs";
		type:         Type;
	};
	typedef Variant = <0x01249670>{
		pre_analyzed: bool?;
		tag:          "variant";
		variants:     [Type];
	};

	-- Members:
	Any:                   <0x015e4a08>{
	                       	tag: "any";
	                       };
	AnyTypeList:           table;
	Bool:                  <0x015fc920>{
	                       	tag:      "variant";
	                       	variants: [<0x015edcf8>{
	                       	          			tag: "false";
	                       	          		} or <0x015ec240>{
	                       	          			tag: "true";
	                       	          		}];
	                       };
	False:                 <0x015edcf8>{
	                       	tag: "false";
	                       };
	Int:                   <0x015f3d68>{
	                       	tag: "int";
	                       };
	List:                  <0x006cad48>{
	                       	tag:  "list";
	                       	type: <0x015e4a08>{
	                       	      	tag: "any";
	                       	      };
	                       };
	Map:                   <0x01607920>{
	                       	key_type:   <0x015e4a08>{
	                       	            	tag: "any";
	                       	            };
	                       	tag:        "map";
	                       	value_type: <0x015e4a08>{
	                       	            	tag: "any";
	                       	            };
	                       };
	Nil:                   <0x015ea470>{
	                       	tag: "nil";
	                       };
	Nilable:               <0x015e4a08>{
	                       	tag: "any";
	                       };
	Num:                   <0x015f23e0>{
	                       	tag: "num";
	                       };
	Object:                <0x01601ce0>{
	                       	members: table;
	                       	tag:     "object";
	                       };
	String:                <0x015efa60>{
	                       	tag: "string";
	                       };
	Table:                 <0x015fefe8>{
	                       	tag: "table";
	                       };
	True:                  <0x015ec240>{
	                       	tag: "true";
	                       };
	Uint:                  <0x015f3d68>{
	                       	tag: "int";
	                       };
	Void:                  table;
	all_variants:          function(typ: Type) -> function() -> Type?;
	as_type_list:          function(t: Type or [Type]) -> Type or [Type] or [<0x01408e98>{
	                       					pre_analyzed: bool?;
	                       					tag:          TypeID;
	                       				} or [Type]];
	broaden:               function(t: Type?) -> Type?;
	clone_variant:         function(v) -> Variant;
	combine:               function(a: Type, b: Type) -> <0x01408e98>{
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
	find:                  function(t: Type, target: Type) -> <0x01408e98>{
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
	variant_remove:        function(t: Type, remove_this_type: Type) -> <0x01408e98>{
	                       		pre_analyzed: bool?;
	                       		tag:          TypeID;
	                       	};
}