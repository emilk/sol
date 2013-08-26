--[[ DO NOT MODIFY - COMPILED FROM sol/type_check.sol --]] --[[ DO NOT MODIFY - COMPILED FROM ../sol/TypeCheck.sol --]] 
--[[ DO NOT MODIFY - COMPILED FROM ../sol/TypeCheck.sol --]] 
local util   = require 'util'
local bimap = util.bimap
local Pretty = require 'pretty'
local T      = require 'type'
local L      = require 'lexer'
local P      = require 'parser'
local S      = require 'scope'
local D      = require 'sol_debug'







local NumOps = bimap{
	'+', '-', '*', '/', '%', '^'
}
local NumCompOps = bimap{
	'<', '<=', '>', '>='
}


local function expr2str(e) 
	local ignore_set = util.bimap{'var_', 'scope', 'Scope', 'Tokens'}
	return Pretty.serialize(e, ignore_set)
end


local function format_expr(e)
	local FormatIdentity = require 'format_identity'
	local insert_new_lines = false
	local str = FormatIdentity(e, '', insert_new_lines)
	str = util.trim(str)
	return str
end





local function Analyze(ast, filename, on_require, settings)
	local analyze_statlist, analyze_expr, analyze_expr_single;
	local analyze_expr_unchecked;

	local error_count = 0

	local function where_is(node)
		if node and node.where then
			return node.where
		elseif node and node.Tokens and node.Tokens[1] then
			local tok = node.Tokens[1]
			return string.format('%s:%i', filename, tok.Line)
		else
			D.break_()
			return filename .. ':??'
		end
	end


	local function report(type, node, fmt, ...)
		local inner_msg = string.format(fmt, ...)
		local msg = string.format('%s: %s: %s', type, where_is(node), inner_msg)
		return msg
	end

	local function report_spam(node, fmt, ...)
		if _G.g_spam then
			print( report('Spam', node, fmt, ...) )
		end
	end

	local function report_info(node, fmt, ...)
		print( report('Info', node, fmt, ...) )
	end

	local function report_warning(node, fmt, ...)
		print( report('WARNING', node, fmt, ...) )
	end

	local function sol_warning(node, fmt, ...)
		if settings.Sol then
			report_warning(node, fmt, ...)
		end
	end

	local function report_error(node, fmt, ...)
		if settings.Sol then
			util.printf_err( "%s", report('ERROR', node, fmt, ...) )
			error_count = error_count + 1
		else
			-- Forgive lua code
			print( report('WARNING', node, fmt, ...) )
		end
	end

	--[[
	-- Will lookup typedefs in scope variables
	local function reduce_type(node, scope, t)
		if t then
			if t.tag == 'identifier' then
				if not t.type then
					if not t.var_.Namespace then
						report_error(t, scope)
					t.type = var_.Namespace
				end
			elseif t.tag == 'variant' then
				for i,v in ipairs(t.variants) do
					t.variants[i] = reduce_type(node, scope, v)
				end
			elseif t.tag == 'list' then
				t.type = reduce_type(t.type, scope)
			elseif t.tag == 'map' then
				t.key_type = reduce_type(node, scope, t.key_type)
				t.value_type = reduce_type(t.value_type, scope)
			elseif t.tag == 'object' then
				for i,v in ipairs(t.members) do
					t.members[i] = reduce_type(node, scope, v)
				end
			end
		end

		return t
	end
	--]]




	local function DeclareLocal(node, scope, name)
		D.assert(node and scope and name)
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		local old = scope:GetScoped(name)

		if old and old.ForwardDeclared then
			old.ForwardDeclared = false -- Properly declared now
			-- TODO: move to proper scope!
			assert(not old.IsGlobal)
			assert(old.Scope == scope)
			old.where = where_is(node) -- Update position of forward-declare
			return old
		end

		if old then
			if name ~= "st" and name ~= "_" then  -- HACK
				report_error(node, "'%s' already declared in this scope, at %s", name, old.where)
			end
			return old
		end

		return scope:CreateLocal(name, where_is(node))
	end

	local function DeclareGlobal(node, scope, name)
		D.assert(node and scope and scope.Parent)
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		if name ~= '_' then
			if not scope:is_module_level() then
				report_error(node, "Global variables should be declared in the top scope")
			end
		end

		local old = scope:GetVar(name)

		if old and old.ForwardDeclared then
			old.ForwardDeclared = false -- Properly declared now
			-- TODO: move to proper scope!
			assert(old.IsGlobal)
			assert(old.Scope == scope)
			old.where = where_is(node) -- Update position of forward-declare
			return old
		end

		if old then
			report_error(node, "'%s' already declared at %s", name, old.where)
			return old
		end

		return scope:CreateGlobal(name, where_is(node))
	end

	local function DeclareVar(node, scope, name, is_local)
		if is_local then
			return DeclareLocal(node, scope, name)
		else
			return DeclareGlobal(node, scope, name)
		end
	end


	local function check_type_is_a(msg, expr, expr_type, expected_type)
		if T.could_be(expr_type, expected_type) then
			return true
		else
			report_error(expr, "%s: Expected type '%s', got '%s'", msg, T.name(expected_type), T.name(expr_type))
			return false
		end
	end

	analyze_expr = function(expr, scope)
		local type, var_

		if true then
			type, var_ = analyze_expr_unchecked(expr, scope)
		else
			-- catches 'error':s in e.g. Type
			local st
			st, type, var_ = pcall( analyze_expr_unchecked, expr, scope )
			if not st then
				local err_msg = string.sub(type, 256) -- Limit msg length
				report_error(expr, "Error type-checking expression of type '%s': %s", expr.AstType, err_msg)

				-- Show stack-trace:
				analyze_expr_unchecked(expr, scope)
			end
		end

		D.assert(T.is_type(type)  or  T.is_type_list(type))

		if not T.is_type(type) and not T.is_type_list(type) then
			report_error(expr, "Expression of type %s: evaluated to non-type: '%s'", expr.AstType, util.Pretty(type))
			type = T.AnyTypeList -- Could be any number of unknown values
		end

		--report_spam(expr, 'Expression of type %s evaluated to %s', expr.AstType, T.name(type))

		return type, var_
	end

	-- Will make sure to return a single type, never void or multiple returns
	analyze_expr_single = function(expr, scope)
		local t,v = analyze_expr(expr, scope)
		if t == T.AnyTypeList then
			return T.Any, v
		end

		if T.is_type_list(t) then
			if #t == 0 then
				report_error(expr, "Analyzing '%'s expression: Expected type, got void")
				return T.Any, v
			elseif #t == 1 then
				return t[1], v
			else
				report_error(expr, "Expected single type, got: '%s' when analyzing '%s' expression", T.name(t), expr.AstType)
				return T.Any, v
			end
		else
			return t, v
		end
	end


	local function check_return_types(node, does_return, should_return)
		if should_return then
			assert(T.is_type_list(does_return))
			assert(T.is_type_list(should_return))

			if not T.could_be_tl(does_return, should_return) then
				local problem_rope = {}
				T.could_be_tl(does_return, should_return, problem_rope)
				local problem_str = table.concat(problem_rope, '\n')
				report_warning(node, "Return statement does not match function return type declaration, returns: '%s', expected: '%s'. %s", T.name(does_return), T.name(should_return), problem_str)
			end
		end
	end


	local function analyze_expr_single_custom(expr, scope, is_pre_analyze)
		if not is_pre_analyze then
			return analyze_expr_single(expr, scope)
		end

		if expr.AstType == 'IdExpr' then
			local base_var = scope:GetVar( expr.Name )

			if base_var then
				return base_var.Type or T.Any, base_var
			else
				report_error(expr, "Unknown identifier '%s'", expr.Name)
				return T.Any, nil
			end

		else
			return T.Any, nil
		end
	end

	 
	-- analyze a function declaration head - either a named one or a lambda function
	local analyze_function_head = function(node, scope, is_pre_analyze)
		assert(node.ReturnTypes == nil or T.is_type_list(node.ReturnTypes))

		local fun_t = {
			tag = "function",
			args = {},
			rets = node.ReturnTypes  -- If any
		}

		if node.IsMemFun then
			local name = node.Name
			assert(name.AstType == 'MemberExpr' and name.Indexer == ':')
			local self_type = analyze_expr_single_custom(name.Base, scope, is_pre_analyze)
			table.insert(fun_t.args, {name = 'self', type = self_type})

			node.SelfVarType = self_type  -- Assign a type to the local 'self' variable

			if _G.g_spam then
				report_spam(node, "self: '%s'", T.name(self_type))
			end
		end

		for i,arg in ipairs(node.Arguments) do
			table.insert(fun_t.args, {name = arg.name, type = arg.type or T.Any})
		end

		if node.VarArg then
			fun_t.vararg = node.VarArg
		end


		if _G.g_spam then
			report_spam(node, "analyze_function_head: '%s'", T.name(fun_t))
		end

		return fun_t
	end

	--[[ Will analyze body and check its return-statements against fun_t.
	     If fun_t.rets is nil (no type deduced) then this function will fill it in via deduction.
	--]]
	local function analyze_function_body(node, fun_t)
		local func_scope = node.Scope

		-- Declare arguments as variables:
		if node.IsMemFun then
			assert(node.SelfVarType) -- Set by analyze_function_head
			local v = DeclareLocal(node, func_scope, 'self')
			v.Type = node.SelfVarType
		end

		for _,arg in ipairs(node.Arguments) do
			local v = DeclareLocal(node, func_scope, arg.name)
			v.Type = arg.type
		end

		if node.VarArg then
			local v = DeclareLocal(node, func_scope, '...')
			v.Type = node.VarArg
			assert(T.is_type(v.Type))
		end

		---

		local ret_t = analyze_statlist(node.Body, func_scope, fun_t)
		ret_t = ret_t and T.as_type_list(ret_t) or T.Void

		if fun_t.rets then
			if not T.could_be_tl(ret_t, fun_t.rets) then
				report_error(node, "Return statement(s) does not match function return type declaration, returns: '%s', expected: '%s'",
					T.name(ret_t), T.name(fun_t.rets))
			end
		else
			-- Deduce return type:
			if ret_t then
				fun_t.rets = ret_t
			else
				fun_t.rets = T.Void  -- No returns  == void
			end
			--report_spam(node, 'function deduced return type: %s', T.name(fun_t.rets))
		end
	end


	local function do_indexing(node, type, name)
		type = T.follow_identifiers(type)

		if type.tag == 'variant' then
			local indexed_type = nil

			for _,v in pairs(type.variants) do
				indexed_type = T.variant(indexed_type, do_indexing(node, v, name))
			end

			return indexed_type
		elseif type.tag == 'object' then
			local obj = type
			local indexed_type = obj.members[name]

			indexed_type = T.broaden( indexed_type ) -- Previous value may have been 'false' - we should allow 'true' now:

			if obj.derived then
				for _,v in ipairs(obj.derived) do
					indexed_type = T.variant(indexed_type, do_indexing(node, v, name))
				end
			end

			return indexed_type
		elseif T.isa(type, T.String) then
			-- TODO:  'example':upper()
			return T.Any
		elseif T.is_any(type) then
			return T.Any
		else
			return nil
		end
	end


	local function generator_types(expr, fun_t, arg_ts)
		--------------------------------------------------------
		-- SPECIAL: 'pairs':
		if fun_t.name == 'pairs' then
			if #arg_ts ~= 1 then
				report_error(expr, "Too many arguments to 'pairs'")
			else
				local function pairs_type(typ, error_rope)
					typ = T.follow_identifiers(typ)

					if typ == T.Any then
						return { T.Any, T.Any }
					elseif typ.tag == 'object' then
						return { T.String, T.Any }
					elseif typ.tag == 'map' then
						assert( typ.key_type )
						assert( typ.value_type )
						return { typ.key_type, typ.value_type }
					elseif typ.tag == 'list' then
						--report_warning(expr, "Calling 'pairs' on a list - did you mean to use 'ipairs'?")
						report_error(expr, "Calling 'pairs' on a list - did you mean to use 'ipairs'?")
						assert( typ.type )
						return { T.Uint, typ.type }
					elseif typ.tag == 'variant' then
						local types = nil

						for _,v in ipairs(typ.variants) do
							types = T.combine_type_lists(types, pairs_type(v, error_rope))
						end

						assert(types == nil  or  #types == 2)
						return types
					else
						table.insert(error_rope, string.format("Incompatible type: '%s'", T.name(typ)))
						return nil
					end
				end

				local error_rope = {}
				local types = pairs_type( arg_ts[1], error_rope )
				if types then
					assert(#types == 2)
					return types
				else
					report_error(expr, "'ipairs' called on incompatible type: " .. table.concat(error_rope, '\n'))
					return { T.Any, T.Any }
				end
			end
		end


		--------------------------------------------------------
		-- SPECIAL: 'ipairs':
		if fun_t.name == 'ipairs' then
			if #arg_ts ~= 1 then
				report_error(expr, "Too many arguments to 'ipairs'")
			else
				local function ipairs_type(typ, error_rope)
					typ = T.follow_identifiers(typ)

					if typ == T.Any then
						return {T.Uint, T.Any}
					elseif T.is_empty_table(typ) then
						report_warning(expr, "Calling 'ipairs' on unknown table")
						return {T.Uint, T.Any} -- Presumably a list?
					elseif typ.tag == 'list' then
						return {T.Uint, typ.type}
					elseif typ.tag == 'variant' then
						local types = nil

						for _,v in ipairs(typ.variants) do
							types = T.combine_type_lists(types, ipairs_type(v, error_rope))
						end

						assert(types == nil  or  #types == 2)
						return types
					else
						table.insert(error_rope, T.name(typ))
						return nil
					end
				end

				local error_rope = {}
				local types = ipairs_type( arg_ts[1], error_rope )
				if types then
					assert(#types == 2)
					return types
				else
					report_error(expr, "'ipairs' called on incompatible type: " .. table.concat(error_rope, ', '))
					return { T.Uint, T.Any }
				end
			end
		end

		--------------------------------------------------------

		return T.AnyTypeList
	end


	local function check_arguments(expr, fun_t, arg_ts)
		assert(fun_t.args)

		-- check arguments:
		local i = 1
		while true do
			report_spam(expr, "Checking argument %i", i)

			if i <= #fun_t.args then
				if fun_t.args[i].name == 'self' and i ~= 1 then
					report_error(expr, "'self' must be the first arguemnt")
				end

				local expected = fun_t.args[i].type

				if i <= #arg_ts then
					local given = arg_ts[i]

					if given.tag == 'varargs' then
						-- When calling with ..., if ... is empty we get nil:s
						given = T.variant(given.type, T.Nil)
					end

					if _G.g_spam then
						report_spam(expr, "Checking argument %i: can we convert from '%s' to '%s'?", i, T.name(given), T.name(expected))
					end

					if T.is_variant(given) then
						-- ensure  string?  ->  int?   does NOT pass
						given = T.variant_remove(given, T.Nil)
					end

					--report_info(expr, "Checking argument %i: could %s be %s ?", i, T.name(arg_ts[i]), T.name(expected))
					
					if not T.could_be(given, expected) then
						local problem_rope = {}
						T.could_be(given, expected, problem_rope)
						local err_msg = table.concat(problem_rope, '\n')
						report_error(expr, "Argument %i: could not convert from '%s' to '%s': %s", i, T.name_verbose(given), T.name_verbose(expected), err_msg)
					end
				else
					if i == 1 and fun_t.args[i].name == 'self' then
						report_error(expr, "Missing object argument ('self'). Did you forget to call with : ?")
					elseif not T.is_nilable(expected) then
						report_error(expr, "Missing non-nilable argument %i: expected '%s'", i, T.name(expected))
					elseif _G.g_spam then
						report_spam(expr, "Ignoring missing argument %i: it's nilable: '%s'", i, T.name(expected))
					end
				end
			elseif i <= #arg_ts then
				if fun_t.vararg then
					local given    = arg_ts[i]
					local expected = fun_t.vararg

					assert(expected.tag == 'varargs')
					expected = expected.type

					assert(T.is_type(given))
					assert(T.is_type(expected))

					if _G.g_spam then
						report_spam(expr, "Check varargs. Given: '%s', expected '%s'", T.name(given), T.name(expected))
					end

					if given.tag == 'varargs' then
						given = given.type
					end

					if not T.could_be(given, expected) then
						report_error(expr, "Argument %i: could not convert from '%s' to '%s' (varargs)", i, T.name(given), T.name(expected))
					end
				else
					report_error(expr, "Too many arguments to function, expected %s", #fun_t.args)
				end
			else
				break
			end

			i = i + 1
		end
	end


	local function analyze_require( module_name, req_where )
		return T.as_type_list( on_require( module_name, req_where ) )
	end


	local function analyze_fun_call(expr, typ, arg_ts, report_errors)
		if _G.g_spam then
			report_spam(expr, "analyze_fun_call, typ: '%s'", T.name(typ))
			report_spam(expr, "analyze_fun_call, arg_ts: '%s'", T.name(arg_ts))
		end

		typ = T.follow_identifiers(typ)

		--[[
		-- TODO
		while T.isa(fun_t, T.Table) do
			fun_t = fun_t.members[ '__call' ]
		end
		--]]

		if T.is_any(typ) then
			return T.AnyTypeList
		end

		if typ.tag == 'variant' then
			local ret = nil

			for _,v in ipairs(typ.variants) do
				ret = T.combine_type_lists(ret, analyze_fun_call(expr, v, arg_ts, report_errors))
			end

			D.assert( T.is_type_list(ret) )
			return ret
		end

		if typ.tag ~= 'function' then
			if report_errors then
				report_error(expr, "Not a function: '%s'", T.name(typ))
			end
			return nil
		end

		local fun_t = typ

		--------------------------------------------------------
		-- Check special functions:

		if fun_t.name == 'require' then
			if #arg_ts == 1 and arg_ts[1].tag == 'string_literal' then
				--util.printf('"require" called with argument: %q', arg_ts[1])
				if on_require then
					return analyze_require( arg_ts[1].value, where_is(expr) )
				end
			else
				report_warning(expr, '"require" called with indeducible argument')
			end
		end

		if fun_t.name == 'pairs' or fun_t.name == 'ipairs' then
			-- Generators returns function that returns 'it_types':
			local it_types = generator_types(expr, fun_t, arg_ts)

			if it_types ~= T.AnyTypeList then
				--report_info(expr, "Generator recognized: %s", T.name(it_types))
			end

			--var<T.Function> ret = {  -- FIXME
			local ret = {
				tag    = 'function',
				args   = {},
				vararg = T.Any,
				rets   = it_types,
			}
			return { ret }
		end

		--------------------------------------------------------

		check_arguments(expr, fun_t, arg_ts)

		--------------------------------------------------------
		-- Return types

		if fun_t.rets then
			D.assert( T.is_type_list(fun_t.rets) )
			return fun_t.rets
		else
			return T.AnyTypeList
		end
	end



	-- Returns a list of types
	local function call_function(expr, scope)
		--------------------------------------------------------
		-- Pick out function type:
		report_spam(expr, "Analyzing function base...")
		local fun_type = analyze_expr_single(expr.Base, scope)
		report_spam(expr, "Done")

		--------------------------------------------------------
		-- Get argument types (they will be evaluated regardless of function type):

		local args = util.shallow_clone( expr.Arguments )

		local called_as_mem_fun = (expr.Base.AstType == 'MemberExpr' and expr.Base.Indexer == ':')

		if called_as_mem_fun then
			local obj_expr = expr.Base.Base
			table.insert(args, 1, obj_expr)
		end

		local arg_ts = {}
		for i,v in ipairs(args) do
			if _G.g_spam then
				--util.printf('Analyzing function argument %q', expr2str(v))
			end
			arg_ts[i], _ = analyze_expr_single(v, scope)
			assert(arg_ts[i], "missing type")
		end


		--------------------------------------------------------
		-- Do we know the function type?

		local function try_call(typ, report_errors)
			typ = T.follow_identifiers(typ)

			if T.is_any(typ) then
				if _G.g_spam then
					report_spam(expr, "Function call cannot be deduced - calling something of unknown type: '%s'", T.name(fun_type))
				end

				return T.AnyTypeList
			elseif typ.tag == 'function' then
				local fun_t = typ
				local is_mem_fun = (#fun_t.args > 0 and fun_t.args[1].name == 'self')

				if called_as_mem_fun and not is_mem_fun then
					report_error(expr, "Calling non-member function as member function")
				end

				if not called_as_mem_fun and is_mem_fun then
					report_warning(expr, "Member function called as non-member function")
					--report_info(expr, "expr.Base.AstType: " .. expr.Base.AstType)
					--report_info(expr, "expr.Base.Indexer: " .. expr2str(expr.Base.Indexer))
				end

				local rets = analyze_fun_call(expr, fun_t, arg_ts, report_errors)
				D.assert( rets==nil or T.is_type_list(rets) )
				return rets
			elseif typ.tag == 'variant' then
				local rets = nil
				for _,v in ipairs(typ.variants) do
					local list = try_call(v, report_errors)
					rets = T.combine_type_lists(rets, list)
				end
				D.assert( T.is_type_list(rets) )
				return rets
			elseif report_errors then
				report_error(expr, "Cannot call '%s'", T.name(typ))
				return nil
			else
				return nil
			end
		end

		local rets = try_call(fun_type, false)

		if rets then
			if _G.g_spam then
				report_spam(expr, "Function deduced to: '%s'", T.name(rets))
			end
			D.assert( T.is_type_list(rets) )
			return rets
		else
			-- Show errors:
			report_error(expr, "Cannot call '%s'", T.name(fun_type))
			try_call(fun_type, true)
			return T.AnyTypeList
		end
	end



	-- for k,v in some_expr
	-- this functions returns a list of types for k,v in the example above
	local function extract_iterator_type(expr, scope)
		report_spam(expr, "extract_iterator_type...")

		local gen_t = analyze_expr_single(expr, scope)

		if _G.g_spam then
			report_spam(expr, "extract_iterator_type, gen_t: '%s'", T.name(gen_t))
		end

		gen_t = T.follow_identifiers(gen_t)
		if gen_t == T.Any then
			return T.AnyTypeList
		end

		if gen_t.tag ~= 'function' then
			local suggestion = 'pairs'
			if T.isa(gen_t, T.List) then
				suggestion = 'ipairs'
			end

			report_error(expr, "Generator function expected, got '%s' - did you forget to use '%s'?", T.name(gen_t), suggestion)

			return T.AnyTypeList
		end

		local fun = gen_t
		--report_info(expr, "Generator deducted to %s", T.name(fun.rets))
		return fun.rets
	end



	local analyze_simple_expr_unchecked;


	analyze_expr_unchecked = function(expr, scope)
		assert(expr)
		assert(type(expr) == 'table')
		if not expr.AstType then
			error("Not an expression: " .. expr2str(expr))
		end
		assert(expr.AstType)

		report_spam(expr, "analyze_expr %s", expr.AstType)


		local function handle_var(var_)
			local type = var_.Type or T.Any
			if var_.Namespace then
				var_.Type = var_.Type or T.Object
				type = var_.Type

				if type.tag == 'object' then
					if type.Namespace then
						assert(type.Namespace == var_.Namespace)
					else
						type = util.shallow_clone(type)
						type.Namespace = var_.Namespace
						var_.Type = type
					end
				else
					report_error(expr, "Variable '%s' used as namespace but is not an object (it's '%s')", var_.Name, T.name(type))
					var_.Namespace = nil -- Only warn once
				end
			end
			
			if _G.g_spam then
				report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.AstType, T.name(type))
			end

			D.assert(T.is_type(type)  or  T.is_type_list(type))

			return type, var_
		end

		if expr.AstType == 'IdExpr' then
			if expr.Name == '_' then
				report_error(expr, "You may not read from discard variable '_'")
			end

			local var_ = scope:GetVar( expr.Name )

			if var_ then
				if var_.ForwardDeclared then
					report_error(expr, "Use of forward-declared variable '%s', forward-declared here: %s",
						expr.Name, var_.where)
				end

				var_.References = var_.References + 1
			else
				if expr.Name ~= '_' then  -- Implicit '_' var is OK
					report_error(expr, "Implicit global %q", expr.Name)
				end
				var_ = scope:CreateGlobal( expr.Name, where_is(expr) )
			end

			if _G.g_spam then
				report_spam(expr, "IdExpr '%s': var_.Type: '%s'", var_.Name, T.name(var_.Type))
			end

			return handle_var(var_)


		elseif expr.AstType == 'VarExpr' then
			local var_ = expr.Variable

			if var_.Name == '_' then
				report_error(expr, "You may not read from discard variable '_'")
			end

			if _G.g_spam then
				report_spam(expr, "VarExpr '%s': var_.Type: '%s'", var_.Name, T.name(var_.Type))
			end

			return handle_var(var_)
		else
			local type = analyze_simple_expr_unchecked(expr, scope)

			if _G.g_spam then
				report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.AstType, T.name(type))
			end

			D.assert(T.is_type(type)  or  T.is_type_list(type))

			return type, nil
		end
	end

	-- Return Type
	analyze_simple_expr_unchecked = function(expr, scope)
		if expr.AstType == 'NumberExpr' then
			-- TODO: 0xff, 42 is int,  42.0 is num
			local str = expr.Value.Data
			local t = T.from_num_literal( str )
			if t then return t end
			if not t then
				report_error(expr, 'Failed to parse number: %q', str)
				return T.Num
			end


		elseif expr.AstType == 'StringExpr' then
			return T.from_string_literal( expr.Value.Data )


		elseif expr.AstType == 'BooleanExpr' then
			assert(expr.Value == true or expr.Value == false)
			if expr.Value == true then
				return T.True
			else
				return T.False
			end


		elseif expr.AstType == 'NilExpr' then
			return T.Nil


		elseif expr.AstType == 'BinopExpr' then
			local op = expr.Op
			local lt = analyze_expr_single( expr.Lhs, scope )
			local rt = analyze_expr_single( expr.Rhs, scope )

			--report_spam(expr, "Binop: %s %s %s", T.name(lt), op, T.name(rt))

			if NumOps[op] then
				if T.could_be(lt, T.Num) and T.could_be(rt, T.Num) then
					return T.combine( lt, rt )  -- int,int -> int,   int,num -> num,  etc
				else
					report_error(expr,
						"Invalid types for operator %q: %s and %s", op, T.name(lt), T.name(rt))
					return T.Num -- Good guess
				end

			elseif NumCompOps[op] then
				if T.could_be(lt, T.Num) and T.could_be(rt, T.Num) then
					return T.Bool
				elseif T.could_be(lt, T.String) and T.could_be(rt, T.String) then
					-- String comparisons OK
					return T.Bool
				else
					report_error(expr,
						"Invalid types for operator %q: %s and %s", op, T.name(lt), T.name(rt))
					return T.Num -- Good guess
				end

			elseif op == '..' then
				if T.could_be(lt, T.String) or T.could_be(rt, T.String) then
					-- TODO: overloaded '..'
					return T.String
				else
					report_error(expr,
						"Cannot concatenate %s with %s", T.name(lt), T.name(rt))
					return T.String -- Good guess
				end

			elseif op == '==' or op== '~=' then
				lt = T.simplify(lt)
				rt = T.simplify(rt)

				if T.is_variant(lt) and T.is_variant(rt) then
					-- ensure  string? == int?   does NOT pass:
					lt = T.variant_remove(lt, T.Nil)
					rt = T.variant_remove(rt, T.Nil)
				end

				-- Make sure we aren't comparing string to int:s:
				if (not T.could_be(lt, rt)) and (not T.could_be(rt, lt)) then
					-- Apples and oranges
					report_error(expr, "Comparing incompatible types: '%s' and '%s'", T.name(lt), T.name(rt))
				end
				return T.Bool

			--[[
				In a boolean expression we want boolean expressions on both side of these op:s.
				However, since we lack a trinary operator in Lua, we often have code like:
				A and B or C
				Here, we want A to be a boolean expression, but we do NOT want B or C to be it
				in particular we do not want B or C to be false

				TODO: check for trinary operator emulation   A and B or C
			--]]
			elseif op == 'and' then
				if not T.is_useful_boolean(lt) then
					report_warning(expr,
						--"Operator 'and' expected boolean expression to the left, got %s from expression %s", T.name(lt), expr2str(expr.Lhs))
						"Operator 'and' expected boolean expression to the left, got '%s'", T.name(lt))
				end

				-- Iff left is false, then left, else right
				-- The left argument is returned iff it is evaluated to 'false' or 'nil'
				-- So we could return 'nil' (iff lt is nil:able), 'false' (iff lt is false:able) or right
				local types = rt
				
				if T.could_be(lt, T.False) then
					types = T.variant(types, T.False)
				end
				
				if T.could_be(lt, T.Nil) then
					types = T.variant(types, T.Nil)
				end

				return types

			elseif op == 'or' then
				if not T.is_useful_boolean(lt) then
					report_warning(expr,
						--"Operator 'or' expected boolean expression to the left, got %s from expression %s", T.name(lt), expr2str(expr.Lhs))
						"Operator 'or' expected boolean expression to the left, got '%s'", T.name(lt))
				end

				-- If first argument is true, then the left is returned, else the right
				-- So we could return the right type or
				-- or we could return the left type, but only cases where the left type is NOT nil or false

				--return T.variant( lt, rt )
				local types = T.make_variant( lt )  -- Anything on the left...
				if not T.is_any(types) then
					report_spam(expr, "Binop: removing Nil and False from 'or'")
					types = T.variant_remove(types, T.Nil)      -- ...except nil...
					types = T.variant_remove(types, T.False)    -- ...except false...
				end
				types = T.variant(types, rt)         -- ...or anything on the right
				return types
			else
				report_error(expr, "Unknown binary operator %q", expr.Op)
				return T.Any
			end


		elseif expr.AstType == 'UnopExpr' then
			local arg_t = analyze_expr_single(expr.Rhs, scope)

			if expr.Op == '-' then
				if T.isa(arg_t, T.Num) then
					return arg_t
				else
					report_error(expr, "Unary minus expected numeric argument, got %s", T.name(arg_t))
					return T.Num -- Good guess
				end

			elseif expr.Op == 'not' then
				if not T.is_useful_boolean(arg_t) then
					report_warning(expr, "'not' operator expected boolean or nil:able, got '%s'", T.name(arg_t))
				end
				return T.Bool

			elseif expr.Op == '#' then
				if not T.could_be(arg_t, T.List) and not T.could_be(arg_t, T.String) then
					report_error(expr, "'#' operator expected list or string, got %s", T.name(arg_t))
				end
				return T.Uint

			else
				report_error(expr, 'Unknown operator %q', expr.Op)
				return T.Any
			end


		elseif expr.AstType == 'DotsExpr' then
			local t = scope:GetVarArgs()
			if t then
				assert(t.tag == 'varargs')
				return t
			else
				report_error(expr, "No ... in scope")
				return {
					tag  = 'varargs',
					type = T.Any 
				}
			end


		elseif expr.AstType == 'CallExpr' then        -- foo(arg, ...)
			--util.printf('CallExpr, base: %q, args: %q', expr2str(expr.Base), expr2str(expr.Arguments))
			return call_function(expr, scope)


		elseif expr.AstType == 'TableCallExpr' then   -- foo{arg}
			--util.printf('TableCallExpr, base: %q, args: %q', expr2str(expr.Base), expr2str(expr.Arguments))
			return call_function(expr, scope)


		elseif expr.AstType == 'StringCallExpr' then  -- foo'arg'
			--util.printf('StringCallExpr, base: %q, args: %q', expr2str(expr.Base), expr2str(expr.Arguments))
			return call_function(expr, scope)


		elseif expr.AstType == 'IndexExpr' then
			-- Base[Index]
			local base_t  = analyze_expr_single(expr.Base, scope)
			local index_t = analyze_expr_single(expr.Index, scope)

			if T.is_any(base_t) then
				return T.Any
			end

			if T.is_empty_table(base_t) then
				-- Indexing what? We don't know
				report_warning(expr, 'Indexing unkown table')
				return T.Any
			else
				local list = T.find(base_t, T.List) -- TODO: find all lists and variant the reuslts
				if list then
					check_type_is_a("List index", expr.Index, index_t, T.Uint)
					if list.type then
						return list.type
					else
						return T.Any -- FIXME
					end
				end

				local map = T.find(base_t, T.Map) -- TODO: find all maps and variant the reuslts
				if map then
					check_type_is_a("Map index", expr.Index, index_t, map.key_type)
					return T.variant(map.value_type, T.Nil)  -- Nil on not found
				else
					report_error(expr, 'Cannot index type %s with %s - not a list, table or map', T.name(base_t), T.name(index_t))
					--error("FATAL")
					return T.Any
				end
			end


		elseif expr.AstType == 'MemberExpr' then
			-- .  or  :
			local base_t = analyze_expr_single(expr.Base, scope)
			local name = expr.Ident.Data

			if T.is_any(base_t) then
				return T.Any
			else
				local t = do_indexing(expr, base_t, name)
				if t then
					return t
				else
					--report_warning(expr, "Failed to find member '%s'", name) -- TODO
					return T.Any
				end
			end


		elseif expr.AstType == 'LambdaFunction' then
			-- Lambda function
			local is_pre_analyze = false
			local fun_t = analyze_function_head( expr, scope, is_pre_analyze )
			analyze_function_body( expr, fun_t )
			return fun_t


		elseif expr.AstType == 'ConstructorExpr' then
			-- TODO    { foo = 32, bar = 15 }
			--[[ v.EntryList contains entries on the form

				{
					Type  : 'KeyString' or 'Key' or 'Value',
					Key   : ident or expr or nil,
					Value : expr,
				}

				'Key'        means   { [expr]  =  val }    -  For maps
				'KeyString'  means   { ident   =  val }    -  For objects
				'Value'      means   { val            }    -  For lists

				Mixing is allowed in Lua, but not in Sol
			--]]
			if #expr.EntryList == 0 then
				-- {}
				--return T.EmptyTable
				-- Assume empty object?
				return { tag='object', members={} }
			else
				local key_type   = T.make_variant()  -- in maps
				local value_type = T.make_variant()
				local members = {}

				local count = { ['Key'] = 0, ['KeyString'] = 0, ['Value'] = 0 }
				for _,e in pairs(expr.EntryList) do
					count[e.Type] = count[e.Type] + 1

					local this_val_type = analyze_expr_single(e.Value, scope)
					if this_val_type.tag == 'varargs' then
						this_val_type = this_val_type.type -- Many of these
					end

					value_type = T.extend_variant( value_type, this_val_type )

					if e.Type == 'Key' then
						assert(e.Key)
						if not e.Key.AstType then
							report_error(expr, "Bad map key: %s", expr2str(e.Key))
						end
						local this_key_type = analyze_expr_single(e.Key, scope)
						key_type = T.extend_variant( key_type, this_key_type )
					end

					if e.Type == 'KeyString' then
						members[ e.Key ] = this_val_type
					end
				end

				key_type   = T.simplify( key_type )
				value_type = T.simplify( value_type )

				if count['Key'] == #expr.EntryList then
					-- A map
					return {
						tag = 'map',
						key_type = key_type,
						value_type = value_type
					}

				elseif count['Value'] == #expr.EntryList then
					-- A list
					return {
						tag  = 'list',
						type = value_type
					}

				elseif count['KeyString'] == #expr.EntryList then
					return {
						tag = 'object',
						members = members
					}

				else
					if count['Value'] == 0 then
						report_error(expr, "Mixed initialization - please use [] on everything or nothing")
					else
						report_error(expr, "Mixed initialization - all or none of the values must have explicit keys")
					end

					return T.Any
				end
			end


		elseif expr.AstType == 'Parentheses' then
			local t = analyze_expr_single( expr.Inner, scope )
			return t

		else
			print("Unknown expression AST Type: ", expr.AstType)
		end

		report_error(expr, "Failed to figure out type of %s", expr.AstType)

		return T.Any
	end


	-- eg:  check_condition(stat, 'while', some_expr, scope)
	-- examples:   if some_expr then ...
	-- examples:   while true then ...
	local check_condition = function(stat, name, expr, scope)
		if expr.AstType == 'BooleanExpr' then
			-- 'true' or 'false' as explici argument - that's OK
			-- e.g. for   while true do  ... break ... end
		else
			local t = analyze_expr_single(expr, scope)
			if not T.is_useful_boolean(t) then
				report_warning(expr, "Not a useful boolean expression in %q, type is '%s'", name, T.name(t))
			end
		end
	end


	local function declare_var(stat, var_, deduced_type)
		if not T.is_type(deduced_type) then
			report_error(stat, "declare_var: 'deduced_type' is not a type: '%s'", expr2str(deduced_type))
			assert( T.is_type(deduced_type) )
		end

		if var_.Type then
			check_type_is_a("Variable declaration", stat, deduced_type, var_.Type)
		else
			if deduced_type == T.Nil then
				--sol_warning(stat, "Initializing value with nil - type cannot be deduced")
				var_.Type  = T.Nilable
			else
				var_.Type  = T.broaden( deduced_type )
			end
		end

		var_.Namespace = deduced_type.Namespace  -- If any

		--[[
		if var_.Namespace then
			for name, type in pairs(var_.Namespace) do
				if not deduced_type.Namespace then
					report_error(stat, "Variable expected to be namespace containing type '%s', first used at %s", name, type.first_usage)
					return
				end

				if not deduced_type.Namespace[name] then
					report_error(stat, "Variable namespaced missing type '%s', first used at %s", name, type.first_usage)
					return
				end

				type.type = deduced_type.Namespace[name]
			end
		end
		--]]
	end


	local function do_assignment(stat, scope, left_expr, right_type, is_pre_analyze)
		assert(not T.is_type_list(right_type))

		if right_type.Namespace then
			report_error(stat, "Cannot assign namespace outside of declaration")
		end

		report_spam(stat, 'do_assignment, left_expr.AstType: %s', left_expr.AstType)

		if left_expr.AstType == 'MemberExpr' then
			-- foo.bar = ...
			local name = left_expr.Ident.Data

			local base_t, base_var = analyze_expr_single_custom(left_expr.Base, scope, is_pre_analyze)

			if not base_var then
			--if true then  -- TODO: always use this path
				-- e.g.:   foo.bar.baz
				report_info(stat, "do_assignment: tried to index non-variable")
				assert(base_t)
				local base_t = T.follow_identifiers(base_t)
				--assert(base_t ~= T.EmptyTable)

				if base_t.tag == 'object' then
					report_spam(stat, "Exisiting object")

					local left_type = base_t.members[name]

					if left_type and left_type.pre_analyzed then
						-- The member type was reached by the pre-analyzer - overwrite with refined info:
						assert(not right_type.pre_analyzed)
						--var_t.members[name] = nil  -- TODO: makes compilation hang!
						left_type = nil

						if _G.g_spam then
							report_spam(stat, "Replacing pre-analyzed type with refined type: '%s'", T.name(right_type))
						end
					end

					if left_type then
						report_spam(stat, "Object already has member")
						left_type = T.broaden( left_type ) -- Previous value may have been 'false' - we should allow 'true' now:

						if not T.could_be(right_type, left_type) then
							report_error(stat, "[A] Type clash: cannot assign to '%s' (type '%s') with '%s'", name, T.name(left_type), T.name(right_type))
							return false
						else
							return true
						end
					else
						-- TODO: check for similarly named member first!

						report_spam(stat, "Adding member")

						--[[
						We do not broaden the type here, to make sure the following code works:

						typedef Foo = { tag : 'foo '}

						function fun() -> Foo
							local ret = {}
							ret.tag = 'foo'  -- No broadeding! tag is 'foo', not string
							return ret
						end
						--]]
						base_t.members[name] = right_type
						return true
					end
				elseif T.is_any(base_t) then
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_spam(stat, "[A] Trying to index type 'any' with '%s'", name)
				else
					report_warning(stat, "[A] Trying to index non-object of type '%s' with '%s'", T.name(base_t), name)
				end
			else
				if not base_var.Type or T.is_empty_table(base_var.Type) then
					report_spam(stat, "New object")
					base_var.Type = { tag = 'object', members = {} }
				end

				report_spam(stat, "Assigning to %s.%s", base_var.Name, name)

				local var_t = T.follow_identifiers(base_var.Type)

				-- HACK: do more nicely:
				if var_t.tag == 'variant' then

					local obj_t = T.find(var_t, T.Object)
					if obj_t then
						var_t = T.follow_identifiers( obj_t )
					end
				end

				if var_t.tag == 'object' then
					report_spam(stat, "Exisiting object")

					local left_type = var_t.members[name]

					if left_type and left_type.pre_analyzed then
						-- The member type was reached by the pre-analyzer - overwrite with refined info:
						assert(not right_type.pre_analyzed)
						--var_t.members[name] = nil  -- TODO: makes compilation hang!
						left_type = nil

						if _G.g_spam then
							report_spam(stat, "Replacing pre-analyzed type with refined type: '%s'", T.name(right_type))
						end
					end

					if left_type then
						report_spam(stat, "Object already has member")
						left_type = T.broaden( left_type ) -- Previous value may have been 'false' - we should allow 'true' now:

						if not T.could_be(right_type, left_type) then
							report_error(stat, "[B] Type clash: cannot assign to '%s' (type '%s') with '%s'", name, T.name(left_type), T.name(right_type))
							return false
						else
							return true
						end
					else
						-- TODO: check for similarly named member first!

						report_spam(stat, "Adding member")

						--var<T.Object> obj_t = var_t
						local obj_t = util.shallow_clone( var_t )
						obj_t.members = util.shallow_clone( obj_t.members )

						--[[
						We do not broaden the type here, to make sure the following code works:

						typedef Foo = { tag : 'foo '}

						function fun() -> Foo
							local ret = {}
							ret.tag = 'foo'  -- No broadeding! tag is 'foo', not string
							return ret
						end
						--]]
						obj_t.members[name] = right_type

						base_var.Type = obj_t
						return true
					end
				elseif T.is_any(var_t) then
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_spam(stat, "[B] Trying to index type 'any' with '%s'", name)
				else
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_warning(stat, "[B] Trying to index non-object of type '%s' with '%s'", T.name(var_t), name)
				end
			end
		end

		if left_expr.AstType == 'IndexExpr' then
			-- foo[bar] = ...  -- TODO
		end

		if left_expr.AstType == 'VarExpr' and left_expr.Variable.Name == '_' then
			-- Assigning to _ is always OK
			return true
		end

		if left_expr.AstType == 'IdExpr' and left_expr.Name == '_' then
			-- Assigning to _ is always OK
			return true
		end

		local left_type = analyze_expr_single( left_expr, scope )

		if left_type.Namespace then
			report_error(stat, "Cannot assign to a namespace outside of declaration")
		end

		--if not T.isa(right_type, left_type) then
		if not T.could_be(right_type, left_type) then
			local problem_rope = {}
			T.could_be(right_type, left_type, problem_rope)
			local problem_str = table.concat(problem_rope, '\n')
			report_error(stat, "[C] Type clash: cannot assign to type '%s' with '%s': %s", T.name(left_type), T.name(right_type), problem_str)
			return false
		end
		return true
	end


	local function analyze_typedef(stat, scope)
		local name = stat.TypeName

		if stat.NamespaceName then
			--local v = stat.Variable
			local v = scope:GetVar( stat.NamespaceName )

			if not v then
				report_error(stat, "Namespaced typedef: %s is not a previously defined variable", stat.NamespaceName)
				return
			end

			v.Namespace = v.Namespace or {}
			local ns = v.Namespace
			if ns[name] then
				report_error(stat, "Type %s.%s already declared as '%s'", v.Name, name, ns[name])
			end

			if _G.g_spam then
				if stat.Type then
					report_spam(stat, "Declaring type %s.%s as '%s'", v.Name, name, T.name(stat.Type))
				else
					report_spam(stat, "Forward-declaring type %s.%s", v.Name, name)
				end
			end

			ns[name] = stat.Type
		else
			local old = scope:GetScopedType(name)
			if old then
				report_error(stat, "Type %q already declared as '%s'", name, T.name(old))
			end
			scope:DeclareType(name, stat.Type, where_is(stat))
		end

		if stat.BaseTypes and #stat.BaseTypes > 0 then
			report_spam(stat, "%s inherits %i types", name, #stat.BaseTypes)

			local child_type = T.follow_identifiers(stat.Type)

			if child_type.tag ~= 'object' then
				report_error(stat, "Only objects can have base-types (child: '%s')", T.name(child_type))
			else
				for _,base in ipairs(stat.BaseTypes) do
					report_spam(stat, "%s inheriting %s", name, base.name)

					if base.tag ~= 'identifier' then
						report_error(stat, "You can only inherit other typedef:s")
						break
					end

					local base_type = T.follow_identifiers(base)
					if base_type.tag ~= 'object' then
						--report_error(stat, "'%s' cannot inherit non-object '%s'", name, T.name(base_type))
						report_error(stat, "'%s' cannot inherit non-object '%s'", name, expr2str(base))
						break
					end

					for id,id_type in pairs(base_type.members) do
						if child_type.members[id] then
							if not T.isa(child_type.members[id], id_type) then
								report_error(stat, "Child type '%s' overrides '%s' with differing type.", name, id)
							end
						else
							-- Inherit:
							child_type.members[id] = id_type
						end
					end

					base_type.derived = base_type.derived or {}
					table.insert(base_type.derived, stat.Type)
				end
			end
		end
	end


	-- Iff it is a return statement, will returns a list of types
	-- Else nil
	-- 'scope_fun' contains info about the enclosing function
	local analyze_statement = function(stat, scope, scope_fun)
		assert(scope)
		local is_pre_analyze = false

		report_spam(stat, "analyze_statement %s", stat.AstType)

		if stat.AstType == 'AssignmentStatement' then
			local nLhs = #stat.Lhs
			local nRhs = #stat.Rhs
			assert(nRhs > 0)
			if nRhs == 1 then
				local rt = analyze_expr(stat.Rhs[1], scope)
				rt = T.as_type_list(rt)
				if rt == T.AnyTypeList then
					-- Nothing to do
				elseif nLhs > #rt then
					report_error(stat, "Unequal number of variables and values: left hand side has %i variables, right hand side evaluates to %s", nLhs, T.name(rt))
				elseif nLhs < #rt then
					report_warning(stat, "Assignment discards values: left hand side has %i variables, right hand side evaluates to %s", nLhs, T.name(rt))
				else
					for i,v in ipairs(rt) do
						do_assignment(stat, scope, stat.Lhs[i], rt[i], is_pre_analyze)
					end
				end
			else
				if #stat.Lhs ~= #stat.Rhs then
					report_error(stat, "Unequal number of variables and values")
				else
					for i = 1,nRhs do
						local rti = analyze_expr_single(stat.Rhs[i], scope)
						do_assignment(stat, scope, stat.Lhs[i], rti, is_pre_analyze)
					end
				end
			end

		elseif stat.AstType == 'CallStatement' then
			analyze_expr(stat.Expression, scope)


		elseif stat.AstType == 'VarDeclareStatement' then
			report_spam(stat, "VarDeclareStatement")

			-- Analyze InitList before declaring variables to prevent
			-- local x = x

			local init_types = {}

			if #stat.InitList == 1 then
				init_types = analyze_expr( stat.InitList[1], scope )
			else
				for _,exp in ipairs(stat.InitList) do
					init_types[#init_types + 1] = analyze_expr_single( exp, scope )
				end
			end

			local explicit_types = util.shallow_clone( stat.TypeList )

			-- Declare variables:
			local is_local = (stat.type ~= 'global')
			local vars = {}
			for _,name in ipairs(stat.NameList) do
				report_spam(stat, "Declaring var '%s'", name)
				vars[#vars + 1] = DeclareVar(stat, scope, name, is_local)
			end

			if explicit_types then
				if #explicit_types ~= 1 and #explicit_types ~= #vars then
					report_error(stat, "Uneven number of explicit types (%i) and variables (%i) in 'local' declaration. Either supply just one type, or one type per variable.", #explicit_types, #vars)
				end

				if #explicit_types == 1 and #explicit_types ~= #vars then
					-- One type to be applied to all - just duplicate: 

					explicit_types = { explicit_types[1] }

					while #explicit_types < #vars do
						table.insert(explicit_types, explicit_types[1])
					end
				end

				local N = #vars
				for i = 1,N do
					local v = vars[i]
					v.Type = explicit_types[i]
				end
			end

			if #stat.InitList == 0 then
				-- local a,b
				if stat.Type == 'var' then
					report_error(stat, "'var' must be initialized at declaration")
				elseif explicit_types then
					for _,v in ipairs(vars) do
						if not T.is_nilable(v.Type) then
							report_error(stat, "Variable '%s' of non-nilable type '%s' missing its definition",
								v.Name, T.name(v.Type))
						end
					end
				else
					for _,v in ipairs(vars) do
						if not v.Type then   -- It could have a forward-type (local foo; foo = function() ... )
							sol_warning(stat, "Un-initialized local - type cannot be deduced!")
							v.Type = T.Nilable
						end
					end
				end

			elseif #stat.InitList == 1 then
				-- local a,b = foo()
				local t = init_types
				if t == T.AnyTypeList then
					-- Nothing to do
				else
					local deduced_types = T.as_type_list( t )
					local nt = #deduced_types
					--[[
					if nt ~= #vars then
						report_error(stat, "Uneven number of variables and values in 'local' declaration. Right hand side has type %s",
							T.name(t))
					--]]
					if #vars < nt then
						-- Ignoring a few return values is OK
					elseif #vars > nt then
						report_error(stat, "Too many variables in 'local' declaration. Right hand side has type %s",
							T.name(t))
					else
						local N = #vars
						for i = 1,N do
							local v = vars[i]
							if not T.is_type(deduced_types[i]) then
								report_error(stat, "VarDeclareStatement: deduced type %i was not a type: %s", i, T.name(deduced_types[i]))
								report_error(stat, "t: %s", expr2str(t))
								D.break_()
								assert( T.is_type(deduced_types[i]) )
							end
							declare_var(stat, v, deduced_types[i])
						end
					end
				end
			elseif #vars ~= #stat.InitList then
				-- local a,b,c = 1,2
				report_error(stat, "Uneven number of variables and values in local declaration. Variables: %i, inits: %i",
					#vars, #stat.InitList)
			else
				-- local a,b,c = 1,2,3
				local N = #vars
				for i = 1,N do
					local v = vars[i]
					local deduced_type = init_types[i]
					assert( T.is_type(deduced_type) )
					declare_var(stat, v, deduced_type)
				end
			end

			if stat.Type == 'var' and not explicit_types then
				for _,v in ipairs(vars) do
					if v.Type==nil or T.is_any(v.Type) then
						report_error(stat, "Undeducible type")
					end
				end
			end


		elseif stat.AstType == 'IfStatement' then
			check_condition( stat, 'if', stat.Clauses[1].Condition, scope )

			local ret = analyze_statlist( stat.Clauses[1].Body, scope, scope_fun )

			for i = 2, #stat.Clauses do
				local st = stat.Clauses[i]
				if st.Condition then
					check_condition( stat, 'elseif', st.Condition, scope )
				end
				ret = T.combine_type_lists(ret, analyze_statlist( st.Body, scope, scope_fun ))
			end

			return ret


		elseif stat.AstType == 'WhileStatement' then
			check_condition( stat, 'while', stat.Condition, scope )
			local ret = analyze_statlist(stat.Body, scope, scope_fun)
			return ret


		elseif stat.AstType == 'DoStatement' then
			local ret = analyze_statlist(stat.Body, scope, scope_fun)
			return ret


		elseif stat.AstType == 'ReturnStatement' then
			local what_to_return = nil
			if #stat.Arguments == 0 then
				what_to_return = T.Void
			elseif #stat.Arguments == 1 then
				what_to_return = T.as_type_list( analyze_expr( stat.Arguments[1], scope ) )
			else
				local type_list = {}
				for i = 1, #stat.Arguments do
					local t = analyze_expr_single( stat.Arguments[i], scope )
					type_list[i] = t
				end
				what_to_return = type_list
			end
			--if scope_fun then
				check_return_types(stat, what_to_return, scope_fun.rets)
			--end
			return what_to_return

		elseif stat.AstType == 'BreakStatement' then
			-- TODO

		elseif stat.AstType == 'RepeatStatement' then
			local ret = analyze_statlist(stat.Body, stat.Scope, scope_fun)
			check_condition( stat, 'repeat', stat.Condition, stat.Scope )
			return ret

		elseif stat.AstType == 'FunctionDecl' then
			assert(stat.Scope.Parent == scope)
			local is_pre_analyze = false
			local fun_t = analyze_function_head( stat, scope, is_pre_analyze )

			--[[ Assign type before recursing on body.
			     This is so that recursive function can typecheck the calls to itself
			]]--
			if stat.VarName then
				--[[ e.g:
					"local function foo(bar)"
					"global function foo(bar)"
				--]]
				if _G.g_spam then
					report_spam(stat, "local function, name: %q", expr2str(stat.Name))
				end

				local v = DeclareVar(stat, scope, stat.VarName, stat.IsLocal)
				v.Type = fun_t
			else
				-- function foo:bar(arg)

				D.assert(stat.Name)
				if stat.Name.AstType ~= 'MemberExpr' then
					-- e.g.  "function foo(bar)"
					report_warning(stat, "non-local function, name: %q", expr2str(stat.Name))
				end

				do_assignment(stat, scope, stat.Name, fun_t, is_pre_analyze)
			end
			analyze_function_body( stat, fun_t )


		elseif stat.AstType == 'GenericForStatement' then
			assert(stat.Scope.Parent == scope)

			if #stat.Generators > 1 then
				report_warning(stat, "Sol currently only support one generator")
			end

			local types = extract_iterator_type( stat.Generators[1], scope )

			if types ~= T.AnyTypeList then
				if #types ~= #stat.VarNames then
					report_error(stat, "Expected %i variables", #types)
				end
			end

			for i = 1,#stat.VarNames do
				local v = DeclareLocal(stat, stat.Scope, stat.VarNames[i])
				if types ~= T.AnyTypeList then
					v.Type = types[i]
				end
			end

			local ret = analyze_statlist(stat.Body, stat.Scope, scope_fun)
			return ret


		elseif stat.AstType == 'NumericForStatement' then
			assert(stat.Scope.Parent == scope)

			local function check_num_arg(what, t)
				if not T.isa(t, T.Num) then
					report_error(stat, "Numeric for loop expected numeric %s, got %s", what, t)
				end
			end

			local start_t = analyze_expr_single(stat.Start, stat.Scope)
			local end_t   = analyze_expr_single(stat.End, stat.Scope)

			check_num_arg('start', start_t)
			check_num_arg('end',   end_t)

			local iter_t = T.combine(start_t, end_t)

			if stat.Step then
				local step_t   = analyze_expr_single(stat.Step, stat.Scope)
				check_num_arg('step', step_t)
				iter_t = T.combine(iter_t, step_t)
			end

			local iter_var = DeclareLocal(stat, stat.Scope, stat.VarName)
			iter_var.Type = iter_t
			
			local ret = analyze_statlist(stat.Body, stat.Scope, scope_fun)
			return ret


		elseif stat.AstType == 'LabelStatement' then

		elseif stat.AstType == 'GotoStatement' then

		elseif stat.AstType == 'Eof' then

		elseif stat.AstType == 'Typedef' then
			analyze_typedef( stat, scope )

		else
			print("Unknown AST Type: ", stat.AstType)
		end

		return nil   -- Returns nothing
	end


	local function pre_analyze_statement(stat, scope)
		local is_pre_analyze = true

		if stat.AstType == 'Typedef' then
			--analyze_typedef( stat, scope )

		elseif stat.AstType == 'VarDeclareStatement' then
			-- HACK for forward-declaring namespaces:
			if #stat.NameList == 1 and #stat.InitList == 1 then
				local init = stat.InitList[1]
				if init.AstType == 'ConstructorExpr' then
					if #init.EntryList == 0 then
						-- {}
						local is_local = (stat.Type ~= 'global')
						local v = DeclareVar(stat, scope, stat.NameList[1], is_local)
						v.ForwardDeclared = true
					end
				end
			end

		elseif stat.AstType == 'AssignmentStatement' then
			-- Could be a    foo = function( ... )   where foo has been forward declared earlier without a type

			if #stat.Lhs == 1 and #stat.Rhs == 1 then
				if stat.Lhs[1].AstType == 'IdExpr' then
					if stat.Rhs[1].AstType == 'LambdaFunction' then
						--do_assignment(stat, scope, stat.Lhs[1], fun_t)

						local varName = stat.Lhs[1].Name

						local v = nil

						if true then
							v = scope:GetScopedVar( varName )
							assert(not v)
							v = scope:GetVar( varName )
							if v then
								-- Assigning to something declared in an outer scope
							else
								v = scope:CreateLocal( varName, where_is(stat) )
								v.ForwardDeclared = true
							end
						else
							v = scope:GetVar( varName )
							if not v then
								report_error(stat, "Implicit global '%s'", varName)
								v = scope:CreateGlobal( varName, where_is(stat) )
							end
						end
					
						if v.Type then
							report_error(stat, "Cannot forward declare '%s': it already has type '%s'", v.Name, T.name(v.Type))
						end

						local fun_t = analyze_function_head( stat.Rhs[1], scope, is_pre_analyze )
						fun_t.pre_analyzed = true -- Rmember that this is a temporary 'guess'

						v.Type = fun_t

						if _G.g_spam then
							report_spam(stat, "Forward-declared '%s' as '%s'", v.Name, T.name(fun_t))
						end
					end
				end


				if stat.Lhs[1].AstType == 'VarExpr' then
					if stat.Rhs[1].AstType == 'LambdaFunction' then
						local fun_t = analyze_function_head( stat.Rhs[1], scope, is_pre_analyze )
						fun_t.pre_analyzed = true -- Rmember that this is a temporary 'guess'

						--do_assignment(stat, scope, stat.Lhs[1], fun_t)
						local v = stat.Lhs[1].Variable

						if v.Type then
							report_error(stat, "Cannot forward declare '%s': it already has type '%s'", v.Name, T.name(fun_t))
						end

						v.Type = fun_t

						if _G.g_spam then
							report_spam(stat, "Forward-declared '%s' as '%s'", v.Name, T.name(fun_t))
						end
					end
				end
			end

		elseif stat.AstType == 'FunctionDecl' then
			assert(stat.Scope.Parent == scope)

			if stat.Name then
				if _G.g_spam then
					report_spam(stat, "Pre-analyzing function %s...", format_expr(stat.Name))
				end
			else
				return
			end

			local fun_t = analyze_function_head( stat, scope, is_pre_analyze )
			fun_t.pre_analyzed = true -- Rmember that this is a temporary 'guess'

			if stat.IsLocal then
				-- e.g.  "local function foo(bar)"
				--report_spam(stat, "local function, name: %q", expr2str(stat.Name))
				stat.Variable.Type = fun_t -- TODO: can't use 'Variable' here w/o a lookup!
			else
				-- function foo(arg)      -- global - not OK
				-- or
				-- function foo.bar(arg)  -- namespaced - OK
				-- function foo:bar(arg)  -- member - OK
				if stat.Name.AstType ~= 'MemberExpr' then
					-- e.g.  "function foo(bar)"
					report_warning(stat, "global function, name: %q", expr2str(stat.Name))
				end

				if stat.Name and _G.g_spam then
					report_spam(stat, "Pre-analyzed function head for %q as '%s'", format_expr(stat.Name), T.name(fun_t))
				end

				do_assignment(stat, scope, stat.Name, fun_t, is_pre_analyze)

				report_spam(stat, "Assigned.")
			end
		end
	end


	-- Returns the list of types returned in these statements
	-- or nil if no returns statements where found
	analyze_statlist = function(stat_list, scope, scope_fun)
		assert(stat_list)
		assert(scope)
		local return_types = nil

		local list_scope = stat_list.Scope
		--assert(list_scope.Parent == scope)
		assert(list_scope)

		-- Look for function declarations:
		-- This is so that we don't need to forward-declare function
		-- like we have to in lesser languages.

		for _, stat in ipairs(stat_list.Body) do
			pre_analyze_statement(stat, list_scope)
		end


		-- End
		for _, stat in ipairs(stat_list.Body) do
			local stat_rets = analyze_statement(stat, list_scope, scope_fun)
			return_types = T.combine_type_lists(return_types, stat_rets)
		end

		return return_types
	end


	local top_scope = ast.Scope  -- HACK
	local module_function = {
		tag = "function",
		args = {}
		-- name = ???
		-- rets = ???
	}
	local ret = analyze_statlist(ast, top_scope, module_function)

	if _G.g_ignore_errors or error_count == 0 then
		return true, ret
	else
		return false, string.format("%i errors", error_count)
	end
end

return Analyze
