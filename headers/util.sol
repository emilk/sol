-- Compiled from sol/util.sol at 2013 Sep 15  18:52:24

return {
   const:             function(table: table) -> object;
   ellipsis:          function(msg: string, max_len: int?) -> string;
   file_exists:       function(path: string) -> bool;
   indent:            function(str: string) -> string;
   is_array:          function(val) -> bool;
   list_concat:       function(a: [any], b: [any]) -> [any];
   list_join:         function(out: [any], in_table: [any]) -> void [EMPTY TYPE-LIST];
   make_const:        function(table: object) -> void [EMPTY TYPE-LIST];
   pretty:            function(arg) -> string;
   printf:            function(fmt: string, ... : varargs) -> void [EMPTY TYPE-LIST];
   printf_err:        function(fmt: string, ... : varargs) -> void [EMPTY TYPE-LIST];
   quote_or_indent:   function(str: string) -> string;
   read_entire_file:  function(path: string) -> string?;
   read_entire_stdin: function() -> string?;
   serialize:         function(val, ignore_set) -> string;
   serialize_to_rope: function(rope, val, ignore_set, indent: string?, discovered: {table}?) -> void [EMPTY TYPE-LIST];
   set:               function(tb: [string]) -> {string};
   shallow_clone:     function(t: table?) -> table?;
   table_clear:       function(t: table) -> void [EMPTY TYPE-LIST];
   table_empty:       function(t: table) -> bool;
   trim:              function(str: string) -> string;
   write_file:        function(path: string, contents: string) -> bool;
   write_protect:     function(path: string) -> bool;
   write_unprotect:   function(path: string) -> bool;
}