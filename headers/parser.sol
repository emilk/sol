-- Compiled from sol/parser.sol on 2013 Sep 29  22:57:03

return <0x0135a150>{
	-- Types:
	typedef AssignmentStatement = <0x006d7f28>{
		ast_type: "AssignmentStatement";
		lhs:      [ExprNode];
		rhs:      [ExprNode];
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef BinopExpr = <0x006bcb70>{
		ast_type: "BinopExpr";
		lhs:      ExprNode;
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef BooleanExpr = <0x00659938>{
		ast_type: "BooleanExpr";
		tokens:   [Token];
		value:    bool;
		where:    string;
	};
	typedef BreakStatement = <0x004f1f30>{
		ast_type: "BreakStatement";
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef CallExpr = <0x006d06f8>{
		arguments: [ExprNode];
		ast_type:  "CallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef CallStatement = <0x006e5e28>{
		ast_type:   "CallStatement";
		expression: ExprNode;
		scope:      Scope?;
		tokens:     [Token];
		where:      string;
	};
	typedef CastExpr = <0x006742a0>{
		ast_type: "CastExpr";
		expr:     ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef ClassDeclStatement = <0x00600638>{
		ast_type: "ClassDeclStatement";
		is_local: bool;
		name:     string;
		rhs:      ExprNode;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef ConstructorExpr = <0x00665730>{
		ast_type:   "ConstructorExpr";
		entry_list: [ConstructorExprEntry];
		tokens:     [Token];
		where:      string;
	};
	typedef DoStatement = <0x006c1298>{
		ast_type: "DoStatement";
		body:     Statlist;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef DotsExpr = <0x006c96c8>{
		ast_type: "DotsExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Eof = <0x00706540>{
		ast_type: "Eof";
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprNode = <0x006003e0>{
		ast_type: ExprType;
		tokens:   [Token];
		where:    string;
	};
	typedef ExprType = "IdExpr" or "NumberExpr" or "StringExpr" or "BooleanExpr" or "NilExpr" or "ExternExpr" or "BinopExpr" or "UnopExpr" or "DotsExpr" or "CallExpr" or "TableCallExpr" or "StringCallExpr" or "IndexExpr" or "MemberExpr" or "LambdaFunctionExpr" or "ConstructorExpr" or "ParenthesesExpr" or "CastExpr";
	typedef ExternExpr = <0x006b39f0>{
		ast_type: "ExternExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef FunctionDeclStatement = <0x00635920>{
		arguments:    [<0x00638da8>{
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
	typedef GenericForStatement = <0x006d6e08>{
		ast_type:   "GenericForStatement";
		body:       Statlist;
		generators: [ExprNode];
		scope:      Scope?;
		tokens:     [Token];
		var_names:  [string];
		where:      string;
	};
	typedef GotoStatement = <0x0068ac98>{
		ast_type: "GotoStatement";
		label:    string;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef IdExpr = <0x00601808>{
		ast_type: "IdExpr";
		name:     string;
		tokens:   [Token];
		variable: Variable;
		where:    string;
	};
	typedef IfStatement = <0x00678518>{
		ast_type: "IfStatement";
		clauses:  [IfStatementClause];
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef IndexExpr = <0x005e0b40>{
		ast_type: "IndexExpr";
		base:     ExprNode;
		index:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef LabelStatement = <0x0038af40>{
		ast_type: "LabelStatement";
		label:    string;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef LambdaFunctionExpr = <0x00671f38>{
		arguments:    [<0x005e4fb8>{
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
	typedef MemberExpr = <0x005ea040>{
		ast_type: "MemberExpr";
		base:     ExprNode;
		ident:    string;
		indexer:  string;
		tokens:   [Token];
		where:    string;
	};
	typedef NilExpr = <0x006a0088>{
		ast_type: "NilExpr";
		tokens:   [Token];
		where:    string;
	};
	typedef Node = <0x005f9f68>{
		ast_type: NodeType;
		tokens:   [Token];
		where:    string;
	};
	typedef NodeType = ExprType or StatType or "Statlist";
	typedef NumberExpr = <0x0061a670>{
		ast_type: "NumberExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef NumericForStatement = <0x0109f6d0>{
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
	typedef ParenthesesExpr = <0x0066d018>{
		ast_type: "ParenthesesExpr";
		inner:    ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef RepeatStatement = <0x006aa708>{
		ast_type:  "RepeatStatement";
		body:      Statlist;
		condition: ExprNode;
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};
	typedef ReturnStatement = <0x006285a8>{
		arguments: [ExprNode];
		ast_type:  "ReturnStatement";
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};
	typedef StatNode = <0x00676de8>{
		ast_type: StatType;
		scope:    Scope?;
		tokens:   [Token];
		where:    string;
	};
	typedef StatType = "AssignmentStatement" or "CallStatement" or "VarDeclareStatement" or "IfStatement" or "WhileStatement" or "DoStatement" or "RepeatStatement" or "GenericForStatement" or "NumericForStatement" or "ReturnStatement" or "BreakStatement" or "LabelStatement" or "GotoStatement" or "FunctionDeclStatement" or "Typedef" or "ClassDeclStatement" or "Eof";
	typedef Statlist = <0x005fd598>{
		ast_type: "Statlist";
		body:     [StatNode];
		tokens:   [Token];
		where:    string;
	};
	typedef StringCallExpr = <0x006e8240>{
		arguments: [StringExpr];
		ast_type:  "StringCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef StringExpr = <0x0063a970>{
		ast_type: "StringExpr";
		tokens:   [Token];
		value:    string;
		where:    string;
	};
	typedef TableCallExpr = <0x006dcfa8>{
		arguments: [ConstructorExpr];
		ast_type:  "TableCallExpr";
		base:      ExprNode;
		tokens:    [Token];
		where:     string;
	};
	typedef Typedef = <0x00683e90>{
		ast_type:       "Typedef";
		base_types:     [Type]?;
		is_local:       bool;
		namespace_name: string?;
		scope:          Scope?;
		tokens:         [Token];
		type:           Type?;
		type_name:      string;
		where:          string;
	};
	typedef UnopExpr = <0x006c4c70>{
		ast_type: "UnopExpr";
		op:       string;
		rhs:      ExprNode;
		tokens:   [Token];
		where:    string;
	};
	typedef VarDeclareStatement = <0x005d9f88>{
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
	typedef WhileStatement = <0x00681440>{
		ast_type:  "WhileStatement";
		body:      Statlist;
		condition: ExprNode;
		scope:     Scope?;
		tokens:    [Token];
		where:     string;
	};

	-- Members:
	LUA_SETTINGS: <0x012f7560>{
	              	function_types: false;
	              	is_sol:         false;
	              	issues:         {"unused-parameter" or "unused-loop-variable" or "unused-variable" or "unassigned-variable" => "SPAM" or "WARNING"};
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	SOL_SETTINGS: <0x01621d70>{
	              	function_types: true;
	              	is_sol:         true;
	              	issues:         {"unused-parameter" or "unused-loop-variable" or "unused-variable" or "unassigned-variable" => "WARNING" or "ERROR"};
	              	keywords:       {string};
	              	symbols:        {string};
	              };
	parse_sol:    function(src: string, tok, filename: string?, settings, module_scope) -> false or true, Statlist or string;
}