-- Compiled from sol/parser.sol at 2013 Sep 24  17:19:06

global typedef Variable = <0x01257a00>{
	forward_declared: bool?;
	is_global:        bool;
	name:             string;
	namespace:        {string => Type}?;
	references:       int;
	scope:            Scope;
	type:             Type?;
	where:            string;
}

global typedef Scope = <instance><0x0144e690>{
	children:        [Scope]?;
	fixed:           false?;
	global_typedefs: {string => Type}?;
	globals:         [Variable]?;
	locals:          [Variable]?;
	parent:          Scope?;
	typedefs:        {string => Type}?;
	vararg:          Variable?;

	!! class_type:    <class><0x0072f838>{
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

		!! instance_type: <RECURSION 0x0144e690>
	}
}

global Scope : <class><0x0072f838>{
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

	!! instance_type: <instance><0x0144e690>{
		children:        [Scope]?;
		fixed:           false?;
		global_typedefs: {string => Type}?;
		globals:         [Variable]?;
		locals:          [Variable]?;
		parent:          Scope?;
		typedefs:        {string => Type}?;
		vararg:          Variable?;

		!! class_type:    <RECURSION 0x0072f838>
	}
}

return <0x01800678>{
	-- Types:
	typedef AssignmentStatement = <0x0124a168>{
		ast_type: "AssignmentStatement";
		lhs:      [ExprNode];
		rhs:      [ExprNode];
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef BinopExpr = <0x01242570>{
		ast_type: "BinopExpr";
		lhs:      ExprNode;
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef BooleanExpr = <0x012412e0>{
		ast_type: "BooleanExpr";
		tokens:   [Token];
		value:    bool;
		where:    string;
	};
	typedef BreakStatement = <0x01251aa8>{
		ast_type: "BreakStatement";
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef CallExpr = <0x01243c38>{
		arguments: [ExprNode];
		ast_type:  "CallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef CallStatement = <0x0124aa68>{
		ast_type:   "CallStatement";
		expression: ExprNode;
		scope:      Scope?;
		tokens:     [Token];
		where:      string;
	};
	typedef CastExpr = <0x01249340>{
		ast_type: "CastExpr";
		expr:     ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ClassDeclStatement = <0x0124c308>{
		ast_type: "ClassDeclStatement";
		is_local: bool;
		name:     string;
		rhs:      ExprNode;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef ConstructorExpr = <0x01248520>{
		ast_type:   "ConstructorExpr";
		entry_list: [ConstructorExprEntry];
		tokens:     [Token];
		where:      string;
	};
	typedef DoStatement = <0x0124e090>{
		ast_type: "DoStatement";
		body:     Statlist;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef DotsExpr = <0x01243648>{
		ast_type: "DotsExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Eof = <0x012539b8>{
		ast_type: "Eof";
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprNode = <0x0121e778>{
		ast_type: ExprType;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "ExternExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
	typedef ExternExpr = <0x01241f80>{
		ast_type: "ExternExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef FunctionDeclStatement = <0x01252528>{
		arguments:    [<0x01252d20>{
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
	typedef GenericForStatement = <0x0124e7a0>{
		ast_type:   "GenericForStatement";
		body:       Statlist;
		generators: [ExprNode];
		scope:      Scope?;
		tokens:     [Token];
		var_names:  [string];
		where:      string;
	};
	typedef GotoStatement = <0x01250c88>{
		ast_type: "GotoStatement";
		label:    string;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef IdExpr = <0x0121edc8>{
		ast_type: "IdExpr";
		name:     string;
		tokens:   [Token];
		variable: Variable;
		where:    string;
	};
	typedef IfStatement = <0x0124d140>{
		ast_type: "IfStatement";
		clauses:  [IfStatementClause];
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef IndexExpr = <0x01245618>{
		ast_type: "IndexExpr";
		base:     ExprNode;
		index:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef LabelStatement = <0x012505d8>{
		ast_type: "LabelStatement";
		label:    string;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef LambdaFunctionExpr = <0x012466f0>{
		arguments:    [<0x012469b8>{
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
	typedef MemberExpr = <0x01245e58>{
		ast_type: "MemberExpr";
		base:     ExprNode;
		ident:    string;
		indexer:  string;
		tokens:   [Token];
		where:    string;
	};
	typedef NilExpr = <0x01241990>{
		ast_type: "NilExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Node = <0x0121d7e0>{
		ast_type: NodeType;
		tokens:   [Token];
		where:    string;
	};
	typedef NodeType = ExprType or StatType or "Statlist";
	typedef NumberExpr = <0x0121f548>{
		ast_type: "NumberExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef NumericForStatement = <0x0124f158>{
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
	typedef ParenthesesExpr = <0x01248c30>{
		ast_type: "ParenthesesExpr";
		inner:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef RepeatStatement = <0x0124fd98>{
		ast_type:  "RepeatStatement";
		body:      Statlist;
		condition: ExprNode;
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};
	typedef ReturnStatement = <0x01251338>{
		arguments: [ExprNode];
		ast_type:  "ReturnStatement";
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};
	typedef StatNode = <0x01249a50>{
		ast_type: StatType;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
	typedef Statlist = <0x0121e008>{
		ast_type: "Statlist";
		body:     [StatNode];
		tokens:   [Token];
		where:    string;
	};
	typedef StringCallExpr = <0x01244d78>{
		arguments: [StringExpr];
		ast_type:  "StringCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef StringExpr = <0x0121fbf8>{
		ast_type: "StringExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef TableCallExpr = <0x012444d8>{
		arguments: [ConstructorExpr];
		ast_type:  "TableCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef Typedef = <0x01253fa8>{
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
	typedef UnopExpr = <0x01242e68>{
		ast_type: "UnopExpr";
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef VarDeclareStatement = <0x0124b178>{
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
	typedef WhileStatement = <0x0124d850>{
		ast_type:  "WhileStatement";
		body:      Statlist;
		condition: ExprNode;
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};

	-- Members:
	LUA_SETTINGS: <0x017e87b8>{
	              	function_types: false;
	              	is_sol:         false;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	SOL_SETTINGS: <0x017f4058>{
	              	function_types: true;
	              	is_sol:         true;
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}