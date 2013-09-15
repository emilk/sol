-- Compiled from sol/parser.sol at 2013 Sep 15  22:46:00

global typedef Variable = <table: 0x01344150>{
   is_global:  bool;
   name:       string;
   namespace:  {string => Type}?;
   references: int;
   scope:      Scope;
   type:       Type?;
   where:      string;
}

global typedef Scope = <instance><table: 0x0189d2f0>{
   children:        [Scope]?;
   fixed:           true?;
   global_typedefs: {string => Type}?;
   globals:         [Variable]?;
   locals:          [Variable]?;
   parent:          Scope?;
   typedefs:        {string => Type}?;
   vararg:          Variable?;

   !! class_type:    <class><table: 0x0189d268>{
      add_global:          (function(self, v) -> void [EMPTY TYPE-LIST]) or nil;
      add_global_type:     (function(self, name: string, typ: Type) -> void [EMPTY TYPE-LIST]) or nil;
      create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
      create_global_scope: (function() -> Scope) or nil;
      create_local:        (function(self, name: string, where: string) -> Variable) or nil;
      create_module_scope: (function() -> Scope) or nil;
      declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void [EMPTY TYPE-LIST]) or nil;
      get_global:          (function(self, name: string) -> Variable?) or nil;
      get_global_scope:    (function() -> Scope) or nil;
      get_global_type:     (function(self, name: string) -> Type?) or nil;
      get_global_typedefs: (function(self, list: [Variable]?) -> [Variable]) or nil;
      get_global_vars:     (function(self, list: [Variable]?) -> [Variable]) or nil;
      get_local:           (function(self, name: string) -> Variable?) or nil;
      get_local_type:      (function(self, name: string) -> Type?) or nil;
      get_scoped:          (function(self, name: string) -> Variable?) or nil;
      get_scoped_global:   (function(self, name: string) -> Variable?) or nil;
      get_scoped_type:     (function(self, name: string) -> Type?) or nil;
      get_scoped_var:      (function(self, name: string) -> Variable?) or nil;
      get_type:            (function(self, name: string) -> Type?) or nil;
      get_var:             (function(self, name: string) -> Variable?) or nil;
      get_var_args:        (function(self) -> Type?) or nil;
      global_scope:        any;
      init:                (function(self, parent: Scope?) -> void [EMPTY TYPE-LIST]) or nil;
      is_module_level:     (function(self) -> bool) or nil;
      new:                 (function(parent: Scope?) -> Scope) or nil;

      !! instance_type: <RECURSION table: 0x0189d2f0>
   }
}

global Scope : <class><table: 0x0189d268>{
   add_global:          (function(self, v) -> void [EMPTY TYPE-LIST]) or nil;
   add_global_type:     (function(self, name: string, typ: Type) -> void [EMPTY TYPE-LIST]) or nil;
   create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
   create_global_scope: (function() -> Scope) or nil;
   create_local:        (function(self, name: string, where: string) -> Variable) or nil;
   create_module_scope: (function() -> Scope) or nil;
   declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void [EMPTY TYPE-LIST]) or nil;
   get_global:          (function(self, name: string) -> Variable?) or nil;
   get_global_scope:    (function() -> Scope) or nil;
   get_global_type:     (function(self, name: string) -> Type?) or nil;
   get_global_typedefs: (function(self, list: [Variable]?) -> [Variable]) or nil;
   get_global_vars:     (function(self, list: [Variable]?) -> [Variable]) or nil;
   get_local:           (function(self, name: string) -> Variable?) or nil;
   get_local_type:      (function(self, name: string) -> Type?) or nil;
   get_scoped:          (function(self, name: string) -> Variable?) or nil;
   get_scoped_global:   (function(self, name: string) -> Variable?) or nil;
   get_scoped_type:     (function(self, name: string) -> Type?) or nil;
   get_scoped_var:      (function(self, name: string) -> Variable?) or nil;
   get_type:            (function(self, name: string) -> Type?) or nil;
   get_var:             (function(self, name: string) -> Variable?) or nil;
   get_var_args:        (function(self) -> Type?) or nil;
   global_scope:        any;
   init:                (function(self, parent: Scope?) -> void [EMPTY TYPE-LIST]) or nil;
   is_module_level:     (function(self) -> bool) or nil;
   new:                 (function(parent: Scope?) -> Scope) or nil;

   !! instance_type: <instance><table: 0x0189d2f0>{
      children:        [Scope]?;
      fixed:           true?;
      global_typedefs: {string => Type}?;
      globals:         [Variable]?;
      locals:          [Variable]?;
      parent:          Scope?;
      typedefs:        {string => Type}?;
      vararg:          Variable?;

      !! class_type:    <RECURSION table: 0x0189d268>
   }
}

return <table: 0x0190e590>{
   -- Types:
   typedef ExprNode = <table: 0x01134948>{
      ast_type: ExprType;
      tokens:   [Token];
      where:    string;
   };
   typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
   typedef Node = <table: 0x01133b30>{
      ast_type: NodeType;
      tokens:   [Token];
      where:    string;
   };
   typedef NodeType = ExprType or StatType or "Statlist";
   typedef StatNode = <table: 0x01134f98>{
      ast_type: StatType;
      tokens:   [Token];
      where:    string;
   };
   typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
   typedef Statlist = <table: 0x01134358>{
      ast_type: "Statlist";
      tokens:   [Token];
      where:    string;
   };

   -- Members:
   LUA_SETTINGS: <table: 0x018fe100>{
      function_types: false;
      is_sol:         false;
      keywords:       {string};
      symbols:        {string};
   };
   SOL_SETTINGS: <table: 0x01909508>{
      function_types: true;
      is_sol:         true;
      keywords:       {string};
      symbols:        {string};
   };
   parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}