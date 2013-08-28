--[[ DO NOT MODIFY - COMPILED FROM sol/parser.sol --]] --
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
local bimap      = U.bimap


local P = {}

P.LuaSettings = {
	-- Lexer:
	symbols = bimap{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#'};

	keywords = bimap{
		'and',    'break', 'do',   'else',     'elseif',
		'end',    'false', 'for',  'function', 'goto', 'if',
		'in',     'local', 'nil',  'not',      'or',   'repeat',
		'return', 'then',  'true', 'until',    'while',
	};


	-- Sol extensions all off:
	is_sol         = false;
	function_types = false;
}

P.SolSettings = {
	-- Lexer:
	symbols = bimap{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#', '?', ':'};

	keywords = bimap{
		'and',    'break', 'do',   'else',     'elseif',
		'end',    'false', 'for',  'function', 'goto', 'if',
		'in',     'local', 'nil',  'not',      'or',   'repeat',
		'return', 'then',  'true', 'until',    'while',

		-- Sol specific:
		'typedef', 'global', 'var',
	};


	-- Parser:
	is_sol         = true;
	function_types = true;  -- Support  foo(arg : int) -> int
}


--------------------------------------------------------






































function P.parse_sol(src, tok, filename, settings, module_scope)
	filename = filename or ''
	settings = settings or P.SolSettings
	local num_err = 0

	--
	local function where_am_i(offset)
		return filename .. ":" .. tok:peek(offset).line
	end

	local function generate_msg(msg_fmt, ...)
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
		local scope = S.Scope:new(parent)
		scope.print = function() return "<Scope>" end
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
	local function parse_function_args_and_body(scope, token_list, is_mem_fun)
		local start = where_am_i()

		local func_scope = create_scope(scope)
		if not tok:consume_symbol('(', token_list) then
			return false, report_error("`(` expected.")
		end
		local  arg_list 




= {}
		local vararg  = nil

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
				local elem_type = T.Any

				if settings.function_types and tok:consume_symbol(':') then
					elem_type = parse_type(func_scope)
					if not elem_type then
						return false, report_error("type expected.")
					end
				end

				local var_arg_type = {
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
			return false, report_error("`end` expected after function body at %s", start)
		end

		local node_func = {
			--ast_type     = 'Function', LambdaFunctionExpr or FunctionDeclStatement
			scope       = func_scope,
			tokens      = token_list,
			IsMemFun    = is_mem_fun,
			arguments   = arg_list,
			vararg      = vararg,
			ReturnTypes = return_types,
			body        = body,
		}

		return true, node_func
	end


	parse_primary_expr = function(scope)
		local token_list = {}

		if tok:consume_symbol('(', token_list) then
			local st, ex = parse_expr(scope)
			if not st then return false, ex end
			if not tok:consume_symbol(')', token_list) then
				return false, report_error("`)` Expected.")
			end

			local parens_exp = {}
			parens_exp.ast_type   = 'ParenthesesExpr'
			parens_exp.inner     = ex
			parens_exp.tokens    = token_list
			return true, parens_exp

		elseif tok:is('ident') then
			local id = tok:get(token_list)

			return true, {
				ast_type = 'IdExpr',
				name    = id.data,
				tokens  = token_list
			}
		else
			return false, report_error("primary expression expected")
		end
	end

	parse_suffixed_expr = function(scope, only_dot_colon)
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
				local args = {}
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


	parse_simple_expr = function(scope)
		local token_list = {}

		if tok:is('Number') then
			local node_num = {}
			node_num.ast_type = 'NumberExpr'
			node_num.value   = tok:get(token_list)
			node_num.tokens  = token_list
			return true, node_num

		elseif tok:is('String') then
			local node_str = {}
			node_str.ast_type = 'StringExpr'
			node_str.value   = tok:get(token_list)
			node_str.tokens  = token_list
			return true, node_str

		elseif tok:consume_keyword('nil', token_list) then
			local node_nil = {}
			node_nil.ast_type = 'NilExpr'
			node_nil.tokens  = token_list
			return true, node_nil

		elseif tok:is_keyword('false') or tok:is_keyword('true') then
			local node_boolean = {}
			node_boolean.ast_type = 'BooleanExpr'
			node_boolean.value   = (tok:get(token_list).data == 'true')
			node_boolean.tokens  = token_list
			return true, node_boolean

		elseif tok:consume_symbol('...', token_list) then
			local node_dots = {}
			node_dots.ast_type  = 'DotsExpr'
			node_dots.tokens   = token_list
			return true, node_dots

		elseif tok:consume_symbol('{', token_list) then
			local v = {}
			v.ast_type = 'ConstructorExpr'
			v.entry_list = {}
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
					v.entry_list[#v.entry_list+1] = {
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
						v.entry_list[#v.entry_list+1] = {
							type  = 'KeyString';
							key   = key.data;
							value = value;
						}

					else
						--we are a value
						local st, value = parse_expr(scope)
						if not st then
							return false, report_error("value Exected")
						end
						v.entry_list[#v.entry_list+1] = {
							type = 'value';
							value = value;
						}

					end
				elseif tok:consume_symbol('}', token_list) then
					break

				else
					--value
					local st, value = parse_expr(scope)
					v.entry_list[#v.entry_list+1] = {
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
			v.tokens  = token_list
			return true, v

		elseif tok:consume_keyword('function', token_list) then
			-- Parse lambda
			local st, func = parse_function_args_and_body(scope, token_list)
			if not st then return false, func end
			--
			func.ast_type = 'LambdaFunctionExpr'
			func.is_local = true
			return true, func

		else
			return parse_suffixed_expr(scope)
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

	parse_sub_expr = function(scope, level)
		--base item, possibly with unop prefix
		local st, exp
		if unops[tok:peek().data] then
			local token_list = {}
			local op = tok:get(token_list).data
			st, exp = parse_sub_expr(scope, unopprio)
			if not st then return false, exp end
			local node_ex = {}
			node_ex.ast_type = 'UnopExpr'
			node_ex.rhs     = exp
			node_ex.op      = op
			node_ex.op_precedence = unopprio
			node_ex.tokens  = token_list
			exp = node_ex
		else
			st, exp = parse_simple_expr(scope)
			if not st then return false, exp end
		end

		--next items in chain
		while true do
			local prio = priority[tok:peek().data]
			if prio and prio[1] > level then
				local token_list = {}
				local op = tok:get(token_list).data
				local st, rhs = parse_sub_expr(scope, prio[2])
				if not st then return false, rhs end
				local node_ex = {}
				node_ex.ast_type = 'BinopExpr'
				node_ex.lhs     = exp
				node_ex.op      = op
				node_ex.op_precedence = prio[1]
				node_ex.rhs     = rhs
				node_ex.tokens  = token_list
				--
				exp = node_ex
			else
				break
			end
		end

		return true, exp
	end


	parse_simple_type = function(scope)
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
				-- Empty object
				return {
					tag = 'object',
					members = {}
				}
			elseif tok:is('ident') and tok:peek(1).data == ':' then
				-- key-value-pairs - an object
				local obj = {
					tag = 'object',
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
				-- a map?
				local key_type   = parse_type(scope)
				local sep        = tok:consume_symbol('=>')
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
			end
		end

		if tok:consume_keyword('function') then
			if not tok:consume_symbol('(') then
				report_error("Expected (")
				return T.Any
			end

			local fun_t = {
				tag    = 'function',
				args   = {},
				vararg = nil,
				rets   = nil,
				name   = nil,
			}

			if not tok:consume_symbol(')') then
				while true do
					if tok:consume_symbol('...') then
						fun_t.vararg = T.Any

						if tok:consume_symbol(':') then
							fun_t.vararg = parse_type(scope)
						end

						if not tok:consume_symbol(')') then
							report_error('vararg (...) must be last argument to function')
						end

						break
					end

					local arg_name = nil
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
			if t then return t end
			if not t then
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


	parse_type = function(scope)
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


	parse_type_list = function(scope)

		if tok:peek().data == 'void' then
			tok:get()
			return T.Void
		end

		local list = nil
		while true do
			local type = parse_type(scope)
			if not type then
				return list;
			end

			list = list or {}
			table.insert(list, type)
			if not tok:consume_symbol(',') then
				return list
			end
		end
	end


	-- Parses a type-list within (and including) angle brackets: <int,string>
	parse_type_args = function(scope)
		if tok:consume_symbol('<') then
			local list = parse_type_list(scope) or {}  -- Empty list OK
			if not tok:consume_symbol('>') then
				return nil, report_error("Missing '>'")
			end
			return list
		else
			return nil -- No type-args here
		end
	end


	local function parse_typedef(scope, type)
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
			ast_type   = 'Typedef',
			scope     = scope,
			TypeName  = type_name,
			tokens    = {},
			where     = where,
			Global    = (type == 'global')
		}

		if not tok:consume_symbol('.') then
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

			type_name = tok:get_ident()
			if not type_name then
				return false, report_error("Identifier expected")
			end

			--node.Variable  = var_
			node.namespace_name = base_name
			node.TypeName      = type_name
		end

		-- Are we a forward-declare?
		if not tok:consume_symbol(';') then
			node.BaseTypes = parse_bases()
			if not node.BaseTypes then return false, report_error("base type(s) expected") end

			node.type  = parse_type_assignment()
			if not node.type then return false, report_error("type assignment expected") end
		end

		return true, node
	end


	parse_expr = function(scope)
		return parse_sub_expr(scope, 0)
	end


	local function parse_declaration(scope, token_list,
		                              type)

		local angle_bracket = (tok:peek().data == '<')

		local is_local = (type ~= 'global')

		if tok:consume_keyword('function', token_list) then
			if not tok:is('ident') then
				return false, report_error("Function name expected")
			end

			local var_name = tok:get(token_list).data
			local st, func = parse_function_args_and_body(scope, token_list)
			if not st then return false, func end

			func.ast_type  = 'FunctionDeclStatement'
			func.var_name  = var_name
			func.is_local  = is_local
			return true, func

		elseif tok:is('ident') or angle_bracket then
			local types = nil

			if type == 'var' then
				types = parse_type_args(scope)
			elseif parse_type_args(scope) then
				return false, report_error("%s cannot have type list - did you want 'var' ?", type)
			end

			if types and #types == 0 then
				return false, report_error("Empty type list")
			end

			local name_list = { tok:get(token_list).data }
			while tok:consume_symbol(',', token_list) do
				if not tok:is('ident') then
					return false, report_error("local variable name expected")
				end
				name_list[#name_list+1] = tok:get(token_list).data
			end

			local init_list = {}
			if tok:consume_symbol('=', token_list) then
				repeat
					local st, ex = parse_expr(scope)
					if not st then return false, ex end
					init_list[#init_list+1] = ex
				until not tok:consume_symbol(',', token_list)
			end

			local node_local = {}
			node_local.ast_type   = 'VarDeclareStatement'
			node_local.TypeList  = types
			node_local.name_list  = name_list
			node_local.init_list  = init_list
			node_local.tokens    = token_list
			node_local.is_local   = is_local
			node_local.type      = type   -- 'local' or 'global' or 'var'
			--
			return true, node_local

		else
			return false, report_error("local var_ or function def expected")
		end
	end


	local function parse_statement(scope)
		local st = true  -- Success?
		local stat = nil
		local token_list = {}

		if tok:consume_keyword('if', token_list) then
			--setup
			local node_if_stat = {}
			node_if_stat.ast_type = 'IfStatement'
			node_if_stat.clauses = {}

			--clauses
			repeat
				local st, node_cond = parse_expr(scope)
				if not st then return false, node_cond end
				if not tok:consume_keyword('then', token_list) then
					return false, report_error("`then` expected.")
				end
				local st, node_body = parse_statement_list(create_scope(scope))
				if not st then return false, node_body end
				node_if_stat.clauses[#node_if_stat.clauses+1] = {
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
				node_if_stat.clauses[#node_if_stat.clauses+1] = {
					body = node_body;
				}
			end

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.")
			end

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
				--
				local st, start_ex = parse_expr(scope)
				if not st then return false, start_ex end
				if not tok:consume_symbol(',', token_list) then
					return false, report_error("`,` Expected")
				end
				local st, end_ex = parse_expr(scope)
				if not st then return false, end_ex end
				local st, step_ex;
				if tok:consume_symbol(',', token_list) then
					st, step_ex = parse_expr(scope)
					if not st then return false, step_ex end
				end
				if not tok:consume_keyword('do', token_list) then
					return false, report_error("`do` expected")
				end
				--
				local st, body = parse_statement_list(for_scope)
				if not st then return false, body end
				if not tok:consume_keyword('end', token_list) then
					return false, report_error("`end` expected")
				end
				--
				local node_for = {}
				node_for.ast_type = 'NumericForStatement'
				node_for.scope    = for_scope
				node_for.var_name = base_var_name.data
				node_for.start    = start_ex
				node_for.end_     = end_ex
				node_for.step     = step_ex
				node_for.body     = body
				node_for.tokens   = token_list
				stat = node_for
			else
				--generic for
				local for_scope = create_scope(scope)
				--
				local var_names = { base_var_name.data }
				while tok:consume_symbol(',', token_list) do
					if not tok:is('ident') then
						return false, report_error("for variable expected.")
					end
					var_names[#var_names+1] = tok:get(token_list).data
				end
				if not tok:consume_keyword('in', token_list) then
					return false, report_error("`in` expected.")
				end
				local generators = {}
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
				local node_for = {}
				node_for.ast_type    = 'GenericForStatement'
				node_for.scope      = for_scope
				node_for.var_names   = var_names
				node_for.generators = generators
				node_for.body       = body
				node_for.tokens     = token_list
				stat = node_for
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
			node_repeat.ast_type   = 'RepeatStatement'
			node_repeat.condition = cond
			node_repeat.body      = body
			node_repeat.tokens    = token_list
			node_repeat.scope     = body.scope
			stat = node_repeat

		elseif tok:consume_keyword('function', token_list) then
			if not tok:is('ident') then
				return false, report_error("Function name expected")
			end
			local st, name = parse_suffixed_expr(scope, true) --true => only dots and colons
			if not st then return false, name end
			--
			local is_mem_fun = (name.ast_type == 'MemberExpr' and name.indexer == ':')
			local st, func = parse_function_args_and_body(scope, token_list, is_mem_fun)
			if not st then return false, func end
			--
			func.ast_type  = 'FunctionDeclStatement'
			func.is_local  = false
			func.name     = name
			stat = func

		elseif tok:consume_keyword('local', token_list) then
			st, stat = parse_declaration(scope, token_list, 'local')

		elseif settings.is_sol and tok:consume_keyword('global', token_list) then
			if tok:consume_keyword('typedef') then
				st, stat = parse_typedef(scope, 'global')
			else
				st, stat = parse_declaration(scope, token_list, 'global')
			end

		elseif tok:consume_keyword('var', token_list) then
			st, stat = parse_declaration(scope, token_list, 'var')

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
			local ex_list = {}
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

			local node_return = {}
			node_return.ast_type   = 'ReturnStatement'
			node_return.arguments = ex_list
			node_return.tokens    = token_list
			stat = node_return

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
			local node_goto = {}
			node_goto.ast_type = 'GotoStatement'
			node_goto.label   = label
			node_goto.tokens  = token_list
			stat = node_goto


		elseif settings.is_sol and tok:consume_keyword('typedef') then
			st,stat = parse_typedef(scope, 'local')

		else
			--statement_parse_expr
			local st, suffixed = parse_suffixed_expr(scope)
			if not st then return false, suffixed end

			--assignment or call?
			if tok:is_symbol(',') or tok:is_symbol('=') then
				--check that it was not parenthesized, making it not an lvalue
				if (suffixed.paren_count or 0) > 0 then
					return false, report_error("Can not assign to parenthesized expression, is not an lvalue")
				end

				--more processing needed
				local lhs = { suffixed }
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
				local rhs = {}
				local st, first_rhs = parse_expr(scope)
				if not st then return false, first_rhs end
				rhs[1] = first_rhs
				while tok:consume_symbol(',', token_list) do
					local st, rhs_part = parse_expr(scope)
					if not st then return false, rhs_part end
					rhs[#rhs+1] = rhs_part
				end

				--done
				local node_assign = {}
				node_assign.ast_type = 'AssignmentStatement'
				node_assign.lhs     = lhs
				node_assign.rhs     = rhs
				node_assign.tokens  = token_list
				stat = node_assign

			elseif suffixed.ast_type == 'CallExpr' or
				   suffixed.ast_type == 'TableCallExpr' or
				   suffixed.ast_type == 'StringCallExpr'
			then
				--it's a call statement
				local node_call = {}
				node_call.ast_type    = 'CallStatement'
				node_call.expression = suffixed
				node_call.tokens     = token_list
				stat = node_call
			else
				return false, report_error("Assignment Statement Expected")
			end
		end
		
		if not st then return st, stat end

		assert(stat)

		if tok:is_symbol(';') then
			stat.semicolon = tok:get( stat.tokens )
		end

		return true, stat
	end


	local stat_list_close_keywords = bimap{'end', 'else', 'elseif', 'until'}

	parse_statement_list = function(scope)
		assert(scope)
		local node_statlist   = {}
		node_statlist.scope   = scope
		node_statlist.ast_type = 'Statlist'
		node_statlist.body    = { }
		node_statlist.tokens  = { }
		--
		--local stats = {}
		--
		while not stat_list_close_keywords[tok:peek().data] and not tok:is_eof() do
			local st, node_statement = parse_statement(node_statlist.scope)
			if not st then return false, node_statement end
			--stats[#stats+1] = node_statement
			node_statlist.body[#node_statlist.body + 1] = node_statement
		end

		if tok:is_eof() then
			local node_eof = {}
			node_eof.ast_type = 'Eof'
			node_eof.tokens  = { tok:get() }
			node_statlist.body[#node_statlist.body + 1] = node_eof
		end

		--
		--node_statlist.body = stats
		return true, node_statlist
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
