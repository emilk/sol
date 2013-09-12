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
	symbols = set{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#'};

	keywords = set{
		'and',    'break', 'do',   'else',     'elseif',
		'end',    'false', 'for',  'function', 'goto', 'if',
		'in',     'local', 'nil',  'not',      'or',   'repeat',
		'return', 'then',  'true', 'until',    'while',
	};


	-- Sol extensions all off:
	is_sol         = false;
	function_types = false;
}

P.SOL_SETTINGS = {
	-- Lexer:
	symbols = set{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#', '?', ':'};

	keywords = set{
		'and',    'break', 'do',   'else',     'elseif',
		'end',    'false', 'for',  'function', 'goto', 'if',
		'in',     'local', 'nil',  'not',      'or',   'repeat',
		'return', 'then',  'true', 'until',    'while',

		-- Sol specific:
		'typedef', 'global', 'var', 'class',
	};


	-- Parser:
	is_sol         = true;
	function_types = true;  -- Support  foo(arg : int) -> int
}


local stat_list_close_keywords = set{'end', 'else', 'elseif', 'until'}


--------------------------------------------------------

typedef P.ExprType = 'IdExpr' or 'NumberExpr' or 'StringExpr' or 'BooleanExpr' or 'NilExpr'
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
	ast_type: P.NodeType,
	tokens:   [L.Token],
	where:    string
}

typedef P.Statlist : P.Node = {
	ast_type: 'Statlist',
}

typedef P.ExprNode : P.Node = {
	ast_type: P.ExprType
}

typedef P.StatNode : P.Node = {
	ast_type: P.StatType
}

typedef ExprNode_or_error = P.ExprNode or string or nil
typedef StatNode_or_error = P.StatNode or string or nil

typedef Scope     = S.Scope
typedef TokenList = L.TokenList


--------------------------------------------------------

