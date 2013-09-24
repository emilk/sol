-- Compiled from sol/parser.sol at 2013 Sep 24  16:57:25

global typedef Variable = <0x005c54d0>{
	forward_declared: bool?;
	is_global:        bool;
	name:             string;
	namespace:        {string => Type}?;
	references:       int;
	scope:            Scope;
	type:             Type?;
	where:            string;
}

global typedef Scope = <instance><0x006b5050>{
	children:        [Scope]?;
	fixed:           false?;
	global_typedefs: {string => Type}?;
	globals:         [Variable]?;
	locals:          [Variable]?;
	parent:          Scope?;
	typedefs:        {string => Type}?;
	vararg:          Variable?;

	!! class_type:    <class><0x014765a8>{
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
		get_global_typedefs: (function(self) -> {string => Type}) or nil;
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

		!! instance_type: <RECURSION 0x006b5050>
	}
}

global Scope : <class><0x014765a8>{
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
	get_global_typedefs: (function(self) -> {string => Type}) or nil;
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

	!! instance_type: <instance><0x006b5050>{
		children:        [Scope]?;
		fixed:           false?;
		global_typedefs: {string => Type}?;
		globals:         [Variable]?;
		locals:          [Variable]?;
		parent:          Scope?;
		typedefs:        {string => Type}?;
		vararg:          Variable?;

		!! class_type:    <RECURSION 0x014765a8>
	}
}

