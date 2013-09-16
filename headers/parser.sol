-- Compiled from sol/parser.sol at 2013 Sep 16  22:23:02

global typedef Variable = <0x0131f920>{
	is_global:  bool;
	name:       string;
	namespace:  {string => Type}?;
	references: int;
	scope:      Scope;
	type:       Type?;
	where:      string;
}

global typedef Scope = <instance><0x018686c8>{
	children:        [Scope]?;
	fixed:           true?;
	global_typedefs: {string => Type}?;
	globals:         [Variable]?;
	locals:          [Variable]?;
	parent:          Scope?;
	typedefs:        {string => Type}?;
	vararg:          Variable?;

	!! class_type:    <class><0x01868640>{
		add_global:          (function(self, v) -> void) or nil;
		add_global_type:     (function(self, name: string, typ: Type) -> void) or nil;
		create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
		create_global_scope: (function() -> Scope) or nil;
		create_local:        (function(self, name: string, where: string) -> Variable) or nil;
		create_module_scope: (function() -> Scope) or nil;
		declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void) or nil;
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
		init:                (function(self, parent: Scope?) -> void) or nil;
		is_module_level:     (function(self) -> bool) or nil;
		new:                 (function(parent: Scope?) -> Scope) or nil;

		!! instance_type: <RECURSION 0x018686c8>
	}
}

global Scope : <class><0x01868640>{
	add_global:          (function(self, v) -> void) or nil;
	add_global_type:     (function(self, name: string, typ: Type) -> void) or nil;
	create_global:       (function(self, name: string, where: string, typ: Type?) -> Variable) or nil;
	create_global_scope: (function() -> Scope) or nil;
	create_local:        (function(self, name: string, where: string) -> Variable) or nil;
	create_module_scope: (function() -> Scope) or nil;
	declare_type:        (function(self, name: string, typ: Type, where: string, is_local: bool) -> void) or nil;
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
	init:                (function(self, parent: Scope?) -> void) or nil;
	is_module_level:     (function(self) -> bool) or nil;
	new:                 (function(parent: Scope?) -> Scope) or nil;

	!! instance_type: <instance><0x018686c8>{
		children:        [Scope]?;
		fixed:           true?;
		global_typedefs: {string => Type}?;
		globals:         [Variable]?;
		locals:          [Variable]?;
		parent:          Scope?;
		typedefs:        {string => Type}?;
		vararg:          Variable?;

		!! class_type:    <RECURSION 0x01868640>
	}
}

