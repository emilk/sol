-- Compiled from sol/lexer.sol on 2013 Oct 02  20:09:51

return {
	-- Types:
	typedef Token = Token;
	typedef TokenList = [Token];

	-- Members:
	lex_sol: function(src: string, filename: string, settings) -> bool, any;
}