-- Compiled from sol/scope.sol
{
   -- Types:
   typedef Scope = Scope,
   typedef Variable = Variable,

   -- Members:
   Scope: [class] {
      add_global:          function(self, v) -> void [EMPTY TYPE-LIST],
      create_global:       function(self, name: string, where: string, type: Type) -> Variable,
      create_global_scope: function() -> Scope,
      create_local:        function(self, name: string, where: string) -> Variable,
      create_module_scope: function() -> Scope,
      declare_type:        function(self, name: string, type: Type, where: string) -> void [EMPTY TYPE-LIST],
      get_global:          function(self, name: string) -> Variable?,
      get_global_scope:    function() -> Scope,
      get_global_typedefs: function(self, list: [Variable]?) -> [Variable],
      get_global_vars:     function(self, list: [Variable]?) -> [Variable],
      get_local:           function(self, name: string) -> Variable?,
      get_scoped:          function(self, name: string) -> Variable?,
      get_scoped_global:   function(self, name: string) -> Variable?,
      get_scoped_type:     function(self, name: string) -> Type?,
      get_scoped_var:      function(self, name: string) -> Variable?,
      get_type:            function(self, name) -> Type?,
      get_var:             function(self, name: string) -> Variable?,
      get_var_args:        function(self) -> Type?,
      global_scope:        any,
      init:                function(self, parent: Scope?) -> void [EMPTY TYPE-LIST],
      is_module_level:     function(self) -> bool,
      new:                 function(parent: Scope?) -> Scope,

      !! instance_type: [instance] {
         children:        [Scope],
         fixed:           false,
         global_typedefs: {string => Type},
         globals:         [Variable],
         locals:          [Variable],
         parent:          Scope?,
         typedefs:        {string => Type},
         vararg:          Variable?,

         !! class_type:    { }
      }
   },
}