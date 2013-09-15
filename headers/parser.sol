-- Compiled from sol/parser.sol at 2013 Sep 15  19:45:19

global typedef Variable = <table: 0x013232c8> {
   is_global:  bool;
   name:       string;
   namespace:  {string => Type}?;
   references: int;
   scope:      Scope;
   type:       Type?;
   where:      string;
}

global typedef Scope = <instance> <table: 0x0184f520> {
   fixed: true?;

   !! class_type:    { }
}

global Scope : <table: 0x018aaca0> {
   add_global:          function(self, v) -> void [EMPTY TYPE-LIST];
   add_global_type:     function(self, name: string, typ: Type) -> void [EMPTY TYPE-LIST];
   create_global:       function(self, name: string, where: string, type: Type?) -> Variable;
   create_global_scope: function() -> Scope;
   create_local:        function(self, name: string, where: string) -> Variable;
   create_module_scope: function() -> Scope;
   declare_type:        function(self, name: string, typ: Type, where: string, is_local: bool) -> void [EMPTY TYPE-LIST];
   get_global:          function(self, name: string) -> Variable?;
   get_global_scope:    function() -> Scope;
   get_global_type:     function(self, name: string) -> Type?;
   get_global_typedefs: function(self, list: [Variable]?) -> [Variable];
   get_global_vars:     function(self, list: [Variable]?) -> [Variable];
   get_local:           function(self, name: string) -> Variable?;
   get_local_type:      function(self, name: string) -> Type?;
   get_scoped:          function(self, name: string) -> Variable?;
   get_scoped_global:   function(self, name: string) -> Variable?;
   get_scoped_type:     function(self, name: string) -> Type?;
   get_scoped_var:      function(self, name: string) -> Variable?;
   get_type:            function(self, name: string) -> Type?;
   get_var:             function(self, name: string) -> Variable?;
   get_var_args:        function(self) -> Type?;
   global_scope:        <instance> <table: 0x0184f520> {
      fixed: true?;

      !! class_type:    { }
   };
   init:                function(self, parent: Scope?) -> void [EMPTY TYPE-LIST];
   is_module_level:     function(self) -> bool;
   new:                 function(parent: Scope?) -> Scope;
}

return <table: 0x018c75b0> {
   -- Types:
   typedef ExprNode = <table: 0x00554a18> {
      ast_type: ExprType;
      tokens:   [Token];
      where:    string;
   };
   typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
   typedef Node = <table: 0x005651f8> {
      ast_type: NodeType;
      tokens:   [Token];
      where:    string;
   };
   typedef NodeType = ExprType or StatType or "Statlist";
   typedef StatNode = <table: 0x00732fb8> {
      ast_type: StatType;
      tokens:   [Token];
      where:    string;
   };
   typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
   typedef Statlist = <table: 0x00569e50> {
      ast_type: "Statlist";
      tokens:   [Token];
      where:    string;
   };

   -- Members:
   LUA_SETTINGS: <table: 0x018b5df8> {
      function_types: false;
      is_sol:         false;
      keywords:       {string};
      symbols:        {string};
   };
   SOL_SETTINGS: <table: 0x018b5dc0> {
      function_types: true;
      is_sol:         true;
      keywords:       {string};
      symbols:        {string};
   };
   parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}