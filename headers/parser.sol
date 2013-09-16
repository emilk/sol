-- Compiled from sol/parser.sol at 2013 Sep 16  22:48:12

global typedef Variable = <0x0068a830>{
	is_global:  bool;
	name:       string;
	namespace:  {string => Type}?;
	references: int;
	scope:      Scope;
	type:       Type?;
	where:      string;
}

global typedef Scope = <instance><0x005b2ff8>{
	children:        [Scope]?;
	fixed:           true?;
	global_typedefs: {string => Type}?;
	globals:         [Variable]?;
	locals:          [Variable]?;
	parent:          Scope?;
	typedefs:        {string => Type}?;
	vararg:          Variable?;

	!! class_type:    <class><0x00581258>{
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

		!! instance_type: <RECURSION 0x005b2ff8>
	}
}

global Scope : <class><0x00581258>{
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

	!! instance_type: <instance><0x005b2ff8>{
		children:        [Scope]?;
		fixed:           true?;
		global_typedefs: {string => Type}?;
		globals:         [Variable]?;
		locals:          [Variable]?;
		parent:          Scope?;
		typedefs:        {string => Type}?;
		vararg:          Variable?;

		!! class_type:    <RECURSION 0x00581258>
	}
}

return <0x014592c0>{
	-- Types:
	typedef AssignmentStatement = <0x00383330>{
		ast_type: "AssignmentStatement";
		lhs:      [ExprNode];
		rhs:      [ExprNode];
		tokens:   [Token];
		where:    string;
	};
	typedef BinopExpr = <0x012f2ee8>{
		ast_type: "BinopExpr";
		lhs:      ExprNode;
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef BooleanExpr = <0x011503e8>{
		ast_type: "BooleanExpr";
		tokens:   [Token];
		value:    bool;
		where:    string;
	};
	typedef BreakStatement = <0x0051b770>{
		ast_type: "BreakStatement";
		tokens:   [Token];
		where:    string;
	};
	typedef CallExpr = <0x007ad168>{
		arguments: [ExprNode];
		ast_type:  "CallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef CallStatement = <0x003d7588>{
		ast_type:   "CallStatement";
		expression: ExprNode;
		tokens:     [Token];
		where:      string;
	};
	typedef CastExpr = <0x00472a00>{
		ast_type: "CastExpr";
		expr:     ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ClassDeclStatement = <0x004ea860>{
		ast_type: "ClassDeclStatement";
		is_local: bool;
		name:     string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ConstructorExpr = <0x00330f00>{
		ast_type:   "ConstructorExpr";
		entry_list: [ConstructorExprEntry];
		tokens:     [Token];
		where:      string;
	};
	typedef DoStatement = <0x004f9190>{
		ast_type: "DoStatement";
		body:     Statlist;
		tokens:   [Token];
		where:    string;
	};
	typedef DotsExpr = <0x007a8710>{
		ast_type: "DotsExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Eof = <0x0052a748>{
		ast_type: "Eof";
		tokens:   [Token];
		where:    string;
	};
	typedef ExprNode = <0x012a7f90>{
		ast_type: ExprType;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
	typedef FunctionDeclStatement = <0x00520cd8>{
		arguments:    [<0x005282b0>{
		              		name: string;
		              	}];
		ast_type:     "FunctionDeclStatement";
		body:         Statlist;
		is_aggregate: bool;
		is_mem_fun:   bool;
		name_expr:    ExprNode;
		scoping:      "local" or "global" or "";
		tokens:       [Token];
		vararg:       VarArgs?;
		where:        string;
	};
	typedef GenericForStatement = <0x004fd100>{
		ast_type:   "GenericForStatement";
		body:       Statlist;
		generators: [ExprNode];
		tokens:     [Token];
		var_names:  [string];
		where:      string;
	};
	typedef GotoStatement = <0x00514288>{
		ast_type: "GotoStatement";
		label:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef IdExpr = <0x012526d8>{
		ast_type: "IdExpr";
		name:     string;
		tokens:   [Token];
		where:    string;
	};
	typedef IfStatement = <0x004f1560>{
		ast_type: "IfStatement";
		clauses:  [IfStatementClause];
		tokens:   [Token];
		where:    string;
	};
	typedef IndexExpr = <0x00389b20>{
		ast_type: "IndexExpr";
		base:     ExprNode;
		index:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef LabelStatement = <0x0050c1e8>{
		ast_type: "LabelStatement";
		label:    string;
		tokens:   [Token];
		where:    string;
	};
	typedef LambdaFunctionExpr = <0x005f3138>{
		arguments:    [<0x0059b748>{
		              		name: string;
		              	}];
		ast_type:     "LambdaFunctionExpr";
		body:         Statlist;
		is_mem_fun:   bool;
		return_types: [Type]?;
		tokens:       [Token];
		vararg:       VarArgs?;
		where:        string;
	};
	typedef MemberExpr = <0x0034e268>{
		ast_type: "MemberExpr";
		base:     ExprNode;
		ident:    string;
		indexer:  string;
		tokens:   [Token];
		where:    string;
	};
	typedef NilExpr = <0x012ecc70>{
		ast_type: "NilExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Node = <0x012f7828>{
		ast_type: NodeType;
		tokens:   [Token];
		where:    string;
	};
	typedef NodeType = ExprType or StatType or "Statlist";
	typedef NumberExpr = <0x007018d8>{
		ast_type: "NumberExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef NumericForStatement = <0x00502710>{
		ast_type: "NumericForStatement";
		body:     Statlist;
		end_:     ExprNode;
		start:    ExprNode;
		step:     ExprNode?;
		tokens:   [Token];
		var_name: string;
		where:    string;
	};
	typedef ParenthesesExpr = <0x0041d1c0>{
		ast_type: "ParenthesesExpr";
		inner:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef RepeatStatement = <0x00509730>{
		ast_type:  "RepeatStatement";
		body:      Statlist;
		condition: ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef ReturnStatement = <0x00519f58>{
		arguments: [ExprNode];
		ast_type:  "ReturnStatement";
		tokens:    [Token];
		where:     string;
	};
	typedef StatNode = <0x003aebf8>{
		ast_type: StatType;
		tokens:   [Token];
		where:    string;
	};
	typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
	typedef Statlist = <0x012f8050>{
		ast_type: "Statlist";
		body:     [StatNode];
		tokens:   [Token];
		where:    string;
	};
	typedef StringCallExpr = <0x007b4658>{
		arguments: [StringExpr];
		ast_type:  "StringCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef StringExpr = <0x011a2370>{
		ast_type: "StringExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef TableCallExpr = <0x007b1de8>{
		arguments: [ConstructorExpr];
		ast_type:  "TableCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef Typedef = <0x00532260>{
		ast_type: "Typedef";
		tokens:   [Token];
		where:    string;
	};
	typedef UnopExpr = <0x01006b78>{
		ast_type: "UnopExpr";
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef VarDeclareStatement = <0x000e9a50>{
		ast_type:  "VarDeclareStatement";
		init_list: [ExprNode];
		is_local:  bool;
		name_list: [string];
		scoping:   "local" or "global" or "var";
		tokens:    [Token];
		type_list: [Type]?;
		where:     string;
	};
	typedef WhileStatement = <0x004f5b10>{
		ast_type:  "WhileStatement";
		body:      Statlist;
		condition: ExprNode;
		tokens:    [Token];
		where:     string;
	};

	-- Members:
	LUA_SETTINGS: <0x005fe650>{
	              	function_types: false;
	              	is_sol:         false;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	SOL_SETTINGS: <0x014c35a0>{
	              	function_types: true;
	              	is_sol:         true;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}