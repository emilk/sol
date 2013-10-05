-- Compiled from sol/util.sol on 2013 Oct 05  22:23:19

return {
	INDENTATION:       "\9";
	const:             function(table: table) -> object;
	count_line_breaks: function(str: string) -> int;
	ellipsis:          function(msg: string, max_len: int?) -> string;
	file_exists:       function(path: string) -> bool;
	indent:            function(str: string) -> string;
	is_array:          function(val) -> bool;
	list_concat:       function(a: [any], b: [any]) -> [any];
	list_join:         function(out: [any], in_table: [any]) -> void;
	make_const:        function(table: table) -> void;
	pretty:            function(arg) -> string;
	printf:            function(fmt: string, ... : any) -> void;
	printf_err:        function(fmt: string, ... : any) -> void;
	quote_or_indent:   function(str: string) -> string;
	read_entire_file:  function(path: string) -> string?;
	read_entire_stdin: function() -> string?;
	serialize:         function(val, ignore_set) -> string;
	serialize_to_rope: function(rope, val, ignore_set, indent: string?, discovered: {table}?) -> void;
	set:               function(tb: [string]) -> {string};
	shallow_clone:     function(t: table?) -> table?;
	table_clear:       function(t: table) -> void;
	table_empty:       function(t: table) -> bool;
	trim:              function(str: string) -> string;
	write_file:        function(path: string, contents: string) -> bool;
	write_protect:     function(path: string) -> bool;
	write_unprotect:   function(path: string) -> bool;
}