return <0x006d4a70>{
	-- Types:
	typedef AssignmentStatement = <0x011a6140>{
		ast_type: "AssignmentStatement";
		lhs:      [ExprNode];
		rhs:      [ExprNode];
		tokens:   [Token];
		where:    string;
	};
	typedef BinopExpr = <0x0119f1e0>{
		ast_type: "BinopExpr";
		lhs:      ExprNode;
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef BooleanExpr = <0x0119e540>{
		ast_type: "BooleanExpr";
		tokens:   [Token];
		value:    bool;
		where:    string;
	};
	typedef BreakStatement = <0x011ad9c8>{
		ast_type: "BreakStatement";
		tokens:   [Token];
		where:    string;
	};
	typedef CallExpr = <0x011a08a8>{
		arguments: [ExprNode];
		ast_type:  "CallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef CallStatement = <0x011a6a40>{
		ast_type:   "CallStatement";
		expression: ExprNode;
		tokens:     [Token];
		where:      string;
	};
	typedef CastExpr = <0x011a5470>{
		ast_type: "CastExpr";
		expr:     ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ClassDeclStatement = <0x011a82e0>{
		ast_type: "ClassDeclStatement";
		name:     string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ConstructorExpr = <0x011a4558>{
		ast_type:   "ConstructorExpr";
		entry_list: [ConstructorExprEntry];
		tokens:     [Token];
		where:      string;
	};
	typedef DoStatement = <0x011a9fb0>{
		ast_type: "DoStatement";
		body:     Statlist;
		tokens:   [Token];
		where:    string;
	};
	typedef DotsExpr = <0x011a02b8>{
		ast_type: "DotsExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Eof = <0x011af210>{
		ast_type: "Eof";
		tokens:   [Token];
		where:    string;
	};
	typedef ExprNode = <0x0119cae0>{
		ast_type: ExprType;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
	typedef FunctionDeclStatement = <0x011adfb8>{
		arguments:    [<0x011ae930>{
		              		name: string;
		              	}];
		ast_type:     "FunctionDeclStatement";
		body:         Statlist;
		is_aggregate: bool;
		name_expr:    ExprNode;
		scoping:      "local" or "global" or "";
		tokens:       [Token];
		vararg:       VarArgs?;
		where:        string;
	};
	typedef GenericForStatement = <0x011aa6c0>{
		ast_type:   "GenericForStatement";
		body:       Statlist;
		generators: [ExprNode];
		tokens:     [Token];
		var_names:  [string];
		where:      string;
	};
	typedef GotoStatement = <0x011acba8>{
		ast_type: "GotoStatement";
		label:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef IdExpr = <0x0119d130>{
		ast_type: "IdExpr";
		name:     string;
		tokens:   [Token];
		where:    string;
	};
	typedef IfStatement = <0x011a9060>{
		ast_type: "IfStatement";
		clauses:  [IfStatementClause];
		tokens:   [Token];
		where:    string;
	};
	typedef IndexExpr = <0x011a2288>{
		ast_type: "IndexExpr";
		base:     ExprNode;
		index:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef LabelStatement = <0x011ac4f8>{
		ast_type: "LabelStatement";
		label:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef LambdaFunctionExpr = <0x011a32a8>{
		ast_type: "LambdaFunctionExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef MemberExpr = <0x011a2ac8>{
		ast_type: "MemberExpr";
		base:     ExprNode;
		ident:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef NilExpr = <0x0119ebf0>{
		ast_type: "NilExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Node = <0x0119bcc8>{
		ast_type: NodeType;
		tokens:   [Token];
		where:    string;
	};
	typedef NodeType = ExprType or StatType or "Statlist";
	typedef NumberExpr = <0x0119d7e0>{
		ast_type: "NumberExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef NumericForStatement = <0x011ab078>{
		ast_type: "NumericForStatement";
		body:     Statlist;
		end_:     ExprNode;
		start:    ExprNode;
		step:     ExprNode?;
		tokens:   [Token];
		var_name: string;
		where:    string;
	};
	typedef ParenthesesExpr = <0x011a4d60>{
		ast_type: "ParenthesesExpr";
		inner:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef RepeatStatement = <0x011abcb8>{
		ast_type:  "RepeatStatement";
		body:      Statlist;
		condition: ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef ReturnStatement = <0x011ad258>{
		arguments: [ExprNode];
		ast_type:  "ReturnStatement";
		tokens:    [Token];
		where:     string;
	};
	typedef StatNode = <0x011a5b80>{
		ast_type: StatType;
		tokens:   [Token];
		where:    string;
	};
	typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
	typedef Statlist = <0x0119c4f0>{
		ast_type: "Statlist";
		tokens:   [Token];
		where:    string;
	};
	typedef StringCallExpr = <0x011a19e8>{
		arguments: [StringExpr];
		ast_type:  "StringCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef StringExpr = <0x0119de90>{
		ast_type: "StringExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef TableCallExpr = <0x011a1148>{
		arguments: [ConstructorExpr];
		ast_type:  "TableCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef Typedef = <0x011af800>{
		ast_type: "Typedef";
		tokens:   [Token];
		where:    string;
	};
	typedef UnopExpr = <0x0119fad8>{
		ast_type: "UnopExpr";
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef VarDeclareStatement = <0x011a7150>{
		ast_type:  "VarDeclareStatement";
		init_list: [ExprNode];
		is_local:  bool;
		name_list: [string];
		scoping:   "local" or "global" or "var";
		tokens:    [Token];
		type_list: [Type]?;
		where:     string;
	};
	typedef WhileStatement = <0x011a9770>{
		ast_type:  "WhileStatement";
		body:      Statlist;
		condition: ExprNode;
		tokens:    [Token];
		where:     string;
	};

	-- Members:
	LUA_SETTINGS: <0x007d8fa8>{
	              	function_types: false;
	              	is_sol:         false;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	SOL_SETTINGS: <0x0113e570>{
	              	function_types: true;
	              	is_sol:         true;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}