function P.parse_sol(src: string, tok, filename: string?, settings, module_scope)
	filename = filename or ''
	settings = settings or P.SOL_SETTINGS
	local num_err = 0

	--
	local function where_am_i(offset: int?) -> string
		return filename .. ":" .. tok:peek(offset).line
	end

	local function generate_msg(msg_fmt, ...) -> string
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

	local function report_error(msg_fmt, ...)
		num_err = num_err + 1
		local msg = generate_msg(msg_fmt, ...)
		printf_err("%s", msg)
		return msg
	end

	local function report_warning(msg_fmt, ...)
		local msg = generate_msg(msg_fmt, ...)
		print( msg )
		return msg
	end

	local function report_spam(msg_fmt, ...)
		if _G.g_spam then
			local msg = generate_msg(msg_fmt, ...)
			print( msg )
		end
	end

	local function report_sol_error(msg_fmt, ...)
		if settings.is_sol then
			report_error(msg_fmt, ...)
		else
			report_warning(msg_fmt, ...)
		end
	end

	local VarUid = 0

	local VarDigits = {'_', 'a', 'b', 'c', 'd'}
	local function create_scope(parent)
		local scope = S.Scope.new(parent)
		--report_spam("New scope %s, parent: %s", tostring(scope), tostring(parent))
		return scope
	end


	local parse_expr
	local parse_statement_list
	local parse_simple_expr, 
	      parse_sub_expr,
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
		var<[ArgInfo]>  arg_list = {}
		var<T.VarArgs?> vararg  = nil

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

				arg_list[#arg_list+1] = arg

				if not tok:consume_symbol(',', token_list) then
					if tok:consume_symbol(')', token_list) then
						break
					else
						return false, report_error("`)` expected.")
					end
				end
			elseif tok:consume_symbol('...', token_list) then
				var<T.Type?> elem_type = T.Any

				if settings.function_types and tok:consume_symbol(':') then
					elem_type = parse_type(func_scope)
					if not elem_type then
						return false, report_error("type expected.")
					end
				end

				var<T.VarArgs> var_arg_type = {
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

		local return_types = nil

		if settings.function_types and tok:consume_symbol('->') then
			return_types = parse_type_list(func_scope)
		end

		--body
		local st, body = parse_statement_list(func_scope)
		if not st then return false, body end

		--end
		if not tok:consume_keyword('end', token_list) then
			return false, report_error("`end` expected after function body at %s", where)
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
		local id = tok:get(token_list)

		return {
			ast_type = 'IdExpr';
			name     = id.data;
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

			if tok:is_symbol('.') or tok:is_symbol(':') then
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
				var<[P.ExprNode]> args = {}
				while not tok:consume_symbol(')', token_list) do
					local st, ex = parse_expr(scope)
					if not st then return false, ex end
					args[#args+1] = ex
					if not tok:consume_symbol(',', token_list) then
						if tok:consume_symbol(')', token_list) then
							break
						else
							return false, report_error("`)` Expected.")
						end
					end
				end
				local node_call = {}
				node_call.ast_type   = 'CallExpr'
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
				node_call.ast_type    = 'StringCallExpr'
				node_call.base       = prim
				--node_call.arguments  = { tok:get(token_list) }
				node_call.arguments  = { ex }
				node_call.tokens     = token_list
				node_call.where      = where
				--
				prim = node_call

			elseif not only_dot_colon and tok:is_symbol('{') then
				--table call
				local st, ex = parse_simple_expr(scope)
				-- FIX: parse_expr(scope) parses the table AND and any following binary expressions.
				-- We just want the table
				if not st then return false, ex end
				local node_call = {}
				node_call.ast_type   = 'TableCallExpr'
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
		var<TokenList> token_list = {}
		var<object?>   node       = nil
		var            where      = where_am_i()

		if tok:is('Number') then
			node = {
				ast_type = 'NumberExpr';
				value    = tok:get(token_list);
				tokens   = token_list;
			}

		elseif tok:is('String') then
			node = {
				ast_type = 'StringExpr';
				value    = tok:get(token_list);
				tokens   = token_list;
			}

		elseif tok:consume_keyword('nil', token_list) then
			node = {
				ast_type = 'NilExpr';
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
			node = {
				ast_type = 'ConstructorExpr';
				entry_list = {};
			}
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
					node.entry_list[#node.entry_list+1] = {
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
						node.entry_list[#node.entry_list+1] = {
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
						node.entry_list[#node.entry_list+1] = {
							type = 'value';
							value = value;
						}

					end
				elseif tok:consume_symbol('}', token_list) then
					break

				else
					--value
					local st, value = parse_expr(scope)
					node.entry_list[#node.entry_list+1] = {
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
					return false, report_error("`}` or table entry Expected")
				end
			end
			node.tokens = token_list

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

	parse_sub_expr = function(scope: Scope, prio_level: int) -> bool, ExprNode_or_error
		var<bool>    st  = false
		var<object?> exp = nil

		--base item, possibly with unop prefix
		if unops[tok:peek().data] then
			local token_list = {}
			local op = tok:get(token_list).data
			st, exp = parse_sub_expr(scope, unopprio)
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
				local st, rhs = parse_sub_expr(scope, prio[2])
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

		exp.where = where_am_i()

		return true, exp
	end


	parse_simple_type = function(scope) -> T.Type?
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

		-- TODO:  if tok:consume_symbol('\\(')   -- Function
		if tok:consume_symbol('{') then
			-- Object or map?
			if tok:consume_symbol('}') then
				report_error("Use 'object'")
				return T.create_empty_table()
			elseif tok:is('ident') and tok:peek(1).data == ':' then
				-- key-value-pairs - an object
				var<T.Object> obj = {
					tag     = 'object',
					members = {}
				}
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

			var<T.Function> fun_t = {
				tag    = 'function',
				args   = {},
				vararg = nil,
				rets   = nil,
				name   = nil,
			}

			if not tok:consume_symbol(')') then
				while true do
					if tok:consume_symbol('...') then
						var<T.Type> var_arg_t = T.Any

						if tok:consume_symbol(':') then
							var_arg_t = parse_type(scope)
						end

						fun_t.vararg = { tag = 'varargs', type = var_arg_t }

						if not tok:consume_symbol(')') then
							report_error('vararg (...) must be last argument to function')
						end

						break
					end

					var<string?> arg_name = nil
					if tok:is('ident') and tok:peek(1).data == ':' then
						-- named type
						arg_name = tok:get_ident()
						tok:get() -- Swallow ':'
					end

					local type = parse_type(scope)

					table.insert(fun_t.args, { name = arg_name, type = type })

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

		-- HACK: Handle keywords explicitly:
		elseif tok:consume_keyword('nil') then
			return T.Nil

		elseif tok:consume_keyword('true') then
			return T.True

		elseif tok:consume_keyword('false') then
			return T.False

		elseif tok:is('ident') then
			local where = where_am_i()
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

		local list = nil
		while true do
			local type = parse_type(scope)
			if not type then
				return list
			end

			list = list or {}
			table.insert(list, type)
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


	local function parse_typedef(scope: S.Scope, type: 'local' or 'global') -> bool, StatNode_or_error
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
		  var<Mod.Foo> foo = 42
		--]]

		local where = where_am_i()

		if not tok:is('ident') then
			return false, report_error("Name expected")
		end
		local type_name = tok:get().data


		local function parse_bases()
			-- Check for inheritance
			local base_types = {}
			if tok:consume_symbol(':') then
				repeat
					local t = parse_type(scope)
					if not t then
						report_error("base type expected")
						return nil
					end
					table.insert(base_types, t)
				until not tok:consume_symbol(',')
			end

			return base_types
		end


		local function parse_type_assignment()
			if not tok:consume_symbol('=') then
				report_error("Expected '='")
				return nil
			end

			local type = parse_type(scope)

			if not type then
				report_error("Expected type") 
				return nil
			end

			return type
		end

		local node = { 
			ast_type  = 'Typedef',
			scope     = scope,
			type_name = type_name,
			tokens    = {},
			where     = where,
			global_   = (type == 'global')
		}

		if not tok:consume_symbol('.') then
			node.type_name  = type_name
		else
			if type == 'global' then
				return false, report_error("global typedef cannot have namespaced name")
			end

			local base_name = type_name
			--[[
			local var_ = scope:get_var(base_name)
			if not var_ then
				return false, report_error("namespaced typedef: %s is not a previously defined variable", base_name)
			end
			--]]

			type_name = tok:get_ident()
			if not type_name then
				return false, report_error("Identifier expected")
			end

			--nod([^S].)variable  = var_
			node.namespace_name = base_name
			node.type_name      = type_name
		end

		-- Are we a forward-declare?
		if not tok:consume_symbol(';') then
			node.base_types = parse_bases()
			if not node.base_types then return false, report_error("base type(s) expected") end

			node.type  = parse_type_assignment()
			if not node.type then return false, report_error("type assignment expected") end
		end

		return true, node
	end


	parse_expr = function(scope: Scope) -> bool, ExprNode_or_error
		var st,expr = parse_sub_expr(scope, 0)
		if not st then return false, expr end

		if tok:consume_symbol(':') then
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
				expr     = expr,
				type     = type,
			}
		else
			return true, expr
		end
	end


	local function parse_function_decl(scope: S.Scope, token_list: L.TokenList,
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


	local function parse_declaration(scope: S.Scope, token_list: L.TokenList,
		                              scoping: 'local' or 'global' or 'var') -> bool, StatNode_or_error

		var is_local = (scoping ~= 'global')
		var angle_bracket = (tok:peek().data == '<')

		var where = where_am_i()
		local types = nil

		if scoping == 'var' then
			types = parse_type_args(scope)
		elseif parse_type_args(scope) then
			return false, report_error("%s cannot have type list - did you want 'var' ?")
		end

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
			name_list[#name_list+1] = tok:get(token_list).data
		end

		var<[P.ExprNode]> init_list = {}
		if tok:consume_symbol('=', token_list) then
			repeat
				local st, ex = parse_expr(scope)
				if not st then return false, ex end
				init_list[#init_list+1] = ex
			until not tok:consume_symbol(',', token_list)
		end

		local node_local = {
			ast_type  = 'VarDeclareStatement';
			type_list = types;
			name_list = name_list;
			init_list = init_list;
			tokens    = token_list;
			is_local  = is_local;
			scoping   = scoping; -- 'local' or 'global' or 'var'
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

		assert(#token_list == 3)

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
		var<object?>   stat       = nil
		var<TokenList> token_list = {}
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
			var<[Clause]> clauses = {}

			--clauses
			repeat
				local st, node_cond = parse_expr(scope)
				if not st then return false, node_cond end
				if not tok:consume_keyword('then', token_list) then
					return false, report_error("`then` expected.")
				end
				local st, node_body = parse_statement_list(create_scope(scope))
				if not st then return false, node_body end
				clauses[#clauses+1] = {
					condition = node_cond;
					body = node_body;
				}
			until not tok:consume_keyword('elseif', token_list)

			--else clause
			if tok:consume_keyword('else', token_list) then
				if tok:peek().data == 'if' and tok:peek().all_leading_white == ' ' then
					-- Warn agains C-style 'else if'
					report_error("Dangerous 'else if' here - did you mean 'elseif' ? (insert extra space to mute this error)")
				end

				local st, node_body = parse_statement_list(create_scope(scope))
				if not st then return false, node_body end
				clauses[#clauses+1] = {
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

				var<P.ExprNode?> step_ex = nil
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
					var_names[#var_names+1] = tok:get(token_list).data
				end
				if not tok:consume_keyword('in', token_list) then
					return false, report_error("`in` expected.")
				end
				var<[P.ExprNode]> generators = {}
				local st, first_generator = parse_expr(scope)
				if not st then return false, first_generator end
				generators[#generators+1] = first_generator
				while tok:consume_symbol(',', token_list) do
					local st, gen = parse_expr(scope)
					if not st then return false, gen end
					generators[#generators+1] = gen
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
			elseif tok:consume_keyword('class') then
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
			var<[P.ExprNode]> ex_list = {}
			if not tok:is_keyword('end') and not tok:is_keyword('else') and not tok:is_keyword('elseif') then
				local st, first_ex = parse_expr(scope)
				if st then
					ex_list[1] = first_ex
					while tok:consume_symbol(',', token_list) do
						local st, ex = parse_expr(scope)
						if not st then return false, ex end
						ex_list[#ex_list+1] = ex
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
					lhs[#lhs+1] = lhs_part
				end

				--equals
				if not tok:consume_symbol('=', token_list) then
					return false, report_error("`=` Expected.")
				end

				--rhs
				var<[P.ExprNode]> rhs = {}
				local st, first_rhs = parse_expr(scope)
				if not st then return false, first_rhs end
				rhs[1] = first_rhs
				while tok:consume_symbol(',', token_list) do
					local st, rhs_part = parse_expr(scope)
					if not st then return false, rhs_part end
					rhs[#rhs+1] = rhs_part
				end

				--done
				stat = {
					ast_type = 'AssignmentStatement';
					lhs     = lhs;
					rhs     = rhs;
					tokens  = token_list;
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
				return false, report_error("Assignment Statement Expected")
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

		var<[P.StatNode]> stats = {}

		while not stat_list_close_keywords[tok:peek().data] and not tok:is_eof() do
			local st, node_statement = parse_statement(node.scope)
			if not st then return false, node_statement end
			stats[#stats + 1] = node_statement
		end

		if tok:is_eof() then
			local node_eof = {
				ast_type = 'Eof';
				tokens   = { tok:get() };
				where    = where_am_i();
			}
			stats[#stats + 1] = node_eof
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
