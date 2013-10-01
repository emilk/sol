--[[ DO NOT MODIFY - COMPILED FROM sol/parser.sol on 2013 Oct 01  21:36:21 --]] --
-- parse_sol.lua
-- parse_sol taken in a token stream (from the lexer)
-- and outputs an AST.
-- It keeps track of scoping and variables.


local L = require 'lexer' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 
local S = require 'scope' --[[SOL OUTPUT--]] 
local T = require 'type' --[[SOL OUTPUT--]]  -- For intrinsic functions
local U = require 'util' --[[SOL OUTPUT--]] 

local printf_err = U.printf_err --[[SOL OUTPUT--]] 
local set        = U.set --[[SOL OUTPUT--]] 

local P = {} --[[SOL OUTPUT--]] 


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

	-- Enabled warnings - names matches GCC - http://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
	issues = {
		['unused-parameter']     = 'SPAM',
		['unused-loop-variable'] = 'SPAM',
		['unused-variable']      = 'WARNING',
		['unassigned-variable']  = 'WARNING';
	}
} --[[SOL OUTPUT--]] 

P.SOL_SETTINGS = {
	-- Lexer:
	symbols = set{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#',  '?', ':', '!'};

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
	}
} --[[SOL OUTPUT--]] 


local stat_list_close_keywords = set{'end', 'else', 'elseif', 'until'} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 


--------------------------------------------------------


































































































































































































































































































