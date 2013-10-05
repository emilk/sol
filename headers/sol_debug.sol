-- Compiled from sol/sol_debug.sol on 2013 Oct 05  09:10:14

return {
	activate: function() -> void;
	active:   false;
	assert:   function(bool_expr, fmt: string?, ... : any) -> void;
	break_:   function() -> void;
	error:    function(msg: string) -> void;
	get_lib:  function() -> any;
}