--
-- parse_sol.lua
-- parse_sol taken in a token stream (from the lexer)
-- and outputs an AST.
-- It keeps track of scoping and variables.


local L = require 'lexer'
local D = require 'sol_debug'
local S = require 'scope'
local T = require 'type' -- For intrinsic functions
local U = require 'util'

local printf_err = U.printf_err
local set        = U.set

local P = {}


P.LUA_SETTINGS = {
	-- Lexer:
	symbols = set{
		'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#',
		':', '::', '>', '<', '=', '==', '~=', '>=', '<=',
	};

	keywords = set{
		'and',    'break', 'do',   'else',     'elseif',
		'end',    'false', 'for',  'function', 'goto', 'if',
		'in',     'local', 'nil',  'not',      'or',   'repeat',
		'return', 'then',  'true', 'until',    'while',
	};


	-- Sol extensions all off:
	is_sol         = false;
	function_types = false;

	-- Enabled warnings - names matches GCC - http://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
	issues = {
		['unused-parameter']     = 'SPAM';
		['unused-loop-variable'] = 'SPAM';
		['unused-variable']      = 'WARNING';
		['unassigned-variable']  = 'WARNING';

		['nil-init']             = 'SPAM';

		['nil-ends-list'] = 'WARNING';  -- { 42, nil }
		['nil-in-list']   = 'WARNING';  -- { nil, 42 }
	}
}

P.SOL_SETTINGS = {
	-- Lexer:
	symbols = set{
		'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#',
		':', '::', '>', '<', '=', '==', '~=', '>=', '<=',
		'->', '=>', '?', '+=', '-=', '*=', '/=', '..=', '#='
	};

	keywords = set{
		'and',    'break', 'do',   'else',     'elseif',
		'end',    'false', 'for',  'function', 'goto', 'if',
		'in',     'local', 'nil',  'not',      'or',   'repeat',
		'return', 'then',  'true', 'until',    'while',

		-- Sol specific:
		'typedef', 'global', 'var', 'class', 'extern',
	};


	-- Parser:
	is_sol         = true;
	function_types = true;  -- Support  foo(arg : int) -> int

	-- Enabled warnings - names matches GCC - http://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
	issues = {
		['unused-parameter']     = 'WARNING';
		['unused-loop-variable'] = 'WARNING';
		['unused-variable']      = 'WARNING';
		['unassigned-variable']  = 'ERROR';

		['nil-init']             = 'WARNING';

		['nil-ends-list'] = 'ERROR';  -- { 42, nil }
		['nil-in-list']   = 'ERROR';  -- { nil, 42 }
	}
}


local stat_list_close_keywords = set{'end', 'else', 'elseif', 'until'}


--------------------------------------------------------

typedef P.ExprType = 'IdExpr' or 'NumberExpr' or 'StringExpr' or 'BooleanExpr' or 'NilExpr' or 'ExternExpr'
                  or 'BinopExpr' or 'UnopExpr' or 'DotsExpr'
                  or 'CallExpr' or 'TableCallExpr' or 'StringCallExpr'
                  or 'IndexExpr' or 'MemberExpr' or 'LambdaFunctionExpr'
                  or 'ConstructorExpr' or 'ParenthesesExpr'
                  or 'CastExpr'

typedef P.StatType = 'AssignmentStatement' or 'CallStatement' or 'VarDeclareStatement'
                  or 'IfStatement' or 'WhileStatement' or 'DoStatement' or 'RepeatStatement'
                  or 'GenericForStatement' or 'NumericForStatement'
                  or 'ReturnStatement' or 'BreakStatement' or 'LabelStatement' or 'GotoStatement'
                  or 'FunctionDeclStatement'
                  or 'Typedef' or 'ClassDeclStatement'
                  or 'Eof'

typedef P.NodeType = P.ExprType or P.StatType or 'Statlist'

-- General AstNode:
typedef P.Node = {
	ast_type: P.NodeType;
	tokens:   [L.Token];
	where:    string;
}

typedef P.Statlist : P.Node = {
	ast_type: 'Statlist';
	body:     [P.StatNode];
}

---------------------------------------------

typedef P.ExprNode : P.Node = {
	ast_type: P.ExprType
}

typedef P.IdExpr : P.ExprNode = {
	ast_type: 'IdExpr';
	name:     string;
	variable: Variable;  -- Set by type_check
}

typedef P.NumberExpr : P.ExprNode = {
	ast_type: 'NumberExpr';
	value:    string;
}

typedef P.StringExpr : P.ExprNode = {
	ast_type: 'StringExpr';
	value:    string;
}

typedef P.BooleanExpr : P.ExprNode = {
	ast_type: 'BooleanExpr';
	value:    bool;
}

typedef P.NilExpr : P.ExprNode = {
	ast_type: 'NilExpr';
}

typedef P.ExternExpr : P.ExprNode = {
	ast_type: 'ExternExpr';
}

typedef P.BinopExpr : P.ExprNode = {
	ast_type: 'BinopExpr';
	lhs:      P.ExprNode;
	op:       string;
	rhs:      P.ExprNode;
}

typedef P.UnopExpr : P.ExprNode = {
	ast_type: 'UnopExpr';
	op:       string;
	rhs:      P.ExprNode;
}

typedef P.DotsExpr : P.ExprNode = {
	ast_type: 'DotsExpr';
}

typedef P.CallExpr : P.ExprNode = {
	ast_type:  'CallExpr';
	base:      P.ExprNode;
	arguments: [P.ExprNode];
}

typedef P.TableCallExpr : P.ExprNode = {
	ast_type:  'TableCallExpr';
	base:      P.ExprNode;
	arguments: [P.ConstructorExpr];
}

typedef P.StringCallExpr : P.ExprNode = {
	ast_type:  'StringCallExpr';
	base:      P.ExprNode;
	arguments: [P.StringExpr];
}

typedef P.IndexExpr : P.ExprNode = {
	ast_type:  'IndexExpr';
	base:      P.ExprNode;
	index:     P.ExprNode;
}

typedef P.MemberExpr : P.ExprNode = {
	ast_type:  'MemberExpr';
	base:      P.ExprNode;
	indexer:   string;
	ident:     string;
}

typedef P.LambdaFunctionExpr : P.ExprNode = {
	ast_type:     'LambdaFunctionExpr';
	is_mem_fun:   bool;
	arguments:    [ {
	              	name: string;
	              	type: T.Type?;
	              } ];
	vararg:       T.VarArgs?;
	return_types: [T.Type]?;
	body:         P.Statlist?;  -- nil means header only, used by lua_intrinsics.sol
}

