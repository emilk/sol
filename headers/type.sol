-- Compiled from sol/type.sol on 2013 Sep 27  15:55:40

return <0x01a68fe0>{
	-- Types:
	typedef Any = <0x0161a4c8>{
		pre_analyzed: bool?;
		tag:          "any";
		where:        string?;
	};
	typedef False = <0x0161cc98>{
		pre_analyzed: bool?;
		tag:          "false";
		where:        string?;
	};
	typedef Function = <0x01621188>{
		args:           [<0x01621270>{
		                		name: string?;
		                		type: Type?;
		                	}];
		intrinsic_name: string?;
		name:           string;
		pre_analyzed:   bool?;
		rets:           [Type]?;
		tag:            "function";
		vararg:         VarArgs?;
		where:          string?;
	};
	typedef Identifier = <0x016228c0>{
		first_usage:  string?;
		name:         string;
		pre_analyzed: bool?;
		scope:        Scope;
		tag:          "identifier";
		type:         Type?;
		var_name:     string?;
		where:        string;
	};
	typedef Int = <0x0161d2c0>{
		pre_analyzed: bool?;
		tag:          "int";
		where:        string?;
	};
	typedef IntLiteral = <0x0161aed8>{
		pre_analyzed: bool?;
		tag:          "int_literal";
		value:        int;
		where:        string?;
	};
	typedef List = <0x0161e980>{
		pre_analyzed: bool?;
		tag:          "list";
		type:         Type;
		where:        string?;
	};
	typedef Map = <0x0161f028>{
		key_type:     Type;
		pre_analyzed: bool?;
		tag:          "map";
		value_type:   Type;
		where:        string?;
	};
	typedef Nil = <0x0161c138>{
		pre_analyzed: bool?;
		tag:          "nil";
		where:        string?;
	};
	typedef Num = <0x0161d870>{
		pre_analyzed: bool?;
		tag:          "number";
		where:        string?;
	};
	typedef NumLiteral = <0x0161b4f8>{
		pre_analyzed: bool?;
		tag:          "num_literal";
		value:        number;
		where:        string?;
	};
	typedef Object = <0x0161f848>{
		class_type:    Object?;
		derived:       [Identifier]?;
		instance_type: Object?;
		members:       {string => Type};
		metatable:     Object?;
		namespace:     {string => Identifier}?;
		pre_analyzed:  bool?;
		tag:           "object";
		where:         string?;
	};
	typedef String = <0x0161de20>{
		pre_analyzed: bool?;
		tag:          "string";
		where:        string?;
	};
	typedef StringLiteral = <0x0161bb18>{
		pre_analyzed: bool?;
		tag:          "string_literal";
		value:        string;
		where:        string?;
	};
	typedef Table = <0x0161e3d0>{
		pre_analyzed: bool?;
		tag:          "table";
		where:        string?;
	};
	typedef True = <0x0161c6e8>{
		pre_analyzed: bool?;
		tag:          "true";
		where:        string?;
	};
	typedef Type = <0x01619810>{
		pre_analyzed: bool?;
		tag:          TypeID;
		where:        string?;
	};
	typedef TypeID = "any" or "int_literal" or "num_literal" or "string_literal" or "nil" or "true" or "false" or "int" or "number" or "string" or "table" or "list" or "map" or "object" or "function" or "variant" or "identifier" or "varargs";
	typedef Typelist = [Type];
	typedef VarArgs = <0x01620ae0>{
		pre_analyzed: bool?;
		tag:          "varargs";
		type:         Type;
		where:        string?;
	};
	typedef Variant = <0x016221b8>{
		pre_analyzed: bool?;
		tag:          "variant";
		variants:     [Type];
		where:        string?;
	};

	-- Members:
	Any:                   <0x017d68d8>{
	                       	tag: "any";
	                       };
	AnyTypeList:           table;
	Bool:                  <0x017ef118>{
	                       	tag:      "variant";
	                       	variants: [<0x017dfeb0>{
	                       	          			tag: "false";
	                       	          		} or <0x017de520>{
	                       	          			tag: "true";
	                       	          		}];
	                       };
	False:                 <0x017dfeb0>{
	                       	tag: "false";
	                       };
	Int:                   <0x017e63e8>{
	                       	tag: "int";
	                       };
	List:                  <0x017f6f20>{
	                       	tag:  "list";
	                       	type: <0x017d68d8>{
	                       	      	tag: "any";
	                       	      };
	                       };
	Map:                   <0x017fa070>{
	                       	key_type:   <0x017d68d8>{
	                       	            	tag: "any";
	                       	            };
	                       	tag:        "map";
	                       	value_type: <0x017d68d8>{
	                       	            	tag: "any";
	                       	            };
	                       };
	Nil:                   <0x017dc950>{
	                       	tag: "nil";
	                       };
	Nilable:               <0x017d68d8>{
	                       	tag: "any";
	                       };
	Num:                   <0x017e49e8>{
	                       	tag: "number";
	                       };
	Object:                <0x017f3fa0>{
	                       	members: table;
	                       	tag:     "object";
	                       };
	String:                <0x017e1aa8>{
	                       	tag: "string";
	                       };
	Table:                 <0x017f1858>{
	                       	tag: "table";
	                       };
	True:                  <0x017de520>{
	                       	tag: "true";
	                       };
	Uint:                  <0x017e63e8>{
	                       	tag: "int";
	                       };
	Void:                  table;
	all_variants:          function(typ: Type) -> function() -> Type?;
	as_type_list:          function(t: Type or [Type]) -> Type or [Type] or [<0x01619810>{
	                       					pre_analyzed: bool?;
	                       					tag:          TypeID;
	                       					where:        string?;
	                       				} or [Type]];
	broaden:               function(t: Type?) -> Type?;
	clone_variant:         function(v) -> Variant;
	combine:               function(a: Type, b: Type) -> <0x01619810>{
	                       		pre_analyzed: bool?;
	                       		tag:          TypeID;
	                       		where:        string?;
	                       	};
	combine_type_lists:    function(a, b, forgiving: bool?) -> Typelist?;
	could_be:              function(a: Type, b: Type, problem_rope: [string]?) -> true or false or true or false or true or false or true;
	could_be_false:        function(a: Type) -> true or false or true or false or true or false or true;
	could_be_tl:           function(al: Typelist, bl: Typelist, problem_rope: [string]?) -> bool;
	could_be_true:         function(a: Type) -> true or false or true or false or true;
	create_empty_table:    function() -> Type;
	extend_variant:        function(v, ... : varargs) -> any;
	extend_variant_one:    function(v: Variant, e: Type) -> Variant;
	find:                  function(t: Type, target: Type) -> <0x01619810>{
	                       			pre_analyzed: bool?;
	                       			tag:          TypeID;
	                       			where:        string?;
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
	variant_remove:        function(t: Type, remove_this_type: Type) -> <0x01619810>{
	                       		pre_analyzed: bool?;
	                       		tag:          TypeID;
	                       		where:        string?;
	                       	};
}