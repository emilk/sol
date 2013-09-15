-- Compiled from sol/type_check.sol at 2013 Sep 15  22:46:01

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

return function(ast, filename: string, on_require: OnRequireT?, settings) -> true or false, any