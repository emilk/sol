-- Compiled from sol/lexer.sol on 2013 Oct 07  15:32:13

return {
	-- Types:
	typedef Token = Token;
	typedef TokenList = [Token];

	-- Members:
	lex_sol: function(src: string, filename: string, settings) -> bool, any;
}