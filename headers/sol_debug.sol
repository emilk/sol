-- Compiled from sol/sol_debug.sol on 2013 Oct 07  15:54:27

return {
	activate: function() -> void;
	active:   false;
	assert:   function(bool_expr, fmt: string?, ... : any) -> void;
	break_:   function() -> void;
	error:    function(msg: string) -> void;
	get_lib:  function() -> any;
}