typedef ConstructorExprEntry = {
	type:  'key'      or 'ident_key' or 'value';
	key:   P.ExprNode or string      or nil;
	value: P.ExprNode;
}

typedef P.ConstructorExpr : P.ExprNode = {
	ast_type:   'ConstructorExpr';
	entry_list: [ ConstructorExprEntry ];
}

typedef P.ParenthesesExpr : P.ExprNode = {
	ast_type: 'ParenthesesExpr';
	inner:    P.ExprNode;
}

typedef P.CastExpr : P.ExprNode = {
	ast_type: 'CastExpr';
	expr:     P.ExprNode;
}

---------------------------------------------

typedef P.StatNode : P.Node = {
	ast_type: P.StatType;
	scope:    Scope?;  -- TODO: remove?
}

typedef P.AssignmentStatement : P.StatNode = {
	ast_type: 'AssignmentStatement';
	lhs:      [P.ExprNode];
	rhs:      [P.ExprNode];
}

typedef P.CallStatement : P.StatNode = {
	ast_type:   'CallStatement';
	expression: P.ExprNode;
}

typedef P.VarDeclareStatement : P.StatNode = {
	ast_type:  'VarDeclareStatement';
	scoping:   'local' or 'global' or 'var';
	is_local:  bool;
	type_list: [T.Type]?;
	--type_list: T.Typelist?;  -- FIXME: doesn't work, but the equivalent above does
	name_list: [string];
	init_list: [P.ExprNode];
}

typedef P.ClassDeclStatement : P.StatNode = {
	ast_type:  'ClassDeclStatement';
	is_local:  bool;
	name:      string;
	rhs:       P.ExprNode;
}

typedef IfStatementClause = {
	condition: P.ExprNode?;
	body:      P.Statlist;
}

typedef P.IfStatement : P.StatNode = {
	ast_type:  'IfStatement';
	clauses:   [IfStatementClause];
}

typedef P.WhileStatement : P.StatNode = {
	ast_type:  'WhileStatement';
	condition: P.ExprNode;
	body:      P.Statlist;
}

typedef P.DoStatement : P.StatNode = {
	ast_type:  'DoStatement';
	body:      P.Statlist;
}

typedef P.GenericForStatement : P.StatNode = {
	ast_type:   'GenericForStatement';
	-- for
	var_names:  [string];
	-- in
	generators: [P.ExprNode];
	-- do
	body:       P.Statlist;
	-- end
}

typedef P.NumericForStatement : P.StatNode = {
	ast_type: 'NumericForStatement';
	-- for
	var_name: string;
	-- =
	start:    P.ExprNode;
	-- ,
	end_:     P.ExprNode;
	-- ,
	step:     P.ExprNode?;
	-- do
	body:     P.Statlist;
	-- end
}

typedef P.RepeatStatement : P.StatNode = {
	ast_type:  'RepeatStatement';
	body:      P.Statlist;
	condition: P.ExprNode;
}

typedef P.LabelStatement : P.StatNode = {
	ast_type: 'LabelStatement';
	label:    string;
}

typedef P.GotoStatement : P.StatNode = {
	ast_type: 'GotoStatement';
	label:    string;
}

typedef P.ReturnStatement : P.StatNode = {
	ast_type:  'ReturnStatement';
	arguments: [P.ExprNode];
}

typedef P.BreakStatement : P.StatNode = {
	ast_type:  'BreakStatement';
}

typedef P.FunctionDeclStatement : P.StatNode = {
	ast_type:     'FunctionDeclStatement';
	scoping:      'local' or 'global' or '';
	is_mem_fun:   bool;
	is_aggregate: bool;   -- true: function foo.bar(...)
	name_expr:    P.ExprNode;
	arguments:    [ {
	              	name: string;
	              	type: T.Type?;
	              } ];
	vararg:       T.VarArgs?;
	body:         P.Statlist;
}

typedef P.Eof : P.StatNode = {
	ast_type:     'Eof';
}

typedef P.Typedef : P.StatNode = {
	ast_type:       'Typedef';
	namespace_name: string?;
	type_name:      string;
	is_local:       bool;
	base_types:     [T.Type]?;  -- Inherits
	type:           T.Type?;  -- nil == forward declare (TODO)
}

---------------------------------------------

typedef ExprNode_or_error = P.ExprNode or string or nil
typedef StatNode_or_error = P.StatNode or string or nil
 
typedef TokenList = L.TokenList


--------------------------------------------------------

