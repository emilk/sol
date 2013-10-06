-- Compiled from sol/sol_debug.sol on 2013 Oct 06  11:22:19

return {
	activate: function() -> void;
	active:   false;
	assert:   function(bool_expr, fmt: string?, ... : any) -> void;
	break_:   function() -> void;
	error:    function(msg: string) -> void;
	get_lib:  function() -> any;
}