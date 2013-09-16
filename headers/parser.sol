-- Compiled from sol/parser.sol at 2013 Sep 16  22:07:42

global typedef Variable = <0x01366e10>{
	is_global:  bool;
	name:       string;
	namespace:  {string => Type}?;
	references: int;
	scope:      Scope;
	type:       Type?;
	where:      string;
}

global typedef Scope = <instance><0x017ce5e0>{
	children:        [Scope]?;
	fixed:           true?;
	global_typedefs: {string => Type}?;
	globals:         [Variable]?;
	locals:          [Variable]?;
	parent:          Scope?;
	typedefs:        {string => Type}?;
	vararg:          Variable?;

	!! class_type:    <class><0x017ce558>{
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

		!! instance_type: <RECURSION 0x017ce5e0>
	}
}

global Scope : <class><0x017ce558>{
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

	!! instance_type: <instance><0x017ce5e0>{
		children:        [Scope]?;
		fixed:           true?;
		global_typedefs: {string => Type}?;
		globals:         [Variable]?;
		locals:          [Variable]?;
		parent:          Scope?;
		typedefs:        {string => Type}?;
		vararg:          Variable?;

		!! class_type:    <RECURSION 0x017ce558>
	}
}

return <0x01842d60>{
	-- Types:
	typedef AssignmentStatement = <0x0114ed88>{
		ast_type: "AssignmentStatement";
		lhs:      [ExprNode];
		rhs:      [ExprNode];
		tokens:   [Token];
		where:    string;
	};
	typedef BinopExpr = <0x01147e28>{
		ast_type: "BinopExpr";
		lhs:      ExprNode;
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef BooleanExpr = <0x01147188>{
		ast_type: "BooleanExpr";
		tokens:   [Token];
		value:    bool;
		where:    string;
	};
	typedef BreakStatement = <0x01155cc0>{
		ast_type: "BreakStatement";
		tokens:   [Token];
		where:    string;
	};
	typedef CallExpr = <0x011494f0>{
		arguments: [ExprNode];
		ast_type:  "CallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef CallStatement = <0x0114f688>{
		ast_type:   "CallStatement";
		expression: ExprNode;
		tokens:     [Token];
		where:      string;
	};
	typedef CastExpr = <0x0114e0b8>{
		ast_type: "CastExpr";
		expr:     ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ClassDeclStatement = <0x011505d8>{
		ast_type: "ClassDeclStatement";
		name:     string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ConstructorExpr = <0x0114d1a0>{
		ast_type:   "ConstructorExpr";
		entry_list: [ConstructorExprEntry];
		tokens:     [Token];
		where:      string;
	};
	typedef DoStatement = <0x011522a8>{
		ast_type: "DoStatement";
		body:     Statlist;
		tokens:   [Token];
		where:    string;
	};
	typedef DotsExpr = <0x01148f00>{
		ast_type: "DotsExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Eof = <0x01157558>{
		ast_type: "Eof";
		tokens:   [Token];
		where:    string;
	};
	typedef ExprNode = <0x01145728>{
		ast_type: ExprType;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
	typedef FunctionDeclStatement = <0x011562b0>{
		arguments:    [<0x01156c78>{
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
	typedef GenericForStatement = <0x011529b8>{
		ast_type:   "GenericForStatement";
		body:       Statlist;
		generators: [ExprNode];
		tokens:     [Token];
		var_names:  [string];
		where:      string;
	};
	typedef GotoStatement = <0x01154ea0>{
		ast_type: "GotoStatement";
		label:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef IdExpr = <0x01145d78>{
		ast_type: "IdExpr";
		name:     string;
		tokens:   [Token];
		where:    string;
	};
	typedef IfStatement = <0x01151358>{
		ast_type: "IfStatement";
		clauses:  [IfStatementClause];
		tokens:   [Token];
		where:    string;
	};
	typedef IndexExpr = <0x0114aed0>{
		ast_type: "IndexExpr";
		base:     ExprNode;
		index:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef LabelStatement = <0x011547f0>{
		ast_type: "LabelStatement";
		label:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef LambdaFunctionExpr = <0x0114bef0>{
		ast_type: "LambdaFunctionExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef MemberExpr = <0x0114b710>{
		ast_type: "MemberExpr";
		base:     ExprNode;
		ident:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef NilExpr = <0x01147838>{
		ast_type: "NilExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Node = <0x01144910>{
		ast_type: NodeType;
		tokens:   [Token];
		where:    string;
	};
	typedef NodeType = ExprType or StatType or "Statlist";
	typedef NumberExpr = <0x01146428>{
		ast_type: "NumberExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef NumericForStatement = <0x01153370>{
		ast_type: "NumericForStatement";
		body:     Statlist;
		end_:     ExprNode;
		start:    ExprNode;
		step:     ExprNode?;
		tokens:   [Token];
		var_name: string;
		where:    string;
	};
	typedef ParenthesesExpr = <0x0114d9a8>{
		ast_type: "ParenthesesExpr";
		inner:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef RepeatStatement = <0x01153fb0>{
		ast_type:  "RepeatStatement";
		body:      Statlist;
		condition: ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef ReturnStatement = <0x01155550>{
		arguments: [ExprNode];
		ast_type:  "ReturnStatement";
		tokens:    [Token];
		where:     string;
	};
	typedef StatNode = <0x0114e7c8>{
		ast_type: StatType;
		tokens:   [Token];
		where:    string;
	};
	typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
	typedef Statlist = <0x01145138>{
		ast_type: "Statlist";
		tokens:   [Token];
		where:    string;
	};
	typedef StringCallExpr = <0x0114a630>{
		arguments: [StringExpr];
		ast_type:  "StringCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef StringExpr = <0x01146ad8>{
		ast_type: "StringExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef TableCallExpr = <0x01149d90>{
		arguments: [ConstructorExpr];
		ast_type:  "TableCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef Typedef = <0x01157b48>{
		ast_type: "Typedef";
		tokens:   [Token];
		where:    string;
	};
	typedef UnopExpr = <0x01148720>{
		ast_type: "UnopExpr";
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef VarDeclareStatement = <0x0114fd98>{
		ast_type:  "VarDeclareStatement";
		init_list: ExprNode;
		name_list: [string];
		tokens:    [Token];
		where:     string;
	};
	typedef WhileStatement = <0x01151a68>{
		ast_type:  "WhileStatement";
		body:      Statlist;
		condition: ExprNode;
		tokens:    [Token];
		where:     string;
	};

	-- Members:
	LUA_SETTINGS: <0x0182c2f0>{
	              	function_types: false;
	              	is_sol:         false;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	SOL_SETTINGS: <0x01837960>{
	              	function_types: true;
	              	is_sol:         true;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}