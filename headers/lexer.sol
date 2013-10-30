-- Compiled from sol/lexer.sol

return {
	-- Types:
	typedef Token = Token;
	typedef TokenList = [Token];

	-- Members:
	lex_sol:     function(src: string, filename: string, settings) -> bool, any;
	print_stats: function() -> void;
}