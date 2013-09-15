-- Compiled from sol/parser.sol
{
   -- Types:
   typedef ExprNode = {
      ast_type: ExprType;
      tokens:   [Token];
      where:    string;
   };
   typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
   typedef Node = {
      ast_type: NodeType;
      tokens:   [Token];
      where:    string;
   };
   typedef NodeType = ExprType or StatType or "Statlist";
   typedef StatNode = {
      ast_type: StatType;
      tokens:   [Token];
      where:    string;
   };
   typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
   typedef Statlist = {
      ast_type: "Statlist";
      tokens:   [Token];
      where:    string;
   };

   -- Members:
   LUA_SETTINGS: {
      function_types: false;
      is_sol:         false;
      keywords:       {string};
      symbols:        {string};
   };
   SOL_SETTINGS: {
      function_types: true;
      is_sol:         true;
      keywords:       {string};
      symbols:        {string};
   };
   parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}