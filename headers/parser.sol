-- Compiled from sol/parser.sol at 2013 Sep 15  22:21:02

global typedef Variable = <table: 0x01321810>{
   is_global:  bool;
   name:       string;
   namespace:  {string => Type}?;
   references: int;
   scope:      Scope;
   type:       Type?;
   where:      string;
}

global typedef Scope = <instance><table: 0x01846540>{
   children:        [Scope]?;
   fixed:           true?;
   global_typedefs: {string => Type}?;
   globals:         [Variable]?;
   locals:          [Variable]?;
   parent:          Scope or nil or nil;
   typedefs:        {string => Type}?;
   vararg:          Variable or nil or nil;

   !! class_type:    <class><table: 0x018464b8>{
      add_global:          function(self, v) -> void [EMPTY TYPE-LIST]?;
      add_global_type:     function(self, name: string, typ: Type) -> void [EMPTY TYPE-LIST]?;
      create_global:       function(self, name: string, where: string, typ: Type?) -> Variable?;
      create_global_scope: function() -> Scope?;
      create_local:        function(self, name: string, where: string) -> Variable?;
      create_module_scope: function() -> Scope?;
      declare_type:        function(self, name: string, typ: Type, where: string, is_local: bool) -> void [EMPTY TYPE-LIST]?;
      get_global:          function(self, name: string) -> Variable??;
      get_global_scope:    function() -> Scope?;
      get_global_type:     function(self, name: string) -> Type??;
      get_global_typedefs: function(self, list: [Variable]?) -> [Variable]?;
      get_global_vars:     function(self, list: [Variable]?) -> [Variable]?;
      get_local:           function(self, name: string) -> Variable??;
      get_local_type:      function(self, name: string) -> Type??;
      get_scoped:          function(self, name: string) -> Variable??;
      get_scoped_global:   function(self, name: string) -> Variable??;
      get_scoped_type:     function(self, name: string) -> Type??;
      get_scoped_var:      function(self, name: string) -> Variable??;
      get_type:            function(self, name: string) -> Type??;
      get_var:             function(self, name: string) -> Variable??;
      get_var_args:        function(self) -> Type??;
      global_scope:        any;
      init:                function(self, parent: Scope?) -> void [EMPTY TYPE-LIST]?;
      is_module_level:     function(self) -> bool?;
      new:                 function(parent: Scope?) -> Scope?;

      !! instance_type: <!RECURSION!>
   }
}

global Scope : <class><table: 0x018464b8>{
   add_global:          function(self, v) -> void [EMPTY TYPE-LIST]?;
   add_global_type:     function(self, name: string, typ: Type) -> void [EMPTY TYPE-LIST]?;
   create_global:       function(self, name: string, where: string, typ: Type?) -> Variable?;
   create_global_scope: function() -> Scope?;
   create_local:        function(self, name: string, where: string) -> Variable?;
   create_module_scope: function() -> Scope?;
   declare_type:        function(self, name: string, typ: Type, where: string, is_local: bool) -> void [EMPTY TYPE-LIST]?;
   get_global:          function(self, name: string) -> Variable??;
   get_global_scope:    function() -> Scope?;
   get_global_type:     function(self, name: string) -> Type??;
   get_global_typedefs: function(self, list: [Variable]?) -> [Variable]?;
   get_global_vars:     function(self, list: [Variable]?) -> [Variable]?;
   get_local:           function(self, name: string) -> Variable??;
   get_local_type:      function(self, name: string) -> Type??;
   get_scoped:          function(self, name: string) -> Variable??;
   get_scoped_global:   function(self, name: string) -> Variable??;
   get_scoped_type:     function(self, name: string) -> Type??;
   get_scoped_var:      function(self, name: string) -> Variable??;
   get_type:            function(self, name: string) -> Type??;
   get_var:             function(self, name: string) -> Variable??;
   get_var_args:        function(self) -> Type??;
   global_scope:        any;
   init:                function(self, parent: Scope?) -> void [EMPTY TYPE-LIST]?;
   is_module_level:     function(self) -> bool?;
   new:                 function(parent: Scope?) -> Scope?;

   !! instance_type: <instance><table: 0x01846540>{
      children:        [Scope]?;
      fixed:           true?;
      global_typedefs: {string => Type}?;
      globals:         [Variable]?;
      locals:          [Variable]?;
      parent:          Scope or nil or nil;
      typedefs:        {string => Type}?;
      vararg:          Variable or nil or nil;

      !! class_type:    <!RECURSION!>
   }
}

return <table: 0x018b8378>{
   -- Types:
   typedef ExprNode = <table: 0x011112f0>{
      ast_type: ExprType;
      tokens:   [Token];
      where:    string;
   };
   typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
   typedef Node = <table: 0x011104d8>{
      ast_type: NodeType;
      tokens:   [Token];
      where:    string;
   };
   typedef NodeType = ExprType or StatType or "Statlist";
   typedef StatNode = <table: 0x01111918>{
      ast_type: StatType;
      tokens:   [Token];
      where:    string;
   };
   typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
   typedef Statlist = <table: 0x01110d00>{
      ast_type: "Statlist";
      tokens:   [Token];
      where:    string;
   };

   -- Members:
   LUA_SETTINGS: <table: 0x018a6e68>{
      function_types: false;
      is_sol:         false;
      keywords:       {string};
      symbols:        {string};
   };
   SOL_SETTINGS: <table: 0x018b2490>{
      function_types: true;
      is_sol:         true;
      keywords:       {string};
      symbols:        {string};
   };
   parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}