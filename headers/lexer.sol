-- Compiled from sol/lexer.sol at 2013 Sep 15  18:52:23

return {
   -- Types:
   typedef Token = Token;
   typedef TokenList = [Token];

   -- Members:
   lex_sol: function(src: string, filename: string, settings) -> bool, any;
}