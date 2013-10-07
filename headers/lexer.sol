-- Compiled from sol/lexer.sol on 2013 Oct 07  13:10:51

return {
	-- Types:
	typedef Token = Token;
	typedef TokenList = [Token];

	-- Members:
	lex_sol: function(src: string, filename: string, settings) -> bool, any;
}