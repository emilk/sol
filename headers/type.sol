-- Compiled from sol/type.sol at 2013 Sep 15  22:21:02

return <table: 0x01844458>{
   -- Types:
   typedef Any = <table: 0x0151a7f0>{
      pre_analyzed: bool?;
      tag:          "any";
   };
   typedef False = <table: 0x0151cbd8>{
      pre_analyzed: bool?;
      tag:          "false";
   };
   typedef Function = <table: 0x01520cf8>{
      args:           [<table: 0x01520de0>{
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
   typedef Identifier = <table: 0x01522430>{
      first_usage:  string?;
      name:         string;
      pre_analyzed: bool?;
      scope:        Scope;
      tag:          "identifier";
      type:         Type?;
      var_:         Variable?;
      where:        string;
   };
   typedef Int = <table: 0x0151d188>{
      pre_analyzed: bool?;
      tag:          "int";
   };
   typedef IntLiteral = <table: 0x0151ada0>{
      pre_analyzed: bool?;
      tag:          "int_literal";
      value:        int;
   };
   typedef List = <table: 0x0151e848>{
      pre_analyzed: bool?;
      tag:          "list";
      type:         Type;
   };
   typedef Map = <table: 0x0151eef0>{
      key_type:     Type;
      pre_analyzed: bool?;
      tag:          "map";
      value_type:   Type;
   };
   typedef Nil = <table: 0x0151c000>{
      pre_analyzed: bool?;
      tag:          "nil";
   };
   typedef Num = <table: 0x0151d738>{
      pre_analyzed: bool?;
      tag:          "num";
   };
   typedef NumLiteral = <table: 0x0151b3c0>{
      pre_analyzed: bool?;
      tag:          "num_literal";
      value:        number;
   };
   typedef Object = <table: 0x0151f710>{
      derived:      [Identifier]?;
      members:      {string => Type};
      metatable:    Object?;
      namespace:    {string => Identifier}?;
      pre_analyzed: bool?;
      tag:          "object";
   };
   typedef String = <table: 0x0151dce8>{
      pre_analyzed: bool?;
      tag:          "string";
   };
   typedef StringLiteral = <table: 0x0151b9e0>{
      pre_analyzed: bool?;
      tag:          "string_literal";
      value:        string;
   };
   typedef Table = <table: 0x0151e298>{
      pre_analyzed: bool?;
      tag:          "table";
   };
   typedef True = <table: 0x0151c5b0>{
      pre_analyzed: bool?;
      tag:          "true";
   };
   typedef Type = <table: 0x01519d20>{
      pre_analyzed: bool?;
      tag:          TypeID;
   };
   typedef TypeID = "any" or "int_literal" or "num_literal" or "string_literal" or "nil" or "true" or "false" or "int" or "num" or "string" or "table" or "list" or "map" or "object" or "function" or "variant" or "identifier" or "varargs";
   typedef Typelist = [Type];
   typedef VarArgs = <table: 0x01520650>{
      pre_analyzed: bool?;
      tag:          "varargs";
      type:         Type;
   };
   typedef Variant = <table: 0x01521d28>{
      pre_analyzed: bool?;
      tag:          "variant";
      variants:     [Type];
   };

   -- Members:
   Any:                   <table: 0x0170a750>{
      tag: "any";
   };
   AnyTypeList:           table;
   Bool:                  object;
   Empty:                 object;
   False:                 object;
   Int:                   object;
   List:                  object;
   Map:                   object;
   Nil:                   object;
   Nilable:               <table: 0x0170a750>{
      tag: "any";
   };
   Num:                   object;
   Object:                object;
   String:                object;
   Table:                 object;
   True:                  object;
   Uint:                  object;
   Void:                  table;
   all_variants:          function(typ: Type) -> function() -> Type?;
   as_type_list:          function(t: Type or [Type]) -> Type or [Type] or [<table: 0x01519d20>{
                  pre_analyzed: bool?;
                  tag:          TypeID;
               } or [Type]];
   broaden:               function(t: Type?) -> Type?;
   clone_variant:         function(v) -> Variant;
   combine:               function(a: Type, b: Type) -> { };
   combine_type_lists:    function(a, b, forgiving: bool?) -> Typelist?;
   could_be:              function(a: Type, b: Type, problem_rope: [string]?) -> true or false or true or false or true or false or true;
   could_be_false:        function(a: Type) -> true or false or true or false or true or false or true;
   could_be_tl:           function(al, bl, problem_rope: [string]?) -> bool;
   could_be_true:         function(a: Type) -> true or false or true or false or true;
   create_empty_table:    function() -> Type;
   extend_variant:        function(v, ... : varargs) -> any;
   extend_variant_one:    function(v: Variant, e: Type) -> Variant;
   find:                  function(t: Type, target: Type) -> <table: 0x01519d20>{
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
   name_old:              function(typ: Type or [Type]?, indent: string?, verbose: bool?) -> string;
   name_verbose:          function(typ: Type or [Type]?) -> string;
   names:                 function(typ: [Type], verbose: bool?) -> string;
   on_error:              function(fmt, ... : varargs) -> void [EMPTY TYPE-LIST];
   should_extend_in_situ: function(typ: Type) -> bool;
   simplify:              function(t: Type) -> Type;
   variant:               function(a: Type?, b: Type?) -> Type?;
   variant_remove:        function(t: Type, remove_this_type: Type) -> <table: 0x01519d20>{
         pre_analyzed: bool?;
         tag:          TypeID;
      };
}