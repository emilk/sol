-- Compiled from sol/output.sol at 2013 Sep 15  18:52:24

global typedef Variable = {
   is_global:  bool;
   name:       string;
   namespace:  {string => Type}?;
   references: int;
   scope:      Scope;
   type:       Type?;
   where:      string;
}

global typedef Scope = { }

global Scope : {
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
   global_scope:        { };
   init:                function(self, parent: Scope?) -> void [EMPTY TYPE-LIST];
   is_module_level:     function(self) -> bool;
   new:                 function(parent: Scope?) -> Scope;
}

return function(ast, filename: string, insert_new_lines: bool?) -> string