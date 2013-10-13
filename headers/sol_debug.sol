-- Compiled from sol/sol_debug.sol on 2013 Oct 13  22:16:08

return {
	activate: function() -> void;
	active:   false;
	assert:   function(bool_expr, fmt: string?, ... : any) -> any;
	break_:   function() -> void;
	error:    function(msg: string) -> void;
	get_lib:  function() -> any;
}