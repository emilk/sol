--
-- ParseSol.lua
-- ParseSol taken in a token stream (from the lexer)
-- and outputs an AST.
-- It keeps track of scoping and variables.


local L         = require 'lexer'
local D         = require 'sol_debug'
local S         = require 'scope'
local T         = require 'type'  -- For intrinsic functions
local U      = require 'util'

local printf_err = U.printf_err
local bimap  = U.bimap


local P = {}

P.LuaSettings = {
	-- Lexer:
	Symbols = bimap{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#'};

	Keywords = bimap{
		'and', 'break', 'do', 'else', 'elseif',
		'end', 'false', 'for', 'function', 'goto', 'if',
		'in', 'local', 'nil', 'not', 'or', 'repeat',
		'return', 'then', 'true', 'until', 'while',
	};


	-- Sol extensions all off:
	Sol           = false;
	FunctionTypes = false;
}

P.SolSettings = {
	-- Lexer:
	Symbols = bimap{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#', '?', ':'};

	Keywords = bimap{
		'and', 'break', 'do', 'else', 'elseif',
		'end', 'false', 'for', 'function', 'goto', 'if',
		'in', 'local', 'nil', 'not', 'or', 'repeat',
		'return', 'then', 'true', 'until', 'while',

		-- Sol specific:
		'typedef', 'global', 'var',
	};


	-- Parser:
	Sol           = true;
	FunctionTypes = true;  -- Support  foo(arg : int) -> int
}


--------------------------------------------------------

typedef P.ExprType = 'IdExpr' or 'VarExpr' or 'NumberExpr' or 'StringExpr' or 'BooleanExpr' or 'NilExpr'
                  or 'BinopExpr' or 'UnopExpr' or 'DotsExpr'
                  or 'CallExpr' or 'TableCallExpr' or 'StringCallExpr'
                  or 'IndexExpr' or 'MemberExpr' or 'LambdaFunction'
                  or 'ConstructorExpr' or 'Parentheses'

typedef P.StatType = 'AssignmentStatement' or 'CallStatement' or 'VarDeclareStatement'
                  or 'IfStatement' or 'WhileStatement' or 'DoStatement' or 'RepeatStatement'
                  or 'GenericForStatement' or 'NumericForStatement'
                  or 'ReturnStatement' or 'BreakStatement' or 'LabelStatement' or 'GotoStatement'
                  or 'FunctionDecl'
                  or 'Typedef'
                  or 'Eof'

typedef P.NodeType = P.ExprType or P.StatType or 'Statlist'

-- General AstNode:
typedef P.Node = {
	AstType: P.NodeType,
	Tokens : [L.Token],
}

typedef P.Statlist : P.Node = {
	AstType: 'Statlist',
}

typedef P.ExprNode : P.Node = {
	AstType: P.ExprType
}

typedef P.StatNode : P.Node = {
	AstType: P.StatType
}


--------------------------------------------------------

function P.ParseSol(src: string, tok, filename: string?, settings, module_scope)
	filename = filename or ''
	settings = settings or P.SolSettings
	local num_err = 0

	--
	local function where_am_i(offset: int?) -> string
		return filename .. ":" .. tok:Peek(offset).Line
	end

	local function generate_msg(msg_fmt, ...) -> string
		local msg = string.format(msg_fmt, ...)
		--local err = ">> :"..tok:Peek().Line..":"..tok:Peek().Char..": "..msg.."\n"
		local err = "solc: "..where_am_i(-1)..": "..msg.."\n"
		--find the line
		local line_num = 0
		for line in src:gmatch("[^\n]*\n?") do
			if line:sub(-1,-1) == '\n' then line = line:sub(1,-2) end
			line_num = line_num+1
			if line_num == tok:Peek().Line then
				err = err..">> `"..line:gsub('\t','    ').."`\n"
				for i = 1, tok:Peek().Char do
					local c = line:sub(i,i)
					if c == '\t' then
						err = err..'    '
					else
						err = err..' '
					end
				end
				if not tok:Peek().Data then
					err = err.."   ^^^^"
				else
					err = err.."   ^"
					for i = 2, #tok:Peek().Data do
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
		if settings.Sol then
			report_error(msg_fmt, ...)
		else
			report_warning(msg_fmt, ...)
		end
	end

	local VarUid = 0

	local VarDigits = {'_', 'a', 'b', 'c', 'd'}
	local function CreateScope(parent)
		local scope = S.Scope:new(parent)
		scope.Print = function() return "<Scope>" end
		--report_spam("New scope %s, parent: %s", tostring(scope), tostring(parent))
		return scope
	end


	local ParseExpr
	local ParseStatementList
	local ParseSimpleExpr, 
	      ParseSubExpr,
	      ParsePrimaryExpr,
	      ParseSuffixedExpr,
	      ParseSimpleType,
	      ParseType,
	      ParseTypeList,
	      ParseTypeArgs


	-- is_mem_fun: we where declared like  foo:fun(args)  and thus have an implicit 'self'
	local function ParseFunctionArgsAndBody(scope, token_list, is_mem_fun)
		local start = where_am_i()

		local func_scope = CreateScope(scope)
		if not tok:ConsumeSymbol('(', token_list) then
			return false, report_error("`(` expected.")
		end

		typedef ArgInfo = {
			name: string;
			type: T.Type?;
		}
		var<[ArgInfo]>  arg_list = {}
		var<T.VarArgs?> vararg  = nil

		while not tok:ConsumeSymbol(')', token_list) do
			if tok:Is('Ident') then
				local arg = {
					name = tok:Get(token_list).Data
				}

				if settings.FunctionTypes and tok:ConsumeSymbol(':') then
					arg.type = ParseType(func_scope)
					if not arg.type then
						return false, report_error("type expected.")
					end
				end

				arg_list[#arg_list+1] = arg

				if not tok:ConsumeSymbol(',', token_list) then
					if tok:ConsumeSymbol(')', token_list) then
						break
					else
						return false, report_error("`)` expected.")
					end
				end
			elseif tok:ConsumeSymbol('...', token_list) then
				var<T.Type?> elem_type = T.Any

				if settings.FunctionTypes and tok:ConsumeSymbol(':') then
					elem_type = ParseType(func_scope)
					if not elem_type then
						return false, report_error("type expected.")
					end
				end

				var<T.VarArgs> var_arg_type = {
					tag  = 'varargs',
					type = elem_type,
				}
				vararg = var_arg_type

				if not tok:ConsumeSymbol(')', token_list) then
					return false, report_error("`...` must be the last argument of a function.")
				end
				break
			else
				return false, report_error("Argument name or `...` expected")
			end
		end

		local return_types = nil

		if settings.FunctionTypes and tok:ConsumeSymbol('->') then
			return_types = ParseTypeList(func_scope)
		end

		--body
		local st, body = ParseStatementList(func_scope)
		if not st then return false, body end

		--end
		if not tok:ConsumeKeyword('end', token_list) then
			return false, report_error("`end` expected after function body at %s", start)
		end

		local node_func = {
			--AstType     = 'Function', LambdaFunction or FunctionDecl
			scope       = func_scope,
			Tokens      = token_list,
			IsMemFun    = is_mem_fun,
			Arguments   = arg_list,
			vararg      = vararg,
			ReturnTypes = return_types,
			Body        = body,
		}

		return true, node_func
	end


	ParsePrimaryExpr = function(scope)
		local token_list = {}

		if tok:ConsumeSymbol('(', token_list) then
			local st, ex = ParseExpr(scope)
			if not st then return false, ex end
			if not tok:ConsumeSymbol(')', token_list) then
				return false, report_error("`)` Expected.")
			end

			local parens_exp = {}
			parens_exp.AstType   = 'Parentheses'
			parens_exp.Inner     = ex
			parens_exp.Tokens    = token_list
			return true, parens_exp

		elseif tok:Is('Ident') then
			local id = tok:Get(token_list)

			return true, {
				AstType = 'IdExpr',
				name    = id.Data,
				Tokens  = token_list
			}
		else
			return false, report_error("primary expression expected")
		end
	end

	ParseSuffixedExpr = function(scope, only_dot_colon)
		--base primary expression
		local st, prim = ParsePrimaryExpr(scope)
		if not st then return false, prim end
		--
		while true do
			local token_list = {}
			local where = where_am_i()

			if tok:IsSymbol('.') or tok:IsSymbol(':') then
				local symb = tok:Get(token_list).Data
				if not tok:Is('Ident') then
					return false, report_error("<Ident> expected.")
				end
				local id = tok:Get(token_list)
				local node_index = {}
				node_index.AstType  = 'MemberExpr'
				node_index.Base     = prim
				node_index.Indexer  = symb
				node_index.Ident    = id
				node_index.Tokens   = token_list
				node_index.where    = where
				--
				prim = node_index

			elseif not only_dot_colon and tok:ConsumeSymbol('[', token_list) then
				local st, ex = ParseExpr(scope)
				if not st then return false, ex end
				if not tok:ConsumeSymbol(']', token_list) then
					return false, report_error("`]` expected.")
				end
				local node_index = {}
				node_index.AstType  = 'IndexExpr'
				node_index.Base     = prim
				node_index.Index    = ex
				node_index.Tokens   = token_list
				node_index.where    = where
				--
				prim = node_index

			elseif not only_dot_colon and tok:ConsumeSymbol('(', token_list) then
				var<[P.ExprNode]> args = {}
				while not tok:ConsumeSymbol(')', token_list) do
					local st, ex = ParseExpr(scope)
					if not st then return false, ex end
					args[#args+1] = ex
					if not tok:ConsumeSymbol(',', token_list) then
						if tok:ConsumeSymbol(')', token_list) then
							break
						else
							return false, report_error("`)` Expected.")
						end
					end
				end
				local node_call = {}
				node_call.AstType   = 'CallExpr'
				node_call.Base      = prim
				node_call.Arguments = args
				node_call.Tokens    = token_list
				node_call.where     = where
				--
				prim = node_call

			elseif not only_dot_colon and tok:Is('String') then
				--string call
				local st, ex = ParseSimpleExpr(scope)
				if not st then return false, ex end
				local node_call = {}
				node_call.AstType    = 'StringCallExpr'
				node_call.Base       = prim
				--node_call.Arguments  = { tok:Get(token_list) }
				node_call.Arguments  = { ex }
				node_call.Tokens     = token_list
				node_call.where      = where
				--
				prim = node_call

			elseif not only_dot_colon and tok:IsSymbol('{') then
				--table call
				local st, ex = ParseSimpleExpr(scope)
				-- FIX: ParseExpr(scope) parses the table AND and any following binary expressions.
				-- We just want the table
				if not st then return false, ex end
				local node_call = {}
				node_call.AstType   = 'TableCallExpr'
				node_call.Base      = prim
				node_call.Arguments = { ex }
				node_call.Tokens    = token_list
				node_call.where     = where
				--
				prim = node_call

			else
				break
			end
		end
		return true, prim
	end


	ParseSimpleExpr = function(scope)
		local token_list = {}

		if tok:Is('Number') then
			local node_num = {}
			node_num.AstType = 'NumberExpr'
			node_num.Value   = tok:Get(token_list)
			node_num.Tokens  = token_list
			return true, node_num

		elseif tok:Is('String') then
			local node_str = {}
			node_str.AstType = 'StringExpr'
			node_str.Value   = tok:Get(token_list)
			node_str.Tokens  = token_list
			return true, node_str

		elseif tok:ConsumeKeyword('nil', token_list) then
			local node_nil = {}
			node_nil.AstType = 'NilExpr'
			node_nil.Tokens  = token_list
			return true, node_nil

		elseif tok:IsKeyword('false') or tok:IsKeyword('true') then
			local node_boolean = {}
			node_boolean.AstType = 'BooleanExpr'
			node_boolean.Value   = (tok:Get(token_list).Data == 'true')
			node_boolean.Tokens  = token_list
			return true, node_boolean

		elseif tok:ConsumeSymbol('...', token_list) then
			local node_dots = {}
			node_dots.AstType  = 'DotsExpr'
			node_dots.Tokens   = token_list
			return true, node_dots

		elseif tok:ConsumeSymbol('{', token_list) then
			local v = {}
			v.AstType = 'ConstructorExpr'
			v.EntryList = {}
			--
			while true do
				if tok:IsSymbol('[', token_list) then
					--key
					tok:Get(token_list)
					local st, key = ParseExpr(scope)
					if not st then
						return false, report_error("Key Expression Expected")
					end
					if not tok:ConsumeSymbol(']', token_list) then
						return false, report_error("`]` Expected")
					end
					if not tok:ConsumeSymbol('=', token_list) then
						return false, report_error("`=` Expected")
					end
					local st, value = ParseExpr(scope)
					if not st then
						return false, report_error("Value Expression Expected")
					end
					v.EntryList[#v.EntryList+1] = {
						type  = 'Key';
						Key   = key;
						Value = value;
					}

				elseif tok:Is('Ident') then
					--value or key
					local lookahead = tok:Peek(1)
					if lookahead.type == 'Symbol' and lookahead.Data == '=' then
						--we are a key
						local key = tok:Get(token_list)
						if not tok:ConsumeSymbol('=', token_list) then
							return false, report_error("`=` Expected")
						end
						local st, value = ParseExpr(scope)
						if not st then
							return false, report_error("Value Expression Expected")
						end
						v.EntryList[#v.EntryList+1] = {
							type  = 'KeyString';
							Key   = key.Data;
							Value = value;
						}

					else
						--we are a value
						local st, value = ParseExpr(scope)
						if not st then
							return false, report_error("Value Exected")
						end
						v.EntryList[#v.EntryList+1] = {
							type = 'Value';
							Value = value;
						}

					end
				elseif tok:ConsumeSymbol('}', token_list) then
					break

				else
					--value
					local st, value = ParseExpr(scope)
					v.EntryList[#v.EntryList+1] = {
						type = 'Value';
						Value = value;
					}
					if not st then
						return false, report_error("Value Expected")
					end
				end

				if tok:ConsumeSymbol(';', token_list) or tok:ConsumeSymbol(',', token_list) then
					--all is good
				elseif tok:ConsumeSymbol('}', token_list) then
					break
				else
					return false, report_error("`}` or table entry Expected")
				end
			end
			v.Tokens  = token_list
			return true, v

		elseif tok:ConsumeKeyword('function', token_list) then
			-- Parse lambda
			local st, func = ParseFunctionArgsAndBody(scope, token_list)
			if not st then return false, func end
			--
			func.AstType = 'LambdaFunction'
			func.IsLocal = true
			return true, func

		else
			return ParseSuffixedExpr(scope)
		end
	end


	local unops = bimap{'-', 'not', '#'}
	local unopprio = 8
	local priority = {
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

	ParseSubExpr = function(scope, level) -> bool, P.ExprNode or string
		--base item, possibly with unop prefix
		local st, exp
		if unops[tok:Peek().Data] then
			local token_list = {}
			local op = tok:Get(token_list).Data
			st, exp = ParseSubExpr(scope, unopprio)
			if not st then return false, exp end
			local node_ex = {}
			node_ex.AstType = 'UnopExpr'
			node_ex.Rhs     = exp
			node_ex.Op      = op
			node_ex.OperatorPrecedence = unopprio
			node_ex.Tokens  = token_list
			exp = node_ex
		else
			st, exp = ParseSimpleExpr(scope)
			if not st then return false, exp end
		end

		--next items in chain
		while true do
			local prio = priority[tok:Peek().Data]
			if prio and prio[1] > level then
				local token_list = {}
				local op = tok:Get(token_list).Data
				local st, rhs = ParseSubExpr(scope, prio[2])
				if not st then return false, rhs end
				local node_ex = {}
				node_ex.AstType = 'BinopExpr'
				node_ex.Lhs     = exp
				node_ex.Op      = op
				node_ex.OperatorPrecedence = prio[1]
				node_ex.Rhs     = rhs
				node_ex.Tokens  = token_list
				--
				exp = node_ex
			else
				break
			end
		end

		return true, exp
	end


	ParseSimpleType = function(scope)
		if tok:ConsumeSymbol('[') then
			local type = ParseType(scope)
			if not type then
				report_error("Expected type in list declaration, e.g. [int]")
				tok:ConsumeSymbol(']')
				return T.Any
			end

			if not tok:ConsumeSymbol(']') then
				report_error("Missing ']' after list declaration")
				return T.Any
			end

			return {
				tag  = "list",
				type = type
			}
		end

		-- TODO:  if tok:ConsumeSymbol('\\(')   -- Function
		if tok:ConsumeSymbol('{') then
			-- Object or map?
			if tok:ConsumeSymbol('}') then
				-- Empty object
				return {
					tag = 'object',
					members = {}
				}
			elseif tok:Is('Ident') and tok:Peek(1).Data == ':' then
				-- Key-value-pairs - an object
				local obj = {
					tag = 'object',
					members = {}
				}
				while true do
					if tok:ConsumeSymbol('}') then break end

					if not tok:Is('Ident') then
						report_error('Bad object: identifier expected')
						return T.Any
					end
					
					local id = tok:Get().Data

					if not tok:ConsumeSymbol(':') then
						report_error("Bad object: expected ':'")
						return T.Any
					end

					local type = ParseType(scope)
					if not type then
						report_error("Bad object: expected type")
						return T.Any
					end

					obj.members[id] = type

					if not tok:ConsumeSymbol(',') and not tok:ConsumeSymbol(';') then
						if tok:ConsumeSymbol('}') then
							break
						else
							report_error("Bad object declaration: expected either , or }")
							return T.Any
						end
					end
				end
				return obj
			else
				-- a map?
				local key_type   = ParseType(scope)
				local sep        = tok:ConsumeSymbol('=>')
				local value_type = ParseType(scope)
				local closing    = tok:ConsumeSymbol('}')

				if not (key_type and sep and value_type and closing) then
					report_error("Expected map type on the form: {key_type => value_type}")
					return T.Any
				end

				return {
					tag        = 'map',
					key_type   = key_type,
					value_type = value_type
				}
			end
		end

		if tok:ConsumeKeyword('function') then
			if not tok:ConsumeSymbol('(') then
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

			if not tok:ConsumeSymbol(')') then
				while true do
					if tok:ConsumeSymbol('...') then
						fun_t.vararg = T.Any

						if tok:ConsumeSymbol(':') then
							fun_t.vararg = ParseType(scope)
						end

						if not tok:ConsumeSymbol(')') then
							report_error('vararg (...) must be last argument to function')
						end

						break
					end

					var<string?> arg_name = nil
					if tok:Is('Ident') and tok:Peek(1).Data == ':' then
						-- named type
						arg_name = tok:GetIdent()
						tok:Get() -- Swallow ':'
					end

					local type = ParseType(scope)

					table.insert(fun_t.args, { name = arg_name, type = type })

					if not tok:ConsumeSymbol(',') then
						if not tok:ConsumeSymbol(')') then
							report_error('bad function syntax')
						end
						break
					end
				end
			end

			if tok:ConsumeSymbol('->') then
				fun_t.rets = ParseTypeList(scope)
			else
				fun_t.rets = T.Void
			end

			return fun_t
		end

		if tok:Is('Number') then
			local str = tok:Get().Data
			local t = T.from_num_literal( str )
			if t then return t end
			if not t then
				report_error('Failed to parse number: %q', str)
				return T.Num
			end

		elseif tok:Is('String') then
			return T.from_string_literal( tok:Get().Data )

		-- HACK: Handle keywords explicitly:
		elseif tok:ConsumeKeyword('nil') then
			return T.Nil

		elseif tok:ConsumeKeyword('true') then
			return T.True

		elseif tok:ConsumeKeyword('false') then
			return T.False

		elseif tok:Is('Ident') then
			local where = where_am_i()
			local name = tok:Get().Data

			if tok:ConsumeSymbol('.') then
				-- namespaced type
				if not tok:Is('Ident') then
					report_error("Identifier expected")
					return nil
				end

				local sub_name = tok:Get().Data

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


	ParseType = function(scope) -> T.Type?
		local type = ParseSimpleType(scope)

		if not type then return nil end

		if tok:ConsumeSymbol('?') then
			--type = T.variant(type, T.Nil)   -- FIXME: isa doesn't work with typedef:s before CheckType
			type = {
				tag = 'variant',
				variants = { type, T.Nil }
			}
		end

		if tok:ConsumeKeyword('or') then
			local rhs = ParseType(scope)
			--type = T.variant(type, rhs) -- FIXME: isa doesn't work with typedef:s before CheckType
			type = {
				tag = 'variant',
				variants = { type, rhs }
			}
		end

		return type
	end


	ParseTypeList = function(scope) -> T.Typelist?

		if tok:Peek().Data == 'void' then
			tok:Get()
			return T.Void
		end

		local list = nil
		while true do
			local type = ParseType(scope)
			if not type then
				return list;
			end

			list = list or {}
			table.insert(list, type)
			if not tok:ConsumeSymbol(',') then
				return list
			end
		end
	end


	-- Parses a type-list within (and including) angle brackets: <int,string>
	ParseTypeArgs = function(scope)
		if tok:ConsumeSymbol('<') then
			local list = ParseTypeList(scope) or {}  -- Empty list OK
			if not tok:ConsumeSymbol('>') then
				return nil, report_error("Missing '>'")
			end
			return list
		else
			return nil -- No type-args here
		end
	end


	local function parse_typedef(scope: S.Scope, type: 'local' or 'global') -> bool, string or P.StatNode
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


		if not tok:Is('Ident') then
			return false, report_error("Name expected")
		end
		local type_name = tok:Get().Data


		local function parse_bases()
			-- Check for inheritance
			local base_types = {}
			if tok:ConsumeSymbol(':') then
				repeat
					local t = ParseType(scope)
					if not t then
						report_error("Base type expected")
						return nil
					end
					table.insert(base_types, t)
				until not tok:ConsumeSymbol(',')
			end

			return base_types
		end


		local function parse_type_assignment()
			if not tok:ConsumeSymbol('=') then
				report_error("Expected '='")
				return nil
			end

			local type = ParseType(scope)

			if not type then
				report_error("Expected type") 
				return nil
			end

			return type
		end

		local node = { 
			AstType   = 'Typedef',
			scope     = scope,
			TypeName  = type_name,
			Tokens    = {},
			where     = where,
			Global    = (type == 'global')
		}

		if not tok:ConsumeSymbol('.') then
			node.TypeName  = type_name
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

			type_name = tok:GetIdent()
			if not type_name then
				return false, report_error("Identifier expected")
			end

			--node.Variable  = var_
			node.namespaceName = base_name
			node.TypeName      = type_name
		end

		-- Are we a forward-declare?
		if not tok:ConsumeSymbol(';') then
			node.BaseTypes = parse_bases()
			if not node.BaseTypes then return false, report_error("Base type(s) expected") end

			node.type  = parse_type_assignment()
			if not node.type then return false, report_error("type assignment expected") end
		end

		return true, node
	end


	ParseExpr = function(scope) -> bool, P.ExprNode or string
		return ParseSubExpr(scope, 0)
	end


	local function parse_declaration(scope: S.Scope, token_list: L.TokenList,
		                              type: 'local' or 'global' or 'var') -> bool, any

		local angle_bracket = (tok:Peek().Data == '<')

		local is_local = (type ~= 'global')

		if tok:ConsumeKeyword('function', token_list) then
			if not tok:Is('Ident') then
				return false, report_error("Function name expected")
			end

			local var_name = tok:Get(token_list).Data
			local st, func = ParseFunctionArgsAndBody(scope, token_list)
			if not st then return false, func end

			func.AstType  = 'FunctionDecl'
			func.VarName  = var_name
			func.IsLocal  = is_local
			return true, func

		elseif tok:Is('Ident') or angle_bracket then
			local types = nil

			if type == 'var' then
				types = ParseTypeArgs(scope)
			elseif ParseTypeArgs(scope) then
				return false, report_error("%s cannot have type list - did you want 'var' ?", type)
			end

			if types and #types == 0 then
				return false, report_error("Empty type list")
			end

			local name_list = { tok:Get(token_list).Data }
			while tok:ConsumeSymbol(',', token_list) do
				if not tok:Is('Ident') then
					return false, report_error("local variable name expected")
				end
				name_list[#name_list+1] = tok:Get(token_list).Data
			end

			local init_list = {}
			if tok:ConsumeSymbol('=', token_list) then
				repeat
					local st, ex = ParseExpr(scope)
					if not st then return false, ex end
					init_list[#init_list+1] = ex
				until not tok:ConsumeSymbol(',', token_list)
			end

			local node_local = {}
			node_local.AstType   = 'VarDeclareStatement'
			node_local.TypeList  = types
			node_local.NameList  = name_list
			node_local.InitList  = init_list
			node_local.Tokens    = token_list
			node_local.IsLocal   = is_local
			node_local.type      = type   -- 'local' or 'global' or 'var'
			--
			return true, node_local

		else
			return false, report_error("local var_ or function def expected")
		end
	end


	local function ParseStatement(scope)
		local st = true  -- Success?
		local stat = nil
		local token_list = {}

		if tok:ConsumeKeyword('if', token_list) then
			--setup
			local node_if_stat = {}
			node_if_stat.AstType = 'IfStatement'
			node_if_stat.Clauses = {}

			--clauses
			repeat
				local st, node_cond = ParseExpr(scope)
				if not st then return false, node_cond end
				if not tok:ConsumeKeyword('then', token_list) then
					return false, report_error("`then` expected.")
				end
				local st, node_body = ParseStatementList(CreateScope(scope))
				if not st then return false, node_body end
				node_if_stat.Clauses[#node_if_stat.Clauses+1] = {
					Condition = node_cond;
					Body = node_body;
				}
			until not tok:ConsumeKeyword('elseif', token_list)

			--else clause
			if tok:ConsumeKeyword('else', token_list) then
				if tok:Peek().Data == 'if' and tok:Peek().AllLeadingWhite == ' ' then
					-- Warn agains C-style 'else if'
					report_error("Dangerous 'else if' here - did you mean 'elseif' ? (insert extra space to mute this error)")
				end

				local st, node_body = ParseStatementList(CreateScope(scope))
				if not st then return false, node_body end
				node_if_stat.Clauses[#node_if_stat.Clauses+1] = {
					Body = node_body;
				}
			end

			--end
			if not tok:ConsumeKeyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

			node_if_stat.Tokens = token_list
			stat = node_if_stat

		elseif tok:ConsumeKeyword('while', token_list) then
			--setup
			local node_while_stat = {}
			node_while_stat.AstType = 'WhileStatement'

			--condition
			local st, node_cond = ParseExpr(scope)
			if not st then return false, node_cond end

			--do
			if not tok:ConsumeKeyword('do', token_list) then
				return false, report_error("`do` expected.")
			end

			--body
			local st, node_body = ParseStatementList(CreateScope(scope))
			if not st then return false, node_body end

			--end
			if not tok:ConsumeKeyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

			--return
			node_while_stat.Condition = node_cond
			node_while_stat.Body      = node_body
			node_while_stat.Tokens    = token_list
			stat = node_while_stat

		elseif tok:ConsumeKeyword('do', token_list) then
			--do block
			local st, node_block = ParseStatementList(CreateScope(scope))
			if not st then return false, node_block end
			if not tok:ConsumeKeyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

			local node_do_stat = {}
			node_do_stat.AstType = 'DoStatement'
			node_do_stat.Body    = node_block
			node_do_stat.Tokens  = token_list
			stat = node_do_stat

		elseif tok:ConsumeKeyword('for', token_list) then
			--for block
			if not tok:Is('Ident') then
				return false, report_error("<ident> expected.")
			end
			local base_var_name = tok:Get(token_list)
			if tok:ConsumeSymbol('=', token_list) then
				--numeric for
				local for_scope = CreateScope(scope)
				--
				local st, start_ex = ParseExpr(scope)
				if not st then return false, start_ex end
				if not tok:ConsumeSymbol(',', token_list) then
					return false, report_error("`,` Expected")
				end
				local st, end_ex = ParseExpr(scope)
				if not st then return false, end_ex end
				local st, step_ex;
				if tok:ConsumeSymbol(',', token_list) then
					st, step_ex = ParseExpr(scope)
					if not st then return false, step_ex end
				end
				if not tok:ConsumeKeyword('do', token_list) then
					return false, report_error("`do` expected")
				end
				--
				local st, body = ParseStatementList(for_scope)
				if not st then return false, body end
				if not tok:ConsumeKeyword('end', token_list) then
					return false, report_error("`end` expected")
				end
				--
				local node_for = {}
				node_for.AstType  = 'NumericForStatement'
				node_for.scope    = for_scope
				node_for.VarName  = base_var_name.Data
				node_for.Start    = start_ex
				node_for.End      = end_ex
				node_for.Step     = step_ex
				node_for.Body     = body
				node_for.Tokens   = token_list
				stat = node_for
			else
				--generic for
				local for_scope = CreateScope(scope)
				--
				var var_names = { base_var_name.Data }
				while tok:ConsumeSymbol(',', token_list) do
					if not tok:Is('Ident') then
						return false, report_error("for variable expected.")
					end
					var_names[#var_names+1] = tok:Get(token_list).Data
				end
				if not tok:ConsumeKeyword('in', token_list) then
					return false, report_error("`in` expected.")
				end
				local generators = {}
				local st, first_generator = ParseExpr(scope)
				if not st then return false, first_generator end
				generators[#generators+1] = first_generator
				while tok:ConsumeSymbol(',', token_list) do
					local st, gen = ParseExpr(scope)
					if not st then return false, gen end
					generators[#generators+1] = gen
				end
				if not tok:ConsumeKeyword('do', token_list) then
					return false, report_error("`do` expected.")
				end
				local st, body = ParseStatementList(for_scope)
				if not st then return false, body end
				if not tok:ConsumeKeyword('end', token_list) then
					return false, report_error("`end` expected.")
				end
				--
				local node_for = {}
				node_for.AstType    = 'GenericForStatement'
				node_for.scope      = for_scope
				node_for.VarNames   = var_names
				node_for.Generators = generators
				node_for.Body       = body
				node_for.Tokens     = token_list
				stat = node_for
			end

		elseif tok:ConsumeKeyword('repeat', token_list) then
			local st, body = ParseStatementList(CreateScope(scope))
			if not st then return false, body end
			--
			if not tok:ConsumeKeyword('until', token_list) then
				return false, report_error("`until` expected.")
			end
			-- FIX: Used to parse in parent scope
			-- Now parses in repeat scope
			local st, cond = ParseExpr(body.scope)
			if not st then return false, cond end
			--
			local node_repeat = {}
			node_repeat.AstType   = 'RepeatStatement'
			node_repeat.Condition = cond
			node_repeat.Body      = body
			node_repeat.Tokens    = token_list
			node_repeat.scope     = body.scope
			stat = node_repeat

		elseif tok:ConsumeKeyword('function', token_list) then
			if not tok:Is('Ident') then
				return false, report_error("Function name expected")
			end
			local st, name = ParseSuffixedExpr(scope, true) --true => only dots and colons
			if not st then return false, name end
			--
			local is_mem_fun = (name.AstType == 'MemberExpr' and name.Indexer == ':')
			local st, func = ParseFunctionArgsAndBody(scope, token_list, is_mem_fun)
			if not st then return false, func end
			--
			func.AstType  = 'FunctionDecl'
			func.IsLocal  = false
			func.name     = name
			stat = func

		elseif tok:ConsumeKeyword('local', token_list) then
			st, stat = parse_declaration(scope, token_list, 'local')

		elseif settings.Sol and tok:ConsumeKeyword('global', token_list) then
			if tok:ConsumeKeyword('typedef') then
				st, stat = parse_typedef(scope, 'global')
			else
				st, stat = parse_declaration(scope, token_list, 'global')
			end

		elseif tok:ConsumeKeyword('var', token_list) then
			st, stat = parse_declaration(scope, token_list, 'var')

		elseif tok:ConsumeSymbol('::', token_list) then
			if not tok:Is('Ident') then
				return false, report_error('Label name expected')
			end
			local label = tok:Get(token_list).Data
			if not tok:ConsumeSymbol('::', token_list) then
				return false, report_error("`::` expected")
			end
			local node_label = {}
			node_label.AstType = 'LabelStatement'
			node_label.Label   = label
			node_label.Tokens  = token_list
			stat = node_label

		elseif tok:ConsumeKeyword('return', token_list) then
			local ex_list = {}
			if not tok:IsKeyword('end') and not tok:IsKeyword('else') and not tok:IsKeyword('elseif') then
				local st, first_ex = ParseExpr(scope)
				if st then
					ex_list[1] = first_ex
					while tok:ConsumeSymbol(',', token_list) do
						local st, ex = ParseExpr(scope)
						if not st then return false, ex end
						ex_list[#ex_list+1] = ex
					end
				end
			end

			local node_return = {}
			node_return.AstType   = 'ReturnStatement'
			node_return.Arguments = ex_list
			node_return.Tokens    = token_list
			stat = node_return

		elseif tok:ConsumeKeyword('break', token_list) then
			local node_break = {}
			node_break.AstType = 'BreakStatement'
			node_break.Tokens  = token_list
			stat = node_break

		elseif tok:ConsumeKeyword('goto', token_list) then
			if not tok:Is('Ident') then
				return false, report_error("Label expected")
			end
			local label = tok:Get(token_list).Data
			local node_goto = {}
			node_goto.AstType = 'GotoStatement'
			node_goto.Label   = label
			node_goto.Tokens  = token_list
			stat = node_goto


		elseif settings.Sol and tok:ConsumeKeyword('typedef') then
			st,stat = parse_typedef(scope, 'local')

		else
			--statement_parse_expr
			local st, suffixed = ParseSuffixedExpr(scope)
			if not st then return false, suffixed end

			--assignment or call?
			if tok:IsSymbol(',') or tok:IsSymbol('=') then
				--check that it was not parenthesized, making it not an lvalue
				if (suffixed.ParenCount or 0) > 0 then
					return false, report_error("Can not assign to parenthesized expression, is not an lvalue")
				end

				--more processing needed
				local lhs = { suffixed }
				while tok:ConsumeSymbol(',', token_list) do
					local st, lhs_part = ParseSuffixedExpr(scope)
					if not st then return false, lhs_part end
					lhs[#lhs+1] = lhs_part
				end

				--equals
				if not tok:ConsumeSymbol('=', token_list) then
					return false, report_error("`=` Expected.")
				end

				--rhs
				local rhs = {}
				local st, first_rhs = ParseExpr(scope)
				if not st then return false, first_rhs end
				rhs[1] = first_rhs
				while tok:ConsumeSymbol(',', token_list) do
					local st, rhs_part = ParseExpr(scope)
					if not st then return false, rhs_part end
					rhs[#rhs+1] = rhs_part
				end

				--done
				local node_assign = {}
				node_assign.AstType = 'AssignmentStatement'
				node_assign.Lhs     = lhs
				node_assign.Rhs     = rhs
				node_assign.Tokens  = token_list
				stat = node_assign

			elseif suffixed.AstType == 'CallExpr' or
				   suffixed.AstType == 'TableCallExpr' or
				   suffixed.AstType == 'StringCallExpr'
			then
				--it's a call statement
				local node_call = {}
				node_call.AstType    = 'CallStatement'
				node_call.Expression = suffixed
				node_call.Tokens     = token_list
				stat = node_call
			else
				return false, report_error("Assignment Statement Expected")
			end
		end
		
		if not st then return st, stat end

		assert(stat)

		if tok:IsSymbol(';') then
			stat.Semicolon = tok:Get( stat.Tokens )
		end

		return true, stat
	end


	local stat_list_close_keywords = bimap{'end', 'else', 'elseif', 'until'}

	ParseStatementList = function(scope) -> bool, P.Statlist or string
		assert(scope)
		local node_statlist   = {}
		node_statlist.scope   = scope
		node_statlist.AstType = 'Statlist'
		node_statlist.Body    = { }
		node_statlist.Tokens  = { }
		--
		--local stats = {}
		--
		while not stat_list_close_keywords[tok:Peek().Data] and not tok:IsEof() do
			local st, node_statement = ParseStatement(node_statlist.scope)
			if not st then return false, node_statement end
			--stats[#stats+1] = node_statement
			node_statlist.Body[#node_statlist.Body + 1] = node_statement
		end

		if tok:IsEof() then
			local node_eof = {}
			node_eof.AstType = 'Eof'
			node_eof.Tokens  = { tok:Get() }
			node_statlist.Body[#node_statlist.Body + 1] = node_eof
		end

		--
		--node_statlist.Body = stats
		return true, node_statlist
	end


	local function mainfunc()
		return ParseStatementList(module_scope)
	end

	local st, main = mainfunc()
	--print("Last Token: "..PrintTable(tok:Peek()))
	if num_err == 0 then
		return st, main
	else
		return false, main
	end
end

return P
