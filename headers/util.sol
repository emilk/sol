-- Compiled from sol/util.sol

return {
	INDENTATION:        '\t';
	const:              function(table: table) -> object;
	count_line_breaks:  function(str: string) -> int;
	ellipsis:           function(msg: string, max_len: int?) -> string;
	escape:             function(str: string) -> string;
	file_exists:        function(path: string) -> bool;
	indent:             function(str: string) -> string;
	is_array:           function(val) -> bool;
	is_constant_name:   function(name: string) -> bool;
	list_concat:        function(a: [any], b: [any]) -> [any];
	list_join:          function(out: [any], in_table: [any]) -> void;
	make_const:         function(table: table) -> void;
	pretty:             function(arg) -> string;
	print_sorted_stats: function(map: {string => number}) -> void;
	printf:             function(fmt: string, ... : any) -> void;
	printf_err:         function(fmt: string, ... : any) -> void;
	quote_or_indent:    function(str: string) -> string;
	read_entire_file:   function(path: string) -> string?;
	read_entire_stdin:  function() -> string?;
	serialize:          function(val, ignore_set: {any}?) -> string;
	serialize_to_rope:  function(rope: [string], val, ignore_set: {any}?, indent: string?, discovered: {table}?) -> void;
	set:                function(tb: [string]) -> {string};
	set_join:           function(... : {string}) -> {string};
	shallow_clone:      function(t: table?) -> table?;
	table_clear:        function(t: table) -> void;
	table_empty:        function(t: table) -> bool;
	trim:               function(str: string) -> string;
	unescape:           function(str: string) -> string;
	write_file:         function(path: string, contents: string) -> bool;
	write_protect:      function(path: string) -> bool;
	write_unprotect:    function(path: string) -> bool;
}