function P.parse_sol(src, tok, filename, settings, module_scope)
	filename = filename or '' --[[SOL OUTPUT--]] 
	settings = settings or P.SOL_SETTINGS --[[SOL OUTPUT--]] 
	local num_err = 0 --[[SOL OUTPUT--]] 

	--
	local function where_am_i(offset)
		local token = tok:peek(offset) --[[SOL OUTPUT--]] 
		return filename .. ":" .. token.line --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function generate_msg(msg_fmt, ...)
		local msg = string.format(msg_fmt, ...) --[[SOL OUTPUT--]] 
		--local err = ">> :"..tok:peek().line..":"..tok:peek().char..": "..msg.."\n"
		local err = "solc: "..where_am_i(-1)..": "..msg.."\n" --[[SOL OUTPUT--]] 
		--find the line
		local line_num = 0 --[[SOL OUTPUT--]] 
		for line in src:gmatch("[^\n]*\n?") do
			if line:sub(-1,-1) == '\n' then line = line:sub(1,-2) --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			line_num = line_num+1 --[[SOL OUTPUT--]] 
			if line_num == tok:peek().line then
				err = err..">> `"..line:gsub('\t','    ').."`\n" --[[SOL OUTPUT--]] 
				for i = 1, tok:peek().char do
					local c = line:sub(i,i) --[[SOL OUTPUT--]] 
					if c == '\t' then
						err = err..'    ' --[[SOL OUTPUT--]] 
					else
						err = err..' ' --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if not tok:peek().data then
					err = err.."   ^^^^" --[[SOL OUTPUT--]] 
				else
					err = err.."   ^" --[[SOL OUTPUT--]] 
					for i = 2, #tok:peek().data do
						err = err.."^" --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				break --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return err --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_error(msg_fmt, ...)
		num_err = num_err + 1 --[[SOL OUTPUT--]] 
		local msg = generate_msg(msg_fmt, ...) --[[SOL OUTPUT--]] 
		printf_err("%s", msg) --[[SOL OUTPUT--]] 
		return msg --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_warning(msg_fmt, ...)
		local msg = generate_msg(msg_fmt, ...) --[[SOL OUTPUT--]] 
		print( msg ) --[[SOL OUTPUT--]] 
		return msg --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_spam(msg_fmt, ...)
		if _G.g_spam then
			local msg = generate_msg(msg_fmt, ...) --[[SOL OUTPUT--]] 
			print( msg ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_sol_error(msg_fmt, ...)
		if settings.is_sol then
			report_error(msg_fmt, ...) --[[SOL OUTPUT--]] 
		else
			report_warning(msg_fmt, ...) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function create_scope(parent)
		local scope = Scope.new(where_am_i(), parent) --[[SOL OUTPUT--]] 
		--report_spam("New scope %s, parent: %s", tostring(scope), tostring(parent))
		return scope --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local parse_expr --[[SOL OUTPUT--]]  
	local parse_statement_list --[[SOL OUTPUT--]] 
	local parse_simple_expr, 
	      parse_sub_expr,
	      parse_primary_expr,
	      parse_suffixed_expr,
	      parse_simple_type,
	      parse_type,
	      parse_type_list,
	      parse_type_args --[[SOL OUTPUT--]] 


	-- is_mem_fun: we where declared like  foo:fun(args)  and thus have an implicit 'self'
	local function parse_function_args_and_body(scope, token_list, type)

		
local is_mem_fun = (type == 'mem_fun') --[[SOL OUTPUT--]] 
		local where = where_am_i() --[[SOL OUTPUT--]] 

		local func_scope = create_scope(scope) --[[SOL OUTPUT--]] 
		if not tok:consume_symbol('(', token_list) then
			return false, report_error("`(` expected.") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 
		local  arg_list 




= {} --[[SOL OUTPUT--]] 
		local vararg  = nil --[[SOL OUTPUT--]] 

		while not tok:consume_symbol(')', token_list) do
			if tok:is('ident') then
				local arg = {
					name = tok:get(token_list).data
				} --[[SOL OUTPUT--]] 

				if settings.function_types and tok:consume_symbol(':') then
					arg.type = parse_type(func_scope) --[[SOL OUTPUT--]] 
					if not arg.type then
						return false, report_error("type expected.") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				arg_list[#arg_list+1] = arg --[[SOL OUTPUT--]] 

				if not tok:consume_symbol(',', token_list) then
					if tok:consume_symbol(')', token_list) then
						break --[[SOL OUTPUT--]] 
					else
						return false, report_error("`)` expected.") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			elseif tok:consume_symbol('...', token_list) then
				local elem_type = T.Any --[[SOL OUTPUT--]] 

				if settings.function_types and tok:consume_symbol(':') then
					elem_type = parse_type(func_scope) --[[SOL OUTPUT--]] 
					if not elem_type then
						return false, report_error("type expected.") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local var_arg_type = {
					tag  = 'varargs',
					type = elem_type,
				} --[[SOL OUTPUT--]] 
				vararg = var_arg_type --[[SOL OUTPUT--]] 

				if not tok:consume_symbol(')', token_list) then
					return false, report_error("`...` must be the last argument of a function.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				break --[[SOL OUTPUT--]] 
			else
				return false, report_error("Argument name or `...` expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local return_types = nil --[[SOL OUTPUT--]] 

		if settings.function_types and tok:consume_symbol('->') then
			return_types = parse_type_list(func_scope) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local st,body --[[SOL OUTPUT--]] 

		if tok:consume_symbol('=') and tok:consume_keyword('extern') then
			-- extern - used by lua_intrinsics.sol
		else
			--body
			st, body = parse_statement_list(func_scope) --[[SOL OUTPUT--]] 
			if not st then return false, body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected after function body in %s", where) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

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
		} --[[SOL OUTPUT--]] 

		return true, node_func --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function parse_id_expr()
		assert(tok:is('ident')) --[[SOL OUTPUT--]] 

		local token_list = {} --[[SOL OUTPUT--]] 
		local where = where_am_i() --[[SOL OUTPUT--]] 
		local id = tok:get(token_list) --[[SOL OUTPUT--]] 

		return {
			ast_type = 'IdExpr';
			name     = id.data;
			tokens   = token_list;
			where    = where;
		} --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	parse_primary_expr = function(scope)
		local token_list = {} --[[SOL OUTPUT--]] 
		local where = where_am_i() --[[SOL OUTPUT--]] 

		if tok:consume_symbol('(', token_list) then
			local st, ex = parse_expr(scope) --[[SOL OUTPUT--]] 
			if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			if not tok:consume_symbol(')', token_list) then
				return false, report_error("`)` Expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local parens_exp = {
				ast_type = 'ParenthesesExpr';
				inner    = ex;
				tokens   = token_list;
				where    = where;
			} --[[SOL OUTPUT--]] 
			return true, parens_exp --[[SOL OUTPUT--]] 

		elseif tok:is('ident') then
			return true, parse_id_expr() --[[SOL OUTPUT--]] 
		else
			return false, report_error("primary expression expected") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_suffixed_expr = function(scope, style)
		local only_dot_colon = (style == 'only_dot_colon') --[[SOL OUTPUT--]] 

		--base primary expression
		local st, prim = parse_primary_expr(scope) --[[SOL OUTPUT--]] 
		if not st then return false, prim --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
		--
		while true do
			local token_list = {} --[[SOL OUTPUT--]] 
			local where = where_am_i() --[[SOL OUTPUT--]] 

			if tok:is_symbol('.') or tok:is_symbol(':') then
				local symb = tok:get(token_list).data --[[SOL OUTPUT--]] 
				if not tok:is('ident') then
					return false, report_error("<ident> expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local id = tok:get(token_list) --[[SOL OUTPUT--]] 
				local node_index = {} --[[SOL OUTPUT--]] 
				node_index.ast_type  = 'MemberExpr' --[[SOL OUTPUT--]] 
				node_index.base     = prim --[[SOL OUTPUT--]] 
				node_index.indexer  = symb --[[SOL OUTPUT--]] 
				node_index.ident    = id --[[SOL OUTPUT--]] 
				node_index.tokens   = token_list --[[SOL OUTPUT--]] 
				node_index.where    = where --[[SOL OUTPUT--]] 
				--
				prim = node_index --[[SOL OUTPUT--]] 

			elseif not only_dot_colon and tok:consume_symbol('[', token_list) then
				local st, ex = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				if not tok:consume_symbol(']', token_list) then
					return false, report_error("`]` expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local node_index = {} --[[SOL OUTPUT--]] 
				node_index.ast_type  = 'IndexExpr' --[[SOL OUTPUT--]] 
				node_index.base     = prim --[[SOL OUTPUT--]] 
				node_index.index    = ex --[[SOL OUTPUT--]] 
				node_index.tokens   = token_list --[[SOL OUTPUT--]] 
				node_index.where    = where --[[SOL OUTPUT--]] 
				--
				prim = node_index --[[SOL OUTPUT--]] 

			elseif not only_dot_colon and tok:consume_symbol('(', token_list) then
				local args = {} --[[SOL OUTPUT--]] 
				while not tok:consume_symbol(')', token_list) do
					local st, ex = parse_expr(scope) --[[SOL OUTPUT--]] 
					if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					args[#args+1] = ex --[[SOL OUTPUT--]] 
					if not tok:consume_symbol(',', token_list) then
						if tok:consume_symbol(')', token_list) then
							break --[[SOL OUTPUT--]] 
						else
							return false, report_error("`)` Expected.") --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local node_call = {} --[[SOL OUTPUT--]] 
				node_call.ast_type  = 'CallExpr' --[[SOL OUTPUT--]] 
				node_call.base      = prim --[[SOL OUTPUT--]] 
				node_call.arguments = args --[[SOL OUTPUT--]] 
				node_call.tokens    = token_list --[[SOL OUTPUT--]] 
				node_call.where     = where --[[SOL OUTPUT--]] 
				--
				prim = node_call --[[SOL OUTPUT--]] 

			elseif not only_dot_colon and tok:is('String') then
				--string call
				local st, ex = parse_simple_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				local node_call = {} --[[SOL OUTPUT--]] 
				node_call.ast_type  = 'StringCallExpr' --[[SOL OUTPUT--]] 
				node_call.base      = prim --[[SOL OUTPUT--]] 
				--node_call.arguments  = { tok:get(token_list) }
				node_call.arguments = { ex } --[[SOL OUTPUT--]] 
				node_call.tokens    = token_list --[[SOL OUTPUT--]] 
				node_call.where     = where --[[SOL OUTPUT--]] 
				--
				prim = node_call --[[SOL OUTPUT--]] 

			elseif not only_dot_colon and tok:is_symbol('{') then
				--table call
				local st, ex = parse_simple_expr(scope) --[[SOL OUTPUT--]] 
				-- FIX: parse_expr(scope) parses the table AND and any following binary expressions.
				-- We just want the table
				if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				local node_call = {} --[[SOL OUTPUT--]] 
				node_call.ast_type  = 'TableCallExpr' --[[SOL OUTPUT--]] 
				node_call.base      = prim --[[SOL OUTPUT--]] 
				node_call.arguments = { ex } --[[SOL OUTPUT--]] 
				node_call.tokens    = token_list --[[SOL OUTPUT--]] 
				node_call.where     = where --[[SOL OUTPUT--]] 
				--
				prim = node_call --[[SOL OUTPUT--]] 

			else
				break --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return true, prim --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_simple_expr = function(scope)
		local token_list = {} --[[SOL OUTPUT--]] 
		local   node       = nil --[[SOL OUTPUT--]] 
		local            where      = where_am_i() --[[SOL OUTPUT--]] 

		if tok:is('Number') then
			node = {
				ast_type = 'NumberExpr';
				value    = tok:get(token_list);
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:is('String') then
			node = {
				ast_type = 'StringExpr';
				value    = tok:get(token_list);
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('nil', token_list) then
			node = {
				ast_type = 'NilExpr';
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('extern', token_list) then
			node = {
				ast_type = 'ExternExpr';
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:is_keyword('false') or tok:is_keyword('true') then
			node = {
				ast_type = 'BooleanExpr';
				value    = (tok:get(token_list).data == 'true');
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:consume_symbol('...', token_list) then
			node = {
				ast_type = 'DotsExpr';
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:consume_symbol('{', token_list) then
			--var entry_list = {} : [ConstructorExprEntry] -- TODO
			local entry_list = {} --[[SOL OUTPUT--]] 
			--
			while true do
				if tok:is_symbol('[', token_list) then
					--key
					tok:get(token_list) --[[SOL OUTPUT--]] 
					local st, key = parse_expr(scope) --[[SOL OUTPUT--]] 
					if not st then
						return false, report_error("key expression Expected") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					if not tok:consume_symbol(']', token_list) then
						return false, report_error("`]` Expected") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					if not tok:consume_symbol('=', token_list) then
						return false, report_error("`=` Expected") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					local st, value = parse_expr(scope) --[[SOL OUTPUT--]] 
					if not st then
						return false, report_error("value expression Expected") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					entry_list[#entry_list+1] = {
						type  = 'key';
						key   = key;
						value = value;
					} --[[SOL OUTPUT--]] 

				elseif tok:is('ident') then
					--value or key
					local lookahead = tok:peek(1) --[[SOL OUTPUT--]] 
					if lookahead.type == 'Symbol' and lookahead.data == '=' then
						--we are a key
						local key = tok:get(token_list) --[[SOL OUTPUT--]] 
						if not tok:consume_symbol('=', token_list) then
							return false, report_error("`=` Expected") --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						local st, value = parse_expr(scope) --[[SOL OUTPUT--]] 
						if not st then
							return false, report_error("value expression Expected") --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						entry_list[#entry_list+1] = {
							type  = 'ident_key';
							key   = key.data;
							value = value;
						} --[[SOL OUTPUT--]] 

					else
						--we are a value
						local st, value = parse_expr(scope) --[[SOL OUTPUT--]] 
						if not st then
							return false, report_error("value Exected") --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						entry_list[#entry_list+1] = {
							type = 'value';
							value = value;
						} --[[SOL OUTPUT--]] 

					end --[[SOL OUTPUT--]] 
				elseif tok:consume_symbol('}', token_list) then
					break --[[SOL OUTPUT--]] 

				else
					--value
					local st, value = parse_expr(scope) --[[SOL OUTPUT--]] 
					entry_list[#entry_list+1] = {
						type = 'value';
						value = value;
					} --[[SOL OUTPUT--]] 
					if not st then
						return false, report_error("value Expected") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if tok:consume_symbol(';', token_list) or tok:consume_symbol(',', token_list) then
					--all is good
				elseif tok:consume_symbol('}', token_list) then
					break --[[SOL OUTPUT--]] 
				else
					return false, report_error("`}` or table entry expected") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			node = {
				ast_type   = 'ConstructorExpr';
				entry_list = entry_list;
				tokens     = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('function', token_list) then
			-- Parse lambda
			local st, lambda_node = parse_function_args_and_body(scope, token_list) --[[SOL OUTPUT--]] 
			if not st then return false, lambda_node --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			--
			node = lambda_node --[[SOL OUTPUT--]] 
			node.ast_type = 'LambdaFunctionExpr' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if node then
			node.where = where --[[SOL OUTPUT--]] 
			return true, node --[[SOL OUTPUT--]] 
		else
			return parse_suffixed_expr(scope) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local unops = set{'-', 'not', '#'} --[[SOL OUTPUT--]] 
	local unopprio = 8 --[[SOL OUTPUT--]] 
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
	} --[[SOL OUTPUT--]] 

	parse_sub_expr = function(scope, prio_level)
		local    st    = false --[[SOL OUTPUT--]] 
		local exp   = nil --[[SOL OUTPUT--]] 
		local          where = where_am_i() --[[SOL OUTPUT--]] 

		--base item, possibly with unop prefix
		if unops[tok:peek().data] then
			local token_list = {} --[[SOL OUTPUT--]] 
			local op = tok:get(token_list).data --[[SOL OUTPUT--]] 
			st, exp = parse_sub_expr(scope, unopprio) --[[SOL OUTPUT--]] 
			if not st then return false, exp --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			local node_ex = {
				ast_type = 'UnopExpr';
				rhs      = exp;
				op       = op;
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 
			exp = node_ex --[[SOL OUTPUT--]] 
		else
			st, exp = parse_simple_expr(scope) --[[SOL OUTPUT--]] 
			if not st then return false, exp --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--next items in chain
		while true do
			local prio = priority[tok:peek().data] --[[SOL OUTPUT--]] 
			if prio and prio[1] > prio_level then
				local token_list = {} --[[SOL OUTPUT--]] 
				local op = tok:get(token_list).data --[[SOL OUTPUT--]] 
				local st, rhs = parse_sub_expr(scope, prio[2]) --[[SOL OUTPUT--]] 
				if not st then return false, rhs --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				local node_ex = {
					ast_type = 'BinopExpr';
					lhs      = exp;
					op       = op;
					rhs      = rhs;
					tokens   = token_list;
				} --[[SOL OUTPUT--]] 
				--
				exp = node_ex --[[SOL OUTPUT--]] 
			else
				break --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		exp.where = exp.where or where --[[SOL OUTPUT--]] 

		return true, exp --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_simple_type = function(scope)
		if tok:consume_symbol('[') then
			local type = parse_type(scope) --[[SOL OUTPUT--]] 
			if not type then
				report_error("Expected type in list declaration, e.g. [int]") --[[SOL OUTPUT--]] 
				tok:consume_symbol(']') --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if not tok:consume_symbol(']') then
				report_error("Missing ']' after list declaration") --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return {
				tag  = "list",
				type = type
			} --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if tok:consume_symbol('{') then
			-- Object or map?
			if tok:consume_symbol('}') then
				report_error("Use 'object'") --[[SOL OUTPUT--]] 
				return T.create_empty_table() --[[SOL OUTPUT--]] 
			elseif tok:is('ident') and tok:peek(1).data == ':' then
				-- key-value-pairs - an object
				local obj = {
					tag     = 'object',
					members = {}
				} --[[SOL OUTPUT--]] 
				while true do
					if tok:consume_symbol('}') then break --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

					if not tok:is('ident') then
						report_error('Bad object: identifier expected') --[[SOL OUTPUT--]] 
						return T.Any --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					
					local id = tok:get().data --[[SOL OUTPUT--]] 

					if not tok:consume_symbol(':') then
						report_error("Bad object: expected ':'") --[[SOL OUTPUT--]] 
						return T.Any --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					local type = parse_type(scope) --[[SOL OUTPUT--]] 
					if not type then
						report_error("Bad object: expected type") --[[SOL OUTPUT--]] 
						return T.Any --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if obj.members[id] then
						report_error("Object member '%s' declared twice", id) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					obj.members[id] = type --[[SOL OUTPUT--]] 

					if not tok:consume_symbol(',') and not tok:consume_symbol(';') then
						if tok:consume_symbol('}') then
							break --[[SOL OUTPUT--]] 
						else
							report_error("Bad object declaration: expected either , or }") --[[SOL OUTPUT--]] 
							return T.Any --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				--U.make_const(obj.members)
				return obj --[[SOL OUTPUT--]] 
			else
				-- a map or a set
				local key_type   = parse_type(scope) --[[SOL OUTPUT--]] 
				local sep        = tok:consume_symbol('=>') --[[SOL OUTPUT--]] 

				if sep then
					local value_type = parse_type(scope) --[[SOL OUTPUT--]] 
					local closing    = tok:consume_symbol('}') --[[SOL OUTPUT--]] 

					if not (key_type and sep and value_type and closing) then
						report_error("Expected map type on the form: {key_type => value_type}") --[[SOL OUTPUT--]] 
						return T.Any --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					return {
						tag        = 'map',
						key_type   = key_type,
						value_type = value_type
					} --[[SOL OUTPUT--]] 
				else
					local closing = tok:consume_symbol('}') --[[SOL OUTPUT--]] 

					if not (key_type and closing) then
						report_error("Expected set on the form { key_type } or a map on the form: {key_type => value_type}") --[[SOL OUTPUT--]] 
						return T.Any --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					return {
						tag        = 'map',
						key_type   = key_type,
						value_type = T.True
					} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if tok:consume_keyword('function') then
			-- function type
			if not tok:consume_symbol('(') then
				report_error("Expected (") --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local fun_t = {
				tag    = 'function',
				args   = {},
				vararg = nil,
				rets   = nil,
				name   = '<lambda>',
			} --[[SOL OUTPUT--]] 

			if not tok:consume_symbol(')') then
				while true do
					if tok:consume_symbol('...') then
						local var_arg_t = T.Any --[[SOL OUTPUT--]] 

						if tok:consume_symbol(':') then
							var_arg_t = parse_type(scope) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						fun_t.vararg = { tag = 'varargs', type = var_arg_t } --[[SOL OUTPUT--]] 

						if not tok:consume_symbol(')') then
							report_error('vararg (...) must be last argument to function') --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						break --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					local arg_name = nil --[[SOL OUTPUT--]] 
					if tok:is('ident') and tok:peek(1).data == ':' then
						-- named type
						arg_name = tok:get_ident() --[[SOL OUTPUT--]] 
						tok:get() --[[SOL OUTPUT--]]  -- Swallow ':'
					end --[[SOL OUTPUT--]] 

					local type = parse_type(scope) --[[SOL OUTPUT--]] 

					table.insert(fun_t.args, { name = arg_name, type = type }) --[[SOL OUTPUT--]] 

					if not tok:consume_symbol(',') then
						if not tok:consume_symbol(')') then
							report_error('bad function syntax') --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						break --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if tok:consume_symbol('->') then
				fun_t.rets = parse_type_list(scope) --[[SOL OUTPUT--]] 
			else
				fun_t.rets = T.Void --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return fun_t --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if tok:is('Number') then
			local str = tok:get().data --[[SOL OUTPUT--]] 
			local t = T.from_num_literal( str ) --[[SOL OUTPUT--]] 
			if t then
				return t --[[SOL OUTPUT--]] 
			else
				report_error('Failed to parse number: %q', str) --[[SOL OUTPUT--]] 
				return T.Num --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif tok:is('String') then
			return T.from_string_literal( tok:get().data ) --[[SOL OUTPUT--]] 

		-- Handle keywords explicitly:
		elseif tok:consume_keyword('nil') then
			return T.Nil --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('true') then
			return T.True --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('false') then
			return T.False --[[SOL OUTPUT--]] 

		elseif tok:is('ident') then
			local where = where_am_i() --[[SOL OUTPUT--]] 
			local name = tok:get().data --[[SOL OUTPUT--]] 

			if tok:consume_symbol('.') then
				-- namespaced type
				if not tok:is('ident') then
					report_error("Identifier expected") --[[SOL OUTPUT--]] 
					return nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local sub_name = tok:get().data --[[SOL OUTPUT--]] 

				return {
					tag         = 'identifier',
					scope       = scope,
					--var_       = var_,
					var_name    = name,
					name        = sub_name,
					first_usage = where,
				} --[[SOL OUTPUT--]] 
			else
				-- Local or global identifier
				return {
					tag         = 'identifier',
					scope       = scope,
					name        = name,
					first_usage = where,
				} --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_type = function(scope)
		local type = parse_simple_type(scope) --[[SOL OUTPUT--]] 

		if not type then return nil --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

		if tok:consume_symbol('?') then
			--type = T.variant(type, T.Nil)   -- FIXME: isa doesn't work with typedef:s before CheckType
			type = {
				tag = 'variant',
				variants = { type, T.Nil }
			} --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if tok:consume_keyword('or') then
			local rhs = parse_type(scope) --[[SOL OUTPUT--]] 
			--type = T.variant(type, rhs) -- FIXME: isa doesn't work with typedef:s before CheckType
			type = {
				tag = 'variant',
				variants = { type, rhs }
			} --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return type --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_type_list = function(scope)
		if tok:peek().data == 'void' then
			tok:get() --[[SOL OUTPUT--]] 
			return T.Void --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local list = nil --[[SOL OUTPUT--]] 
		while true do
			if tok:consume_symbol('...') then
				if false then
					local var_arg_t = T.Any --[[SOL OUTPUT--]] 

					if tok:consume_symbol(':') then
						var_arg_t = parse_type(scope) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					local type = { tag = 'varargs', type = var_arg_t } --[[SOL OUTPUT--]] 
					list = list or {} --[[SOL OUTPUT--]] 
					table.insert(list, type) --[[SOL OUTPUT--]] 
					return list --[[SOL OUTPUT--]]   -- var-args must be last
				else
					return T.AnyTypeList --[[SOL OUTPUT--]]  -- FIXME HACK
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local type = parse_type(scope) --[[SOL OUTPUT--]] 
			if not type then
				return list --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			list = list or {} --[[SOL OUTPUT--]] 
			table.insert(list, type) --[[SOL OUTPUT--]] 
			if not tok:consume_symbol(',') then
				return list --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Parses a type-list within (and including) angle brackets: <int,string>
	parse_type_args = function(scope)
		if tok:consume_symbol('<') then
			local list = parse_type_list(scope) or {} --[[SOL OUTPUT--]]   -- Empty list OK
			if not tok:consume_symbol('>') then
				report_error("Missing '>'") --[[SOL OUTPUT--]] 
				return nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return list --[[SOL OUTPUT--]] 
		else
			return nil --[[SOL OUTPUT--]]  -- No type-args here
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function parse_typedef(scope, scoping)
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

		local where = where_am_i() --[[SOL OUTPUT--]] 

		if not tok:is('ident') then
			return false, report_error("Name expected") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		local type_name = tok:get().data --[[SOL OUTPUT--]] 

		local node = { 
			ast_type  = 'Typedef',
			scope     = scope,
			type_name = type_name,
			tokens    = {},
			where     = where,
			is_local  = (scoping ~= 'global'),
		} --[[SOL OUTPUT--]] 

		if not tok:consume_symbol('.') then
			node.type_name  = type_name --[[SOL OUTPUT--]] 
		else
			if scoping == 'global' then
				return false, report_error("global typedef cannot have namespaced name") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local base_name = type_name --[[SOL OUTPUT--]] 

			type_name = tok:get_ident() --[[SOL OUTPUT--]] 
			if not type_name then
				return false, report_error("Identifier expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			node.namespace_name = base_name --[[SOL OUTPUT--]] 
			node.type_name      = type_name --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		-- Are we a forward-declare?
		if not tok:consume_symbol(';') then
			local function parse_bases()
				-- Check for inheritance
				local base_types = {} --[[SOL OUTPUT--]] 
				if tok:consume_symbol(':') then
					repeat
						local t = parse_type(scope) --[[SOL OUTPUT--]] 
						if not t then
							report_error("base type expected") --[[SOL OUTPUT--]] 
							return nil --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						table.insert(base_types, t) --[[SOL OUTPUT--]] 
					until not tok:consume_symbol(',') --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				return base_types --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local function parse_type_assignment()
				if not tok:consume_symbol('=') then
					report_error("Expected '='") --[[SOL OUTPUT--]] 
					return nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local type = parse_type(scope) --[[SOL OUTPUT--]] 

				if not type then
					report_error("Expected type") --[[SOL OUTPUT--]]  
					return nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				return type --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local base_types = parse_bases() --[[SOL OUTPUT--]] 
			if not base_types then return false, report_error("base type(s) expected") --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			node.base_types = base_types --[[SOL OUTPUT--]] 

			local type = parse_type_assignment() --[[SOL OUTPUT--]] 
			if not type then return false, report_error("type assignment expected") --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			node.type = type --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return true, node --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_expr = function(scope)
		local st,expr = parse_sub_expr(scope, 0) --[[SOL OUTPUT--]] 
		if not st then return false, expr --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

		if tok:consume_symbol(':') or tok:consume_symbol('!') then
			-- A cast

			local where = where_am_i() --[[SOL OUTPUT--]] 

			local type = parse_type(scope) --[[SOL OUTPUT--]] 
			if not type then
				return false, report_error("Bad cast, expected  'expr : type'") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return true, {
				ast_type = 'CastExpr',
				where    = where,
				tokens   = {},
				expr     = expr,
				type     = type,
			} --[[SOL OUTPUT--]] 
		else
			return true, expr --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function parse_function_decl(scope, token_list,
		                                scoping)

		if not tok:is('ident') then
			return false, report_error("Function name expected") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local name_expr = parse_id_expr() --[[SOL OUTPUT--]] 
		local st, func = parse_function_args_and_body(scope, token_list) --[[SOL OUTPUT--]] 
		if not st then return false, func --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

		func.ast_type     = 'FunctionDeclStatement' --[[SOL OUTPUT--]] 
		func.name_expr    = name_expr --[[SOL OUTPUT--]] 
		func.is_aggregate = false --[[SOL OUTPUT--]] 
		func.is_local     = (scoping == 'local') --[[SOL OUTPUT--]] 
		func.scoping      = scoping --[[SOL OUTPUT--]] 
		return true, func --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function parse_declaration(scope, token_list,
		                              scoping)

		local is_local = (scoping ~= 'global') --[[SOL OUTPUT--]] 

		local where = where_am_i() --[[SOL OUTPUT--]] 
		local types = nil --[[SOL OUTPUT--]] 

		if scoping == 'var' then
			types = parse_type_args(scope) --[[SOL OUTPUT--]] 
		elseif parse_type_args(scope) then
			return false, report_error("%s cannot have type list - did you want 'var' ?") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if types and #types == 0 then
			return false, report_error("Empty type list") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if not tok:is('ident') then
			return false, report_error("Variable name expected") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local name_list = { tok:get(token_list).data } --[[SOL OUTPUT--]] 
		while tok:consume_symbol(',', token_list) do
			if not tok:is('ident') then
				return false, report_error("local variable name expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			name_list[#name_list+1] = tok:get(token_list).data --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local init_list = {} --[[SOL OUTPUT--]] 
		if tok:consume_symbol('=', token_list) then
			repeat
				local st, ex = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				init_list[#init_list+1] = ex --[[SOL OUTPUT--]] 
			until not tok:consume_symbol(',', token_list) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local node_local = {
			ast_type  = 'VarDeclareStatement';
			scoping   = scoping; -- 'local' or 'global' or 'var'
			is_local  = is_local;
			type_list = types;
			name_list = name_list;
			init_list = init_list;
			tokens    = token_list;
			where     = where;
		} --[[SOL OUTPUT--]] 
		--
		return true, node_local --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function parse_class(scope, token_list, scoping)
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

		local where = where_am_i() --[[SOL OUTPUT--]] 

		if not tok:is('ident') then
			return false, report_error("Name expected") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		local name = tok:get(token_list).data --[[SOL OUTPUT--]] 

		if not tok:consume_symbol('=', token_list) then
			return false, report_error("Expected '='") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local st, rhs = parse_expr(scope) --[[SOL OUTPUT--]] 
		
		if not st then return false, rhs --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

		local node = { 
			ast_type  = 'ClassDeclStatement',
			scope     = scope,
			name      = name,
			rhs       = rhs,
			tokens    = token_list,
			where     = where,
			is_local  = (scoping == 'local')
		} --[[SOL OUTPUT--]] 

		return true, node --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function parse_statement(scope)
		local            st         = true --[[SOL OUTPUT--]]  -- Success?
		local   stat       = nil --[[SOL OUTPUT--]] 
		local token_list = {} --[[SOL OUTPUT--]] 
		local            where      = where_am_i() --[[SOL OUTPUT--]] 

		if tok:consume_keyword('if', token_list) then
			--setup
			local node_if_stat = {
				ast_type = 'IfStatement'
			} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 
			local clauses 



= {} --[[SOL OUTPUT--]] 

			--clauses
			repeat
				local st, node_cond = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, node_cond --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				if not tok:consume_keyword('then', token_list) then
					return false, report_error("`then` expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local st, node_body = parse_statement_list(create_scope(scope)) --[[SOL OUTPUT--]] 
				if not st then return false, node_body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				clauses[#clauses+1] = {
					condition = node_cond;
					body      = node_body;
				} --[[SOL OUTPUT--]] 
			until not tok:consume_keyword('elseif', token_list) --[[SOL OUTPUT--]] 

			--else clause
			if tok:consume_keyword('else', token_list) then
				if tok:peek().data == 'if' and tok:peek().all_leading_white == ' ' then
					-- Warn agains C-style 'else if'
					report_error("Dangerous 'else if' here - did you mean 'elseif' ? (insert extra space to mute this error)") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local st, node_body = parse_statement_list(create_scope(scope)) --[[SOL OUTPUT--]] 
				if not st then return false, node_body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				clauses[#clauses+1] = {
					body = node_body;
				} --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			node_if_stat.clauses = clauses --[[SOL OUTPUT--]] 
			node_if_stat.tokens = token_list --[[SOL OUTPUT--]] 
			stat = node_if_stat --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('while', token_list) then
			--setup
			local node_while_stat = {} --[[SOL OUTPUT--]] 
			node_while_stat.ast_type = 'WhileStatement' --[[SOL OUTPUT--]] 

			--condition
			local st, node_cond = parse_expr(scope) --[[SOL OUTPUT--]] 
			if not st then return false, node_cond --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

			--do
			if not tok:consume_keyword('do', token_list) then
				return false, report_error("`do` expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--body
			local st, node_body = parse_statement_list(create_scope(scope)) --[[SOL OUTPUT--]] 
			if not st then return false, node_body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

			--end
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--return
			node_while_stat.condition = node_cond --[[SOL OUTPUT--]] 
			node_while_stat.body      = node_body --[[SOL OUTPUT--]] 
			node_while_stat.tokens    = token_list --[[SOL OUTPUT--]] 
			stat = node_while_stat --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('do', token_list) then
			--do block
			local st, node_block = parse_statement_list(create_scope(scope)) --[[SOL OUTPUT--]] 
			if not st then return false, node_block --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			if not tok:consume_keyword('end', token_list) then
				return false, report_error("`end` expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local node_do_stat = {} --[[SOL OUTPUT--]] 
			node_do_stat.ast_type = 'DoStatement' --[[SOL OUTPUT--]] 
			node_do_stat.body    = node_block --[[SOL OUTPUT--]] 
			node_do_stat.tokens  = token_list --[[SOL OUTPUT--]] 
			stat = node_do_stat --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('for', token_list) then
			--for block
			if not tok:is('ident') then
				return false, report_error("<ident> expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			local base_var_name = tok:get(token_list) --[[SOL OUTPUT--]] 
			if tok:consume_symbol('=', token_list) then
				--numeric for
				local for_scope = create_scope(scope) --[[SOL OUTPUT--]] 

				local st, start_ex = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, start_ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				if not tok:consume_symbol(',', token_list) then
					return false, report_error("`,` Expected") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local st, end_ex = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, end_ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

				local step_ex = nil --[[SOL OUTPUT--]] 
				if tok:consume_symbol(',', token_list) then
					st, step_ex = parse_expr(scope) --[[SOL OUTPUT--]] 
					if not st then return false, step_ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if not tok:consume_keyword('do', token_list) then
					return false, report_error("`do` expected") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local st, body = parse_statement_list(for_scope) --[[SOL OUTPUT--]] 
				if not st then return false, body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				if not tok:consume_keyword('end', token_list) then
					return false, report_error("`end` expected") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				stat = {
					ast_type = 'NumericForStatement';
					scope    = for_scope;
					var_name = base_var_name.data;
					start    = start_ex;
					end_     = end_ex;
					step     = step_ex;
					body     = body;
					tokens   = token_list;
				} --[[SOL OUTPUT--]] 

			else
				--generic for
				local for_scope = create_scope(scope) --[[SOL OUTPUT--]] 
				--
				local var_names = { base_var_name.data } --[[SOL OUTPUT--]] 
				while tok:consume_symbol(',', token_list) do
					if not tok:is('ident') then
						return false, report_error("for variable expected.") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					var_names[#var_names+1] = tok:get(token_list).data --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if not tok:consume_keyword('in', token_list) then
					return false, report_error("`in` expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local generators = {} --[[SOL OUTPUT--]] 
				local st, first_generator = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, first_generator --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				generators[#generators+1] = first_generator --[[SOL OUTPUT--]] 
				while tok:consume_symbol(',', token_list) do
					local st, gen = parse_expr(scope) --[[SOL OUTPUT--]] 
					if not st then return false, gen --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					generators[#generators+1] = gen --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if not tok:consume_keyword('do', token_list) then
					return false, report_error("`do` expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local st, body = parse_statement_list(for_scope) --[[SOL OUTPUT--]] 
				if not st then return false, body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				if not tok:consume_keyword('end', token_list) then
					return false, report_error("`end` expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				--
				stat = {
					ast_type   = 'GenericForStatement';
					scope      = for_scope;
					var_names  = var_names;
					generators = generators;
					body       = body;
					tokens     = token_list;
				} --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('repeat', token_list) then
			local st, body = parse_statement_list(create_scope(scope)) --[[SOL OUTPUT--]] 
			if not st then return false, body --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			--
			if not tok:consume_keyword('until', token_list) then
				return false, report_error("`until` expected.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			-- FIX: Used to parse in parent scope
			-- Now parses in repeat scope
			local st, cond = parse_expr(body.scope) --[[SOL OUTPUT--]] 
			if not st then return false, cond --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			--
			local node_repeat = {} --[[SOL OUTPUT--]] 
			node_repeat.ast_type  = 'RepeatStatement' --[[SOL OUTPUT--]] 
			node_repeat.condition = cond --[[SOL OUTPUT--]] 
			node_repeat.body      = body --[[SOL OUTPUT--]] 
			node_repeat.tokens    = token_list --[[SOL OUTPUT--]] 
			node_repeat.scope     = body.scope --[[SOL OUTPUT--]] 
			stat = node_repeat --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('function', token_list) then
			if not tok:is('ident') then
				return false, report_error("Function name expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			local st, name_expr = parse_suffixed_expr(scope, 'only_dot_colon') --[[SOL OUTPUT--]] 
			if not st then return false, name_expr --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			--
			local is_aggregate = (name_expr.ast_type == 'MemberExpr') --[[SOL OUTPUT--]] 
			local is_mem_fun = (name_expr.ast_type == 'MemberExpr' and name_expr.indexer == ':') --[[SOL OUTPUT--]] 
			local st, func = parse_function_args_and_body(scope, token_list, is_mem_fun and 'mem_fun' or nil) --[[SOL OUTPUT--]] 
			if not st then return false, func --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

			-- 'function foo()' is local in sol, global in lua

			func.ast_type     = 'FunctionDeclStatement' --[[SOL OUTPUT--]] 
			if not is_aggregate then
				func.is_local  = settings.sol --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			func.scoping      = '' --[[SOL OUTPUT--]] 
			func.is_aggregate = is_aggregate --[[SOL OUTPUT--]] 
			func.name_expr    = name_expr --[[SOL OUTPUT--]] 
			stat = func --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('local', token_list) then
			if tok:consume_keyword('function', token_list) then
				st, stat = parse_function_decl(scope, token_list, 'local') --[[SOL OUTPUT--]] 
			else
				st, stat = parse_declaration(scope, token_list, 'local') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif settings.is_sol and tok:consume_keyword('global', token_list) then
			if tok:consume_keyword('typedef') then
				st, stat = parse_typedef(scope, 'global') --[[SOL OUTPUT--]] 
			elseif tok:consume_keyword('class', token_list) then
				st, stat = parse_class(scope, token_list, 'global') --[[SOL OUTPUT--]] 
			elseif tok:consume_keyword('function', token_list) then
				st, stat = parse_function_decl(scope, token_list, 'global') --[[SOL OUTPUT--]] 
			else
				st, stat = parse_declaration(scope, token_list, 'global') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('var', token_list) then
			st, stat = parse_declaration(scope, token_list, 'var') --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('class', token_list) then
			st, stat = parse_class(scope, token_list, 'local') --[[SOL OUTPUT--]] 

		elseif tok:consume_symbol('::', token_list) then
			if not tok:is('ident') then
				return false, report_error('label name expected') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			local label = tok:get(token_list).data --[[SOL OUTPUT--]] 
			if not tok:consume_symbol('::', token_list) then
				return false, report_error("`::` expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			local node_label = {} --[[SOL OUTPUT--]] 
			node_label.ast_type = 'LabelStatement' --[[SOL OUTPUT--]] 
			node_label.label   = label --[[SOL OUTPUT--]] 
			node_label.tokens  = token_list --[[SOL OUTPUT--]] 
			stat = node_label --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('return', token_list) then
			local ex_list = {} --[[SOL OUTPUT--]] 
			if not tok:is_keyword('end') and not tok:is_keyword('else') and not tok:is_keyword('elseif') then
				local st, first_ex = parse_expr(scope) --[[SOL OUTPUT--]] 
				if st then
					ex_list[1] = first_ex --[[SOL OUTPUT--]] 
					while tok:consume_symbol(',', token_list) do
						local st, ex = parse_expr(scope) --[[SOL OUTPUT--]] 
						if not st then return false, ex --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
						ex_list[#ex_list+1] = ex --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			stat = {
				ast_type  = 'ReturnStatement';
				arguments = ex_list;
				tokens    = token_list;
			} --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('break', token_list) then
			local node_break = {} --[[SOL OUTPUT--]] 
			node_break.ast_type = 'BreakStatement' --[[SOL OUTPUT--]] 
			node_break.tokens  = token_list --[[SOL OUTPUT--]] 
			stat = node_break --[[SOL OUTPUT--]] 

		elseif tok:consume_keyword('goto', token_list) then
			if not tok:is('ident') then
				return false, report_error("label expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			local label = tok:get(token_list).data --[[SOL OUTPUT--]] 
			stat = {
				ast_type = 'GotoStatement';
				label    = label;
				tokens   = token_list;
			} --[[SOL OUTPUT--]] 

		elseif settings.is_sol and tok:consume_keyword('typedef') then
			st,stat = parse_typedef(scope, 'local') --[[SOL OUTPUT--]] 

		else
			--statement_parse_expr
			local st, suffixed = parse_suffixed_expr(scope) --[[SOL OUTPUT--]] 
			if not st then return false, suffixed --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

			--assignment or call?
			if tok:is_symbol(',') or tok:is_symbol('=') then
				--check that it was not parenthesized, making it not an lvalue
				if (suffixed.paren_count or 0) > 0 then
					return false, report_error("Can not assign to parenthesized expression, is not an lvalue") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				--more processing needed
				local lhs = { suffixed } --[[SOL OUTPUT--]] 
				while tok:consume_symbol(',', token_list) do
					local st, lhs_part = parse_suffixed_expr(scope) --[[SOL OUTPUT--]] 
					if not st then return false, lhs_part --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					lhs[#lhs+1] = lhs_part --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				--equals
				if not tok:consume_symbol('=', token_list) then
					return false, report_error("`=` Expected.") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				--rhs
				local rhs = {} --[[SOL OUTPUT--]] 
				local st, first_rhs = parse_expr(scope) --[[SOL OUTPUT--]] 
				if not st then return false, first_rhs --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				rhs[1] = first_rhs --[[SOL OUTPUT--]] 
				while tok:consume_symbol(',', token_list) do
					local st, rhs_part = parse_expr(scope) --[[SOL OUTPUT--]] 
					if not st then return false, rhs_part --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					rhs[#rhs+1] = rhs_part --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				--done
				stat = {
					ast_type = 'AssignmentStatement';
					lhs     = lhs;
					rhs     = rhs;
					tokens  = token_list;
				} --[[SOL OUTPUT--]] 

			elseif suffixed.ast_type == 'CallExpr' or
				   suffixed.ast_type == 'TableCallExpr' or
				   suffixed.ast_type == 'StringCallExpr'
			then
				--it's a call statement
				stat = {
					ast_type   = 'CallStatement';
					expression = suffixed;
					tokens     = token_list;
				} --[[SOL OUTPUT--]] 
			else
				return false, report_error("Assignment Statement Expected") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		
		if not st then return st, stat --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

		assert(stat) --[[SOL OUTPUT--]] 

		stat.where = where --[[SOL OUTPUT--]] 

		if tok:is_symbol(';') then
			report_warning("semicolon at the end of a statement is considered bad style") --[[SOL OUTPUT--]] 
			stat.semicolon = tok:get( stat.tokens ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return true, stat --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	parse_statement_list = function(scope)
		assert(scope) --[[SOL OUTPUT--]] 
		local node = {
			ast_type = 'Statlist';
			where    = where_am_i();
			scope    = scope;
			tokens   = { };
		} --[[SOL OUTPUT--]] 

		local stats = {} --[[SOL OUTPUT--]] 

		while not stat_list_close_keywords[tok:peek().data] and not tok:is_eof() do
			local st, node_statement = parse_statement(node.scope) --[[SOL OUTPUT--]] 
			if not st then return false, node_statement --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			stats[#stats + 1] = node_statement --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if tok:is_eof() then
			local node_eof = {
				ast_type = 'Eof';
				tokens   = { tok:get() };
				where    = where_am_i();
			} --[[SOL OUTPUT--]] 
			stats[#stats + 1] = node_eof --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		node.body = stats --[[SOL OUTPUT--]] 

		return true, node --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function mainfunc()
		return parse_statement_list(module_scope) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local st, main = mainfunc() --[[SOL OUTPUT--]] 
	--print("Last Token: "..PrintTable(tok:peek()))
	if num_err == 0 then
		return st, main --[[SOL OUTPUT--]] 
	else
		return false, main --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return P --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 