function P.parse_sol(src: string, tok, filename: string?, settings, module_scope: Scope) -> bool, P.Statlist or string
	filename = filename or ''
	settings = settings or P.SOL_SETTINGS
	local num_err = 0

	--
	local function where_am_i(offset: int?) -> string
		local token = tok:peek(offset)
		return filename .. ":" .. token.line
	end

	local function generate_msg(msg_fmt: string, ...) -> string
		local msg = string.format(msg_fmt, ...)
		--local err = ">> :"..tok:peek().line..":"..tok:peek().char..": "..msg.."\n"
		local err = "solc: "..where_am_i(-1)..": "..msg.."\n"
		--find the line
		local line_num = 0
		for line in src:gmatch("[^\n]*\n?") do
			if line:sub(-1,-1) == '\n' then line = line:sub(1,-2) end
			line_num = line_num+1
			if line_num == tok:peek().line then
				err = err..">> `"..line:gsub('\t','    ').."`\n"
				for i = 1, tok:peek().char do
					local c = line:sub(i,i)
					if c == '\t' then
						err = err..'    '
					else
						err = err..' '
					end
				end
				if not tok:peek().data then
					err = err.."   ^^^^"
				else
					err = err.."   ^"
					for i = 2, #tok:peek().data do
						err = err.."^"
					end
				end
				break
			end
		end

		return err
	end

	local function report_error(msg_fmt: string, ...) -> string
		num_err +=  1
		local msg = generate_msg(msg_fmt, ...)
		printf_err("%s", msg)
		return msg
	end

	local function report_warning(msg_fmt: string, ...) -> string
		if _G.g_warnings_as_errors then
			return report_error(msg_fmt, ...)
		else
			local msg = generate_msg(msg_fmt, ...)
			print( msg )
			return msg
		end
	end

	local function report_spam(msg_fmt: string, ...) -> void
		if _G.g_spam then
			local msg = generate_msg(msg_fmt, ...)
			print( msg )
		end
	end

	local function report_sol_error(msg_fmt: string, ...) -> void
		if settings.is_sol then
			report_error(msg_fmt, ...)
		else
			report_warning(msg_fmt, ...)
		end
	end


	local function create_scope(parent: Scope) -> Scope
		local scope = Scope.new(where_am_i(), parent)
		--report_spam("New scope %s, parent: %s", tostring(scope), tostring(parent))
		return scope
	end


	local parse_statement_list
	local parse_simple_expr, 
	      parse_expr,
	      parse_primary_expr,
	      parse_suffixed_expr,
	      parse_simple_type,
	      parse_type,
	      parse_type_list,
	      parse_type_args


	-- is_mem_fun: we where declared like  foo:fun(args)  and thus have an implicit 'self'
	local function parse_function_args_and_body(scope: Scope, token_list: TokenList, type: 'mem_fun'?)
						-> bool, string or { where: string }

		local is_mem_fun = (type == 'mem_fun')
		local where = where_am_i()

		local func_scope = create_scope(scope)
		if not tok:consume_symbol('(', token_list) then
			return false, report_error("`(` expected.")
		end

		typedef ArgInfo = {
			name: string;
			type: T.Type?;
		}
		var arg_list = {}  : [ArgInfo]
		var vararg   = nil : T.VarArgs?

		while not tok:consume_symbol(')', token_list) do
			if tok:is('ident') then
				local arg = {
					name = tok:get(token_list).data
				}

				if settings.function_types and tok:consume_symbol(':') then
					arg.type = parse_type(func_scope)
					if not arg.type then
						return false, report_error("type expected.")
					end
				end

				arg_list #= arg

				if not tok:consume_symbol(',', token_list) then
					if tok:consume_symbol(')', token_list) then
						break
					else
						return false, report_error("`)` expected.")
					end
				end
			elseif tok:consume_symbol('...', token_list) then
				var elem_type = T.Any : T.Type?

				if settings.function_types and tok:consume_symbol(':') then
					elem_type = parse_type(func_scope)
					if not elem_type then
						return false, report_error("type expected.")
					end
				end

				var var_arg_type = {
					tag  = 'varargs',
					type = elem_type,
				}
				vararg = var_arg_type

				if not tok:consume_symbol(')', token_list) then
					return false, report_error("`...` must be the last argument of a function.")
				end
				break
			else
				return false, report_error("Argument name or `...` expected")
			end
		end

		var return_types = nil : T.Typelist?

		if settings.function_types and tok:consume_symbol('->') then
			return_types = parse_type_list(func_scope)
		end

		local st,body

		if tok:consume_symbol('=') and tok:consume_keyword('extern') then
			-- extern - used by lua_intrinsics.sol
		else
			--body
			st, body = parse_statement_list(func_scope)
			if not st then return false, body end

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected after function body in %s", where)
			end
		end

		local node_func = {
			--ast_type     = 'Function', LambdaFunctionExpr or FunctionDeclStatement
			scope        = func_scope,
			tokens       = token_list,
			is_mem_fun   = is_mem_fun,
			arguments    = arg_list,
			vararg       = vararg,
			return_types = return_types,
			body         = body,
			where        = where,
		}

		return true, node_func
	end


	local function parse_id_expr() -> ExprNode_or_error
		assert(tok:is('ident'))

		local token_list = {}
		var where = where_am_i()
		local name = tok:get(token_list).data

		return {
			ast_type = 'IdExpr';
			name     = name;
			tokens   = token_list;
			where    = where;
		}
	end

	parse_primary_expr = function(scope: Scope) -> bool, ExprNode_or_error
		local token_list = {}
		var where = where_am_i()

		if tok:consume_symbol('(', token_list) then
			local st, ex = parse_expr(scope)
			if not st then return false, ex end
			if not tok:consume_symbol(')', token_list) then
				return false, report_error("`)` Expected.")
			end

			local parens_exp = {
				ast_type = 'ParenthesesExpr';
				inner    = ex;
				tokens   = token_list;
				where    = where;
			}
			return true, parens_exp

		elseif tok:is('ident') then
			return true, parse_id_expr()
		else
			return false, report_error("primary expression expected")
		end
	end


	parse_suffixed_expr = function(scope: Scope, style: 'only_dot_colon' or nil) -> bool, ExprNode_or_error
		var only_dot_colon = (style == 'only_dot_colon')

		--base primary expression
		local st, prim = parse_primary_expr(scope)
		if not st then return false, prim end
		--
		while true do
			local token_list = {}
			local where = where_am_i()

			if tok:is_symbol('.') or
				   (tok:is_symbol(':') and tok:peek().leading_white=="")
		   then
				local symb = tok:get(token_list).data
				if not tok:is('ident') then
					return false, report_error("<ident> expected.")
				end
				local id = tok:get(token_list)
				local node_index = {}
				node_index.ast_type  = 'MemberExpr'
				node_index.base     = prim
				node_index.indexer  = symb
				node_index.ident    = id
				node_index.tokens   = token_list
				node_index.where    = where
				--
				prim = node_index

			elseif not only_dot_colon and tok:consume_symbol('[', token_list) then
				local st, ex = parse_expr(scope)
				if not st then return false, ex end
				if not tok:consume_symbol(']', token_list) then
					return false, report_error("`]` expected.")
				end
				local node_index = {}
				node_index.ast_type  = 'IndexExpr'
				node_index.base     = prim
				node_index.index    = ex
				node_index.tokens   = token_list
				node_index.where    = where
				--
				prim = node_index

			elseif not only_dot_colon and tok:consume_symbol('(', token_list) then
				var args = {} : [P.ExprNode]
				while not tok:consume_symbol(')', token_list) do
					local st, ex = parse_expr(scope)
					if not st then return false, ex end
					args #= ex
					if not tok:consume_symbol(',', token_list) then
						if tok:consume_symbol(')', token_list) then
							break
						else
							return false, report_error("`)` Expected.")
						end
					end
				end
				local node_call = {}
				node_call.ast_type  = 'CallExpr'
				node_call.base      = prim
				node_call.arguments = args
				node_call.tokens    = token_list
				node_call.where     = where
				--
				prim = node_call

			elseif not only_dot_colon and tok:is('String') then
				--string call
				local st, ex = parse_simple_expr(scope)
				if not st then return false, ex end
				local node_call = {}
				node_call.ast_type  = 'StringCallExpr'
				node_call.base      = prim
				--node_call.arguments  = { tok:get(token_list) }
				node_call.arguments = { ex }
				node_call.tokens    = token_list
				node_call.where     = where
				--
				prim = node_call

			elseif not only_dot_colon and tok:is_symbol('{') then
				--table call
				local st, ex = parse_simple_expr(scope)
				-- FIX: parse_expr(scope) parses the table AND and any following binary expressions.
				-- We just want the table
				if not st then return false, ex end
				local node_call = {}
				node_call.ast_type  = 'TableCallExpr'
				node_call.base      = prim
				node_call.arguments = { ex }
				node_call.tokens    = token_list
				node_call.where     = where
				--
				prim = node_call

			else
				break
			end
		end
		return true, prim
	end


	parse_simple_expr = function(scope) -> bool, ExprNode_or_error
		var token_list = {}  : TokenList
		var node       = nil : object?
		var where      = where_am_i()

		if tok:is('Number') then
			node = {
				ast_type = 'NumberExpr';
				value    = tok:get(token_list).data;
				tokens   = token_list;
			}

		elseif tok:is('String') then
			node = {
				ast_type = 'StringExpr';
				value    = tok:get(token_list).data;
				tokens   = token_list;
			}

		elseif tok:consume_keyword('nil', token_list) then
			node = {
				ast_type = 'NilExpr';
				tokens   = token_list;
			}

		elseif tok:consume_keyword('extern', token_list) then
			node = {
				ast_type = 'ExternExpr';
				tokens   = token_list;
			}

		elseif tok:is_keyword('false') or tok:is_keyword('true') then
			node = {
				ast_type = 'BooleanExpr';
				value    = (tok:get(token_list).data == 'true');
				tokens   = token_list;
			}

		elseif tok:consume_symbol('...', token_list) then
			node = {
				ast_type = 'DotsExpr';
				tokens   = token_list;
			}

		elseif tok:consume_symbol('{', token_list) then
			--var entry_list = {} : [ConstructorExprEntry] -- TODO
			var entry_list = {} : [any]
			--
			while true do
				if tok:is_symbol('[', token_list) then
					--key
					tok:get(token_list)
					local st, key = parse_expr(scope)
					if not st then
						return false, report_error("key expression Expected")
					end
					if not tok:consume_symbol(']', token_list) then
						return false, report_error("`]` Expected")
					end
					if not tok:consume_symbol('=', token_list) then
						return false, report_error("`=` Expected")
					end
					local st, value = parse_expr(scope)
					if not st then
						return false, report_error("value expression Expected")
					end
					entry_list #= {
						type  = 'key';
						key   = key;
						value = value;
					}

				elseif tok:is('ident') then
					--value or key
					local lookahead = tok:peek(1)
					if lookahead.type == 'Symbol' and lookahead.data == '=' then
						--we are a key
						local key = tok:get(token_list)
						if not tok:consume_symbol('=', token_list) then
							return false, report_error("`=` Expected")
						end
						local st, value = parse_expr(scope)
						if not st then
							return false, report_error("value expression Expected")
						end
						entry_list #= {
							type  = 'ident_key';
							key   = key.data;
							value = value;
						}

					else
						--we are a value
						local st, value = parse_expr(scope)
						if not st then
							return false, report_error("value Exected")
						end
						entry_list #= {
							type = 'value';
							value = value;
						}

					end
				elseif tok:consume_symbol('}', token_list) then
					break

				else
					--value
					local st, value = parse_expr(scope)
					entry_list #= {
						type = 'value';
						value = value;
					}
					if not st then
						return false, report_error("value Expected")
					end
				end

				if tok:consume_symbol(';', token_list) or tok:consume_symbol(',', token_list) then
					--all is good
				elseif tok:consume_symbol('}', token_list) then
					break
				else
					return false, report_error("`}` or table entry expected")
				end
			end

			node = {
				ast_type   = 'ConstructorExpr';
				entry_list = entry_list;
				tokens     = token_list;
			}

		elseif tok:consume_keyword('function', token_list) then
			-- Parse lambda
			local st, lambda_node = parse_function_args_and_body(scope, token_list)
			if not st then return false, lambda_node end
			--
			node = lambda_node
			node.ast_type = 'LambdaFunctionExpr'
		end

		if node then
			node.where = where
			return true, node
		else
			return parse_suffixed_expr(scope)
		end
	end


	var unops = set{'-', 'not', '#'}
	var unopprio = 8
	var priority = {
		['+']   = {6,6};
		['-']   = {6,6};
		['%']   = {7,7};
		['/']   = {7,7};
		['*']   = {7,7};
		['^']   = {10,9};
		['..']  = {5,4};
		['==']  = {3,3};
		['<']   = {3,3};
		['<=']  = {3,3};
		['~=']  = {3,3};
		['>']   = {3,3};
		['>=']  = {3,3};
		['and'] = {2,2};
		['or']  = {1,1};
	}

	var assign_op = {
		['+=']  = '+',
		['-=']  = '-',
		['*=']  = '*',
		['/=']  = '/',
		['..='] = '..',
	}

	parse_expr = function(scope: Scope, prio_level: int?) -> bool, ExprNode_or_error
		prio_level = prio_level or 0

		var st    = false
		var exp   = nil : object?
		var where = where_am_i()

		--base item, possibly with unop prefix
		if unops[tok:peek().data] then
			local token_list = {}
			local op = tok:get(token_list).data
			st, exp = parse_expr(scope, unopprio)
			if not st then return false, exp end
			local node_ex = {
				ast_type = 'UnopExpr';
				rhs      = exp;
				op       = op;
				tokens   = token_list;
			}
			exp = node_ex
		else
			st, exp = parse_simple_expr(scope)
			if not st then return false, exp end
		end

		--next items in chain
		while true do
			local prio = priority[tok:peek().data]
			if prio and prio[1] > prio_level then
				local token_list = {}
				local op = tok:get(token_list).data
				local st, rhs = parse_expr(scope, prio[2])
				if not st then return false, rhs end
				local node_ex = {
					ast_type = 'BinopExpr';
					lhs      = exp;
					op       = op;
					rhs      = rhs;
					tokens   = token_list;
				}
				--
				exp = node_ex
			else
				break
			end
		end

		exp.where = exp.where or where

		if #tok:peek().leading_white>0 and tok:consume_symbol(':') then
			-- A cast

			var where = where_am_i()

			var type = parse_type(scope)
			if not type then
				return false, report_error("Bad cast, expected  'expr : type'")
			end

			return true, {
				ast_type = 'CastExpr',
				where    = where,
				tokens   = {},
				expr     = exp,
				type     = type,
			}
		else
			return true, exp
		end
	end


	parse_simple_type = function(scope) -> T.Type?
		local where = where_am_i()

		if tok:consume_symbol('[') then
			local type = parse_type(scope)
			if not type then
				report_error("Expected type in list declaration, e.g. [int]")
				tok:consume_symbol(']')
				return T.Any
			end

			if not tok:consume_symbol(']') then
				report_error("Missing ']' after list declaration")
				return T.Any
			end

			return {
				tag  = "list",
				type = type
			}
		end

		if tok:consume_symbol('{') then
			-- Object or map?
			if tok:consume_symbol('}') then
				report_error("Use 'object'")
				return T.create_empty_table()

			elseif tok:is('ident')
			   and tok:peek(1).data == ':'
			   --and #tok:peek(1).leading_white > 0
			then
				-- key-value-pairs - an object
				var obj = {
					tag     = 'object',
					members = {}
				} : T.Object
				while true do
					if tok:consume_symbol('}') then break end

					if not tok:is('ident') then
						report_error('Bad object: identifier expected')
						return T.Any
					end
					
					local id = tok:get().data

					if not tok:consume_symbol(':') then
						report_error("Bad object: expected ':'")
						return T.Any
					end

					local type = parse_type(scope)
					if not type then
						report_error("Bad object: expected type")
						return T.Any
					end

					if obj.members[id] then
						report_error("Object member '%s' declared twice", id)
					end

					obj.members[id] = type

					if not tok:consume_symbol(',') and not tok:consume_symbol(';') then
						if tok:consume_symbol('}') then
							break
						else
							report_error("Bad object declaration: expected either , or }")
							return T.Any
						end
					end
				end
				--U.make_const(obj.members)
				return obj
			else
				-- a map or a set
				local key_type   = parse_type(scope)
				local sep        = tok:consume_symbol('=>')

				if sep then
					local value_type = parse_type(scope)
					local closing    = tok:consume_symbol('}')

					if not (key_type and sep and value_type and closing) then
						report_error("Expected map type on the form: {key_type => value_type}")
						return T.Any
					end

					return {
						tag        = 'map',
						key_type   = key_type,
						value_type = value_type
					}
				else
					local closing = tok:consume_symbol('}')

					if not (key_type and closing) then
						report_error("Expected set on the form { key_type } or a map on the form: {key_type => value_type}")
						return T.Any
					end

					return {
						tag        = 'map',
						key_type   = key_type,
						value_type = T.True
					}
				end
			end
		end

		if tok:consume_keyword('function') then
			-- function type
			if not tok:consume_symbol('(') then
				report_error("Expected (")
				return T.Any
			end

			var fun_t = {
				tag    = 'function',
				args   = {},
				vararg = nil ,--: T:VarArgs?,  -- TODO
				rets   = nil ,--: [T.Type]?,
				name   = '<lambda>',
			} : T.Function

			if not tok:consume_symbol(')') then
				while true do
					if tok:consume_symbol('...') then
						var var_arg_t = T.Any

						if tok:consume_symbol(':') then
							var_arg_t = parse_type(scope)
						end

						fun_t.vararg = { tag = 'varargs', type = var_arg_t }

						if not tok:consume_symbol(')') then
							report_error('vararg (...) must be last argument to function')
						end

						break
					end

					var arg_name = nil : string?
					if tok:is('ident') and tok:peek(1).data == ':' then
						-- named type
						arg_name = tok:get_ident()
						tok:get() -- Swallow ':'
					end

					local type = parse_type(scope)

					fun_t.args #= { name = arg_name, type = type }

					if not tok:consume_symbol(',') then
						if not tok:consume_symbol(')') then
							report_error('bad function syntax')
						end
						break
					end
				end
			end

			if tok:consume_symbol('->') then
				fun_t.rets = parse_type_list(scope)
			else
				fun_t.rets = T.Void
			end

			return fun_t
		end

		if tok:is('Number') then
			local str = tok:get().data
			local t = T.from_num_literal( str )
			if t then
				return t
			else
				report_error('Failed to parse number: %q', str)
				return T.Num
			end

		elseif tok:is('String') then
			return T.from_string_literal( tok:get().data )

		-- Handle keywords explicitly:
		elseif tok:consume_keyword('nil') then
			return T.Nil

		elseif tok:consume_keyword('true') then
			return T.True

		elseif tok:consume_keyword('false') then
			return T.False

		elseif tok:consume_keyword('extern') then
			return { tag = 'extern', where = where }

		elseif tok:is('ident') then
			local name = tok:get().data

			if tok:consume_symbol('.') then
				-- namespaced type
				if not tok:is('ident') then
					report_error("Identifier expected")
					return nil
				end

				local sub_name = tok:get().data

				return {
					tag         = 'identifier',
					scope       = scope,
					--var_       = var_,
					var_name    = name,
					name        = sub_name,
					first_usage = where,
				}
			else
				-- Local or global identifier
				return {
					tag         = 'identifier',
					scope       = scope,
					name        = name,
					first_usage = where,
				}
			end
		else
			return nil
		end
	end


	parse_type = function(scope) -> T.Type?
		local type = parse_simple_type(scope)

		if not type then return nil end

		if tok:consume_symbol('?') then
			--type = T.variant(type, T.Nil)   -- FIXME: isa doesn't work with typedef:s before CheckType
			type = {
				tag = 'variant',
				variants = { type, T.Nil }
			}
		end

		if tok:consume_keyword('or') then
			local rhs = parse_type(scope)
			--type = T.variant(type, rhs) -- FIXME: isa doesn't work with typedef:s before CheckType
			type = {
				tag = 'variant',
				variants = { type, rhs }
			}
		end

		return type
	end


	parse_type_list = function(scope) -> T.Typelist?
		if tok:peek().data == 'void' then
			tok:get()
			return T.Void
		end

		var list = nil : T.Typelist?
		while true do
			if tok:consume_symbol('...') then
				if false then  -- TODO: varargs as last thing returned by function
					var var_arg_t = T.Any

					if tok:consume_symbol(':') then
						var_arg_t = parse_type(scope)
					end

					local type = { tag = 'varargs', type = var_arg_t }
					list = list or {}
					list #= type
					return list  -- var-args must be last
				else
					return T.AnyTypeList -- FIXME HACK
				end
			end

			local type = parse_type(scope)
			if not type then
				return list
			end

			list = list or {}
			list #= type
			if not tok:consume_symbol(',') then
				return list
			end
		end
	end


	-- Parses a type-list within (and including) angle brackets: <int,string>
	parse_type_args = function(scope) -> T.Typelist?
		if tok:consume_symbol('<') then
			local list = parse_type_list(scope) or {}  -- Empty list OK
			if not tok:consume_symbol('>') then
				report_error("Missing '>'")
				return nil
			end
			return list
		else
			return nil -- No type-args here
		end
	end


	local function parse_typedef(scope: Scope, scoping: 'local' or 'global') -> bool, StatNode_or_error
		--[[ We allow:
		typedef foo = ...    -- Normal local typedef
		typedef M.bar = ...  -- namespaced typedef
		typedef foo;    -- Forward declaration
		typedef M.bar;  -- Forward declaration

		A namespaced typedef works like this:

		M must be a locally accessible object variable, which is now also a namespace.
		A namespace maps idendifiers to types.

		The namespace variable can be returned from a module, and the namespace will then also be propagated.

		module.sol:
		  local M = {}
		  typedef M.Foo = int
		  return M

		user.sol:
		  local Mod = require 'module'
		  var foo = {} : Mod.Foo
		--]]

		local where = where_am_i()

		if not tok:is('ident') then
			return false, report_error("Name expected")
		end
		local type_name = tok:get().data

		local node = { 
			ast_type  = 'Typedef',
			scope     = scope,
			type_name = type_name,
			tokens    = {},
			where     = where,
			is_local  = (scoping ~= 'global'),
		}

		if not tok:consume_symbol('.') then
			node.type_name  = type_name
		else
			if scoping == 'global' then
				return false, report_error("global typedef cannot have namespaced name")
			end

			local base_name = type_name

			type_name = tok:get_ident()
			if not type_name then
				return false, report_error("Identifier expected")
			end

			node.namespace_name = base_name
			node.type_name      = type_name
		end

		-- Are we a forward-declare?
		if not tok:consume_symbol(';') then
			local function parse_bases() -> T.Typelist?
				-- Check for inheritance
				var base_types = {} : T.Typelist
				if tok:consume_symbol(':') then
					repeat
						var t = parse_type(scope)
						if not t then
							report_error("base type expected")
							return nil
						end
						base_types #= t
					until not tok:consume_symbol(',')
				end

				return base_types
			end

			local function parse_type_assignment() -> T.Type?
				if not tok:consume_symbol('=') then
					report_error("Expected '='")
					return nil
				end

				var type = parse_type(scope)

				if not type then
					report_error("Expected type") 
					return nil
				end

				return type
			end

			var base_types = parse_bases()
			if not base_types then return false, report_error("base type(s) expected") end
			node.base_types = base_types

			var type = parse_type_assignment()
			if not type then return false, report_error("type assignment expected") end
			node.type = type
		end

		return true, node
	end


	local function parse_function_decl(scope: Scope, token_list: L.TokenList,
		                                scoping: 'local' or 'global') -> bool, StatNode_or_error

		if not tok:is('ident') then
			return false, report_error("Function name expected")
		end

		local name_expr = parse_id_expr()
		local st, func = parse_function_args_and_body(scope, token_list)
		if not st then return false, func end

		func.ast_type     = 'FunctionDeclStatement'
		func.name_expr    = name_expr
		func.is_aggregate = false
		func.is_local     = (scoping == 'local')
		func.scoping      = scoping
		return true, func
	end


	local function parse_declaration(scope: Scope, token_list: L.TokenList,
		                              scoping: 'local' or 'global' or 'var') -> bool, StatNode_or_error

		var is_local = (scoping ~= 'global')

		var where = where_am_i()
		var types = nil : T.Typelist?

		--[[
		--parse var<type>
		if scoping == 'var' then
			types = parse_type_args(scope)
		elseif parse_type_args(scope) then
			return false, report_error("%s cannot have type list - did you want 'var' ?")
		end
		--]]

		if types and #types == 0 then
			return false, report_error("Empty type list")
		end

		if not tok:is('ident') then
			return false, report_error("Variable name expected")
		end

		local name_list = { tok:get(token_list).data }
		while tok:consume_symbol(',', token_list) do
			if not tok:is('ident') then
				return false, report_error("local variable name expected")
			end
			name_list #= tok:get(token_list).data
		end

		var init_list = {} : [P.ExprNode]
		if tok:consume_symbol('=', token_list) then
			repeat
				local st, ex = parse_expr(scope)
				if not st then return false, ex end
				init_list #= ex
			until not tok:consume_symbol(',', token_list)
		end

		local node_local = {
			ast_type  = 'VarDeclareStatement';
			scoping   = scoping; -- 'local' or 'global' or 'var'
			is_local  = is_local;
			type_list = types;
			name_list = name_list;
			init_list = init_list;
			tokens    = token_list;
			where     = where;
		}
		--
		return true, node_local
	end


	local function parse_class(scope: Scope, token_list: TokenList, scoping: 'local' or 'global') -> bool, StatNode_or_error
		--[[
		A class definition defines both a table (the class table, Foo)
		and a class type.
		It is implied that the class table 'Foo' is the __index for an instance type, which is also defined.

		The typename 'Foo' will refer to the *instance type*.
		There is no way to refer to the class type.

		class Foo = expr

		-- Extends the class 'Foo':
		function Foo.static_fun()
			Foo.static_var = 42
		end

		function Foo:init()
			-- The next line extends the instance type
			self.member_var = 32 
		end

		function Foo:member_fun()
			return self.member_var
		end
		--]]

		local where = where_am_i()

		if not tok:is('ident') then
			return false, report_error("Name expected")
		end
		local name = tok:get(token_list).data

		if not tok:consume_symbol('=', token_list) then
			return false, report_error("Expected '='")
		end

		local st, rhs = parse_expr(scope)
		
		if not st then return false, rhs end

		local node = { 
			ast_type  = 'ClassDeclStatement',
			scope     = scope,
			name      = name,
			rhs       = rhs,
			tokens    = token_list,
			where     = where,
			is_local  = (scoping == 'local')
		}

		return true, node
	end


	local function parse_statement(scope) -> bool, StatNode_or_error
		var            st         = true -- Success?
		var   stat       = nil : object?
		var token_list = {} : TokenList
		var            where      = where_am_i()

		if tok:consume_keyword('if', token_list) then
			--setup
			local node_if_stat = {
				ast_type = 'IfStatement'
			}
			typedef Clause = {
				condition: P.ExprNode?;
				body:      P.Statlist;
			}
			var clauses = {} : [Clause]

			--clauses
			repeat
				local st, node_cond = parse_expr(scope)
				if not st then return false, node_cond end
				if not tok:consume_keyword('then', token_list) then
					return false, report_error("`then` expected.")
				end
				local st, node_body = parse_statement_list(create_scope(scope))
				if not st then return false, node_body end
				clauses #= {
					condition = node_cond;
					body      = node_body;
				}
			until not tok:consume_keyword('elseif', token_list)

			--else clause
			if tok:consume_keyword('else', token_list) then
				if tok:peek().data == 'if' and tok:peek().leading_white == ' ' then
					-- Warn agains C-style 'else if'
					report_error("Dangerous 'else if' here - did you mean 'elseif' ? (insert extra space to mute this error)")
				end

				local st, node_body = parse_statement_list(create_scope(scope))
				if not st then return false, node_body end
				clauses #= {
					body = node_body;
				}
			end

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

			node_if_stat.clauses = clauses
			node_if_stat.tokens = token_list
			stat = node_if_stat

		elseif tok:consume_keyword('while', token_list) then
			--setup
			local node_while_stat = {}
			node_while_stat.ast_type = 'WhileStatement'

			--condition
			local st, node_cond = parse_expr(scope)
			if not st then return false, node_cond end

			--do
			if not tok:consume_keyword('do', token_list) then
				return false, report_error("`do` expected.")
			end

			--body
			local st, node_body = parse_statement_list(create_scope(scope))
			if not st then return false, node_body end

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

			--return
			node_while_stat.condition = node_cond
			node_while_stat.body      = node_body
			node_while_stat.tokens    = token_list
			stat = node_while_stat

		elseif tok:consume_keyword('do', token_list) then
			--do block
			local st, node_block = parse_statement_list(create_scope(scope))
			if not st then return false, node_block end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

			local node_do_stat = {}
			node_do_stat.ast_type = 'DoStatement'
			node_do_stat.body    = node_block
			node_do_stat.tokens  = token_list
			stat = node_do_stat

		elseif tok:consume_keyword('for', token_list) then
			--for block
			if not tok:is('ident') then
				return false, report_error("<ident> expected.")
			end
			local base_var_name = tok:get(token_list)
			if tok:consume_symbol('=', token_list) then
				--numeric for
				local for_scope = create_scope(scope)

				local st, start_ex = parse_expr(scope)
				if not st then return false, start_ex end
				if not tok:consume_symbol(',', token_list) then
					return false, report_error("`,` Expected")
				end

				local st, end_ex = parse_expr(scope)
				if not st then return false, end_ex end

				var step_ex = nil : P.ExprNode or string or nil
				if tok:consume_symbol(',', token_list) then
					st, step_ex = parse_expr(scope)
					if not st then return false, step_ex end
				end
				if not tok:consume_keyword('do', token_list) then
					return false, report_error("`do` expected")
				end

				local st, body = parse_statement_list(for_scope)
				if not st then return false, body end
				if not tok:consume_keyword('end', token_list) then
					return false, report_error("`end` expected")
				end

				stat = {
					ast_type = 'NumericForStatement';
					scope    = for_scope;
					var_name = base_var_name.data;
					start    = start_ex;
					end_     = end_ex;
					step     = step_ex;
					body     = body;
					tokens   = token_list;
				}

			else
				--generic for
				local for_scope = create_scope(scope)
				--
				var var_names = { base_var_name.data }
				while tok:consume_symbol(',', token_list) do
					if not tok:is('ident') then
						return false, report_error("for variable expected.")
					end
					var_names #= tok:get(token_list).data
				end
				if not tok:consume_keyword('in', token_list) then
					return false, report_error("`in` expected.")
				end
				var generators = {} : [P.ExprNode]
				local st, first_generator = parse_expr(scope)
				if not st then return false, first_generator end
				generators #= first_generator
				while tok:consume_symbol(',', token_list) do
					local st, gen = parse_expr(scope)
					if not st then return false, gen end
					generators #= gen
				end
				if not tok:consume_keyword('do', token_list) then
					return false, report_error("`do` expected.")
				end
				local st, body = parse_statement_list(for_scope)
				if not st then return false, body end
				if not tok:consume_keyword('end', token_list) then
					return false, report_error("`end` expected.")
				end
				--
				stat = {
					ast_type   = 'GenericForStatement';
					scope      = for_scope;
					var_names  = var_names;
					generators = generators;
					body       = body;
					tokens     = token_list;
				}
			end

		elseif tok:consume_keyword('repeat', token_list) then
			local st, body = parse_statement_list(create_scope(scope))
			if not st then return false, body end
			--
			if not tok:consume_keyword('until', token_list) then
				return false, report_error("`until` expected.")
			end
			-- FIX: Used to parse in parent scope
			-- Now parses in repeat scope
			local st, cond = parse_expr(body.scope)
			if not st then return false, cond end
			--
			local node_repeat = {}
			node_repeat.ast_type  = 'RepeatStatement'
			node_repeat.condition = cond
			node_repeat.body      = body
			node_repeat.tokens    = token_list
			node_repeat.scope     = body.scope
			stat = node_repeat

		elseif tok:consume_keyword('function', token_list) then
			if not tok:is('ident') then
				return false, report_error("Function name expected")
			end
			local st, name_expr = parse_suffixed_expr(scope, 'only_dot_colon')
			if not st then return false, name_expr end
			--
			var is_aggregate = (name_expr.ast_type == 'MemberExpr')
			var is_mem_fun = (name_expr.ast_type == 'MemberExpr' and name_expr.indexer == ':')
			local st, func = parse_function_args_and_body(scope, token_list, is_mem_fun and 'mem_fun' or nil)
			if not st then return false, func end

			-- 'function foo()' is local in sol, global in lua

			func.ast_type     = 'FunctionDeclStatement'
			if not is_aggregate then
				func.is_local  = settings.sol
			end
			func.scoping      = ''
			func.is_aggregate = is_aggregate
			func.name_expr    = name_expr
			stat = func

		elseif tok:consume_keyword('local', token_list) then
			if tok:consume_keyword('function', token_list) then
				st, stat = parse_function_decl(scope, token_list, 'local')
			else
				st, stat = parse_declaration(scope, token_list, 'local')
			end

		elseif settings.is_sol and tok:consume_keyword('global', token_list) then
			if tok:consume_keyword('typedef') then
				st, stat = parse_typedef(scope, 'global')
			elseif tok:consume_keyword('class', token_list) then
				st, stat = parse_class(scope, token_list, 'global')
			elseif tok:consume_keyword('function', token_list) then
				st, stat = parse_function_decl(scope, token_list, 'global')
			else
				st, stat = parse_declaration(scope, token_list, 'global')
			end

		elseif tok:consume_keyword('var', token_list) then
			st, stat = parse_declaration(scope, token_list, 'var')

		elseif tok:consume_keyword('class', token_list) then
			st, stat = parse_class(scope, token_list, 'local')

		elseif tok:consume_symbol('::', token_list) then
			if not tok:is('ident') then
				return false, report_error('label name expected')
			end
			local label = tok:get(token_list).data
			if not tok:consume_symbol('::', token_list) then
				return false, report_error("`::` expected")
			end
			local node_label = {}
			node_label.ast_type = 'LabelStatement'
			node_label.label   = label
			node_label.tokens  = token_list
			stat = node_label

		elseif tok:consume_keyword('return', token_list) then
			var ex_list = {} : [P.ExprNode]
			if not tok:is_keyword('end') and not tok:is_keyword('else') and not tok:is_keyword('elseif') then
				local st, first_ex = parse_expr(scope)
				if st then
					ex_list[1] = first_ex
					while tok:consume_symbol(',', token_list) do
						local st, ex = parse_expr(scope)
						if not st then return false, ex end
						ex_list #= ex
					end
				end
			end

			stat = {
				ast_type  = 'ReturnStatement';
				arguments = ex_list;
				tokens    = token_list;
			}

		elseif tok:consume_keyword('break', token_list) then
			local node_break = {}
			node_break.ast_type = 'BreakStatement'
			node_break.tokens  = token_list
			stat = node_break

		elseif tok:consume_keyword('goto', token_list) then
			if not tok:is('ident') then
				return false, report_error("label expected")
			end
			local label = tok:get(token_list).data
			stat = {
				ast_type = 'GotoStatement';
				label    = label;
				tokens   = token_list;
			}

		elseif settings.is_sol and tok:consume_keyword('typedef') then
			st,stat = parse_typedef(scope, 'local')

		else
			--statement_parse_expr
			var st, suffixed = parse_suffixed_expr(scope)
			if not st then return false, suffixed end

			--assignment or call?
			if tok:is_symbol(',') or tok:is_symbol('=') then
				--check that it was not parenthesized, making it not an lvalue
				if (suffixed.paren_count or 0) > 0 then
					return false, report_error("Can not assign to parenthesized expression, is not an lvalue")
				end

				--more processing needed
				var lhs = { suffixed }
				while tok:consume_symbol(',', token_list) do
					local st, lhs_part = parse_suffixed_expr(scope)
					if not st then return false, lhs_part end
					lhs #= lhs_part
				end

				--equals
				if not tok:consume_symbol('=', token_list) then
					return false, report_error("`=` Expected.")
				end

				--rhs
				var rhs = {} : [P.ExprNode]
				local st, first_rhs = parse_expr(scope)
				if not st then return false, first_rhs end
				rhs[1] = first_rhs
				while tok:consume_symbol(',', token_list) do
					local st, rhs_part = parse_expr(scope)
					if not st then return false, rhs_part end
					rhs #= rhs_part
				end

				--done
				stat = {
					ast_type = 'AssignmentStatement';
					lhs      = lhs;
					rhs      = rhs;
					tokens   = token_list;
				}

			elseif assign_op[tok:peek().data] then
				-- += etc
				var op = assign_op[ tok:get(token_list).data ]
				assert(op)

				local st, rhs = parse_expr(scope)
				if not st then return false, rhs end

				var target = suffixed

				var binop_expr = {
					ast_type = 'BinopExpr';
					tokens   = token_list;
					where    = where;
					lhs      = suffixed;
					op       = op;
					rhs      = {
						ast_type = 'ParenthesesExpr';
						tokens   = {};
						where    = where;
						inner    = rhs;
					};
				}

				stat = {
					ast_type = 'AssignmentStatement';
					lhs      = { suffixed   };
					rhs      = { binop_expr };
					tokens   = token_list;
					where    = where;
				}

			elseif tok:consume_symbol('#=', token_list) then
				--[[
				Table append operator:
				IN:    foo #= bar
				OUT:   foo[#foo + 1] = bar
				SLOW:  table.insert(foo, bar)

				TODO:  foo #= a, b, c
				OUT:   foo[#foo + 1] = a; foo[#foo + 1] = b; foo[#foo + 1] = c;
				--]]

				local array = suffixed

				local st, rhs = parse_expr(scope)
				if not st then return false, rhs end

				stat =
				{
					ast_type = 'AssignmentStatement';
					where    = where;
					tokens   = token_list;
					lhs      =
					{
						--foo[#foo + 1]
						{
							ast_type = 'IndexExpr';
							where    = where;
							tokens   = {};
							base     = array;
							index    =
							{
								-- #foo + 1
								ast_type = 'BinopExpr';
								where    = where;
								tokens   = {};
								op       = '+';
								lhs      =
								{
									-- #foo
									ast_type = 'UnopExpr';
									where    = where;
									tokens   = {};
									op       = '#';
									rhs      = array;
								};
								rhs =
								{
									-- 1
									ast_type = 'NumberExpr';
									where    = where;
									tokens   = {};
									value    = "1";
								};
							}
						}
					};
					rhs      = { rhs };
				}

			elseif suffixed.ast_type == 'CallExpr' or
				   suffixed.ast_type == 'TableCallExpr' or
				   suffixed.ast_type == 'StringCallExpr'
			then
				--it's a call statement
				stat = {
					ast_type   = 'CallStatement';
					expression = suffixed;
					tokens     = token_list;
				}
				
			else
				return false, report_error("Assignment statement expected, got (" .. tok:peek().data .. ")")
			end
		end
		
		if not st then return st, stat end

		assert(stat)

		stat.where = where

		if tok:is_symbol(';') then
			report_warning("semicolon at the end of a statement is considered bad style")
			stat.semicolon = tok:get( stat.tokens )
		end

		return true, stat
	end


	parse_statement_list = function(scope) -> bool, P.Statlist or string
		assert(scope)
		var node = {
			ast_type = 'Statlist';
			where    = where_am_i();
			scope    = scope;
			tokens   = { };
		}

		var stats = {} : [P.StatNode]

		while not stat_list_close_keywords[tok:peek().data] and not tok:is_eof() do
			local st, node_statement = parse_statement(node.scope)
			if not st then return false, node_statement end
			stats #= node_statement
		end

		if tok:is_eof() then
			local node_eof = {
				ast_type = 'Eof';
				tokens   = { tok:get() };
				where    = where_am_i();
			}
			stats #= node_eof
		end

		node.body = stats

		return true, node
	end


	local function mainfunc()
		return parse_statement_list(module_scope)
	end

	local st, main = mainfunc()
	--print("Last Token: "..PrintTable(tok:peek()))
	if num_err == 0 then
		return st, main
	else
		return false, main
	end
end

return P