return <0x01522c50>{
	-- Types:
	typedef AssignmentStatement = <0x011e28b0>{
		ast_type: "AssignmentStatement";
		lhs:      [ExprNode];
		rhs:      [ExprNode];
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef BinopExpr = <0x011b9c70>{
		ast_type: "BinopExpr";
		lhs:      ExprNode;
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef BooleanExpr = <0x011b89e0>{
		ast_type: "BooleanExpr";
		tokens:   [Token];
		value:    bool;
		where:    string;
	};
	typedef BreakStatement = <0x011ea1f0>{
		ast_type: "BreakStatement";
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef CallExpr = <0x011bb338>{
		arguments: [ExprNode];
		ast_type:  "CallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef CallStatement = <0x011e31b0>{
		ast_type:   "CallStatement";
		expression: ExprNode;
		scope:      Scope?;
		tokens:     [Token];
		where:      string;
	};
	typedef CastExpr = <0x011e1a88>{
		ast_type: "CastExpr";
		expr:     ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ClassDeclStatement = <0x011e4a50>{
		ast_type: "ClassDeclStatement";
		is_local: bool;
		name:     string;
		rhs:      ExprNode;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef ConstructorExpr = <0x011bfc20>{
		ast_type:   "ConstructorExpr";
		entry_list: [ConstructorExprEntry];
		tokens:     [Token];
		where:      string;
	};
	typedef DoStatement = <0x011e67d8>{
		ast_type: "DoStatement";
		body:     Statlist;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef DotsExpr = <0x011bad48>{
		ast_type: "DotsExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Eof = <0x011ebc98>{
		ast_type: "Eof";
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprNode = <0x011b6eb0>{
		ast_type: ExprType;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "ExternExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
	typedef ExternExpr = <0x011b9680>{
		ast_type: "ExternExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef FunctionDeclStatement = <0x011ea7e0>{
		arguments:    [<0x011eb000>{
		              		name: string;
		              		type: Type?;
		              	}];
		ast_type:     "FunctionDeclStatement";
		body:         Statlist;
		is_aggregate: bool;
		is_mem_fun:   bool;
		name_expr:    ExprNode;
		scope:        Scope?;
		scoping:      "local" or "global" or "";
		tokens:       [Token];
		vararg:       VarArgs?;
		where:        string;
	};
	typedef GenericForStatement = <0x011e6ee8>{
		ast_type:   "GenericForStatement";
		body:       Statlist;
		generators: [ExprNode];
		scope:      Scope?;
		tokens:     [Token];
		var_names:  [string];
		where:      string;
	};
	typedef GotoStatement = <0x011e93d0>{
		ast_type: "GotoStatement";
		label:    string;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef IdExpr = <0x011b7500>{
		ast_type: "IdExpr";
		name:     string;
		tokens:   [Token];
		variable: Variable;
		where:    string;
	};
	typedef IfStatement = <0x011e5888>{
		ast_type: "IfStatement";
		clauses:  [IfStatementClause];
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef IndexExpr = <0x011bcd18>{
		ast_type: "IndexExpr";
		base:     ExprNode;
		index:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef LabelStatement = <0x011e8d20>{
		ast_type: "LabelStatement";
		label:    string;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef LambdaFunctionExpr = <0x011bddf0>{
		arguments:    [<0x011be0b8>{
		              		name: string;
		              		type: Type?;
		              	}];
		ast_type:     "LambdaFunctionExpr";
		body:         Statlist?;
		is_mem_fun:   bool;
		return_types: [Type]?;
		tokens:       [Token];
		vararg:       VarArgs?;
		where:        string;
	};
	typedef MemberExpr = <0x011bd558>{
		ast_type: "MemberExpr";
		base:     ExprNode;
		ident:    string;
		indexer:  string;
		tokens:   [Token];
		where:    string;
	};
	typedef NilExpr = <0x011b9090>{
		ast_type: "NilExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Node = <0x011b5f18>{
		ast_type: NodeType;
		tokens:   [Token];
		where:    string;
	};
	typedef NodeType = ExprType or StatType or "Statlist";
	typedef NumberExpr = <0x011b7c80>{
		ast_type: "NumberExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef NumericForStatement = <0x011e78a0>{
		ast_type: "NumericForStatement";
		body:     Statlist;
		end_:     ExprNode;
		scope:    Scope?;
		start:    ExprNode;
		step:     ExprNode?;
		tokens:   [Token];
		var_name: string;
		where:    string;
	};
	typedef ParenthesesExpr = <0x011e1378>{
		ast_type: "ParenthesesExpr";
		inner:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef RepeatStatement = <0x011e84e0>{
		ast_type:  "RepeatStatement";
		body:      Statlist;
		condition: ExprNode;
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};
	typedef ReturnStatement = <0x011e9a80>{
		arguments: [ExprNode];
		ast_type:  "ReturnStatement";
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};
	typedef StatNode = <0x011e2198>{
		ast_type: StatType;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
	typedef Statlist = <0x011b6740>{
		ast_type: "Statlist";
		body:     [StatNode];
		tokens:   [Token];
		where:    string;
	};
	typedef StringCallExpr = <0x011bc478>{
		arguments: [StringExpr];
		ast_type:  "StringCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef StringExpr = <0x011b8330>{
		ast_type: "StringExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef TableCallExpr = <0x011bbbd8>{
		arguments: [ConstructorExpr];
		ast_type:  "TableCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef Typedef = <0x011ec288>{
		ast_type:       "Typedef";
		base_types:     [Type];
		is_local:       bool;
		namespace_name: string?;
		scope:          Scope?;
		tokens:         [Token];
		type:           Type?;
		type_name:      string;
		where:          string;
	};
	typedef UnopExpr = <0x011ba568>{
		ast_type: "UnopExpr";
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef VarDeclareStatement = <0x011e38c0>{
		ast_type:  "VarDeclareStatement";
		init_list: [ExprNode];
		is_local:  bool;
		name_list: [string];
		scope:     Scope?;
		scoping:   "local" or "global" or "var";
		tokens:    [Token];
		type_list: [Type]?;
		where:     string;
	};
	typedef WhileStatement = <0x011e5f98>{
		ast_type:  "WhileStatement";
		body:      Statlist;
		condition: ExprNode;
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};

	-- Members:
	LUA_SETTINGS: <0x01294390>{
	              	function_types: false;
	              	is_sol:         false;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	SOL_SETTINGS: <0x01336460>{
	              	function_types: true;
	              	is_sol:         true;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}