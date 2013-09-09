--[[ DO NOT MODIFY - COMPILED FROM sol/type_check.sol --]] --[[ DO NOT MODIFY - COMPILED FROM ../sol/TypeCheck.sol --]] 
--[[ DO NOT MODIFY - COMPILED FROM ../sol/TypeCheck.sol --]] 
local U   = require 'util' --[[SOL OUTPUT--]] 
local set = U.set --[[SOL OUTPUT--]] 
local T   = require 'type' --[[SOL OUTPUT--]] 
local L   = require 'lexer' --[[SOL OUTPUT--]] 
local P   = require 'parser' --[[SOL OUTPUT--]] 
local S   = require 'scope' --[[SOL OUTPUT--]] 
local D   = require 'sol_debug' --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 


local NumOps 



= set{
	'+', '-', '*', '/', '%', '^'
} --[[SOL OUTPUT--]] 
local NumCompOps = set{
	'<', '<=', '>', '>='
} --[[SOL OUTPUT--]] 


local function loose_lookup(table, id)
	D.assert(type(id) == 'string') --[[SOL OUTPUT--]] 

	if table[id] then
		return id --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local edit_distance = require 'edit_distance' --[[SOL OUTPUT--]] 

	local MAX_DIST = 2 --[[SOL OUTPUT--]] 
	local  closest_dist = math.huge --[[SOL OUTPUT--]] 
	local closest_key  = nil --[[SOL OUTPUT--]] 

	for k,v in pairs(table) do
		D.assert(type(k) == 'string') --[[SOL OUTPUT--]] 

		local dist = edit_distance(k, id, MAX_DIST) --[[SOL OUTPUT--]] 
		if dist < MAX_DIST then
			--U.printf("Dist between '%s' and '%s' is %d", k, id, dist)
			if dist < closest_dist then
				closest_dist = dist --[[SOL OUTPUT--]] 
				closest_key = k --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if closest_dist >= MAX_DIST then
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	assert(type(closest_key) == 'string') --[[SOL OUTPUT--]] 
	return closest_key --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function expr2str(e) 
	local ignore_set = U.set{'var_', 'scope', 'tokens'} --[[SOL OUTPUT--]] 
	return U.serialize(e, ignore_set) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function format_expr(e)
	local format_identity = require 'format_identity' --[[SOL OUTPUT--]] 
	local insert_new_lines = false --[[SOL OUTPUT--]] 
	local str = format_identity(e, '', insert_new_lines) --[[SOL OUTPUT--]] 
	str = U.trim(str) --[[SOL OUTPUT--]] 
	return str --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 





local function analyze(ast, filename, on_require, settings)
	local analyze_statlist, analyze_expr, analyze_expr_single --[[SOL OUTPUT--]] 
	local analyze_expr_unchecked --[[SOL OUTPUT--]] 

	local error_count = 0 --[[SOL OUTPUT--]] 

	local function where_is(node)
		if node and node.where then
			return node.where --[[SOL OUTPUT--]] 
		elseif node and node.tokens and node.tokens[1] then
			local tok = node.tokens[1] --[[SOL OUTPUT--]] 
			return string.format('%s:%i', filename, tok.line) --[[SOL OUTPUT--]] 
		else
			D.break_() --[[SOL OUTPUT--]] 
			return filename .. ':??' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function fancy_format(fmt, ...)
		local buf = {} --[[SOL OUTPUT--]] 
		for i = 1, select( '#', ... ) do
			local a = select( i, ... ) --[[SOL OUTPUT--]] 
			if type(a) == 'table' and a.ast_type then
				a = format_expr(a) --[[SOL OUTPUT--]] 
			elseif T.is_type(a) or T.is_type_list(a) then
				a = T.name(a) --[[SOL OUTPUT--]] 
			elseif type( a ) ~= 'string' and type( a ) ~= 'number' then
				-- bool/table
				a = tostring( a ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			buf[i] = a --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return string.format( fmt, unpack( buf ) ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function report(type, node, fmt, ...)
		local inner_msg = fancy_format(fmt, ...) --[[SOL OUTPUT--]] 
		local msg = string.format('%s: %s: %s', type, where_is(node), inner_msg) --[[SOL OUTPUT--]] 
		return msg --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_spam(node, fmt, ...)
		if _G.g_spam then
			print( report('Spam', node, fmt, ...) ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_info(node, fmt, ...)
		print( report('Info', node, fmt, ...) ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_warning(node, fmt, ...)
		print( report('WARNING', node, fmt, ...) ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function sol_warning(node, fmt, ...)
		if settings.is_sol then
			report_warning(node, fmt, ...) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_error(node, fmt, ...)
		if settings.is_sol then
			U.printf_err( "%s", report('ERROR', node, fmt, ...) ) --[[SOL OUTPUT--]] 
			error_count = error_count + 1 --[[SOL OUTPUT--]] 
		else
			-- Forgive lua code
			print( report('WARNING', node, fmt, ...) ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--[[
	-- Will lookup typedefs in scope variables
	local function reduce_type(node, scope, t)
		if t then
			if t.tag == 'identifier' then
				if not t.type then
					if not t.var_.namespace then
						report_error(t, scope)
					t.type = var_.namespace
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




	local function declare_local(node, scope, name)
		D.assert(node and scope and name) --[[SOL OUTPUT--]] 
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		local old = scope:get_scoped(name) --[[SOL OUTPUT--]] 

		if old and old.forward_declared then
			old.forward_declared = false --[[SOL OUTPUT--]]  -- Properly declared now
			-- TODO: move to proper scope!
			assert(not old.is_global) --[[SOL OUTPUT--]] 
			assert(old.scope == scope) --[[SOL OUTPUT--]] 
			old.where = where_is(node) --[[SOL OUTPUT--]]  -- Update position of forward-declare
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if old then
			if name ~= "st" and name ~= "_" then  -- HACK
				report_error(node, "'%s' already declared in this scope, at %s", name, old.where) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return scope:create_local(name, where_is(node)) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function declare_global(node, scope, name)
		D.assert(node and scope and scope.parent) --[[SOL OUTPUT--]] 
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		if name ~= '_' then
			if not scope:is_module_level() then
				report_error(node, "Global variables should be declared in the top scope") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local old = scope:get_var(name) --[[SOL OUTPUT--]] 

		if old and old.forward_declared then
			old.forward_declared = false --[[SOL OUTPUT--]]  -- Properly declared now
			-- TODO: move to proper scope!
			assert(old.is_global) --[[SOL OUTPUT--]] 
			assert(old.scope == scope) --[[SOL OUTPUT--]] 
			old.where = where_is(node) --[[SOL OUTPUT--]]  -- Update position of forward-declare
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if old then
			report_error(node, "global '%s' already declared at %s", name, old.where) --[[SOL OUTPUT--]] 
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return scope:create_global(name, where_is(node)) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function declare_var(node, scope, name, is_local)
		if is_local then
			return declare_local(node, scope, name) --[[SOL OUTPUT--]] 
		else
			return declare_global(node, scope, name) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function check_type_is_a(msg, expr, expr_type, expected_type, severity)
		if T.could_be(expr_type, expected_type) then
			return true --[[SOL OUTPUT--]] 
		else
			local error_rope = {} --[[SOL OUTPUT--]] 
			T.could_be(expr_type, expected_type, error_rope) --[[SOL OUTPUT--]] 
			local error_msg = table.concat(error_rope, '\n') --[[SOL OUTPUT--]] 
			local reporter = (severity == 'error' and report_error or report_warning) --[[SOL OUTPUT--]] 
			reporter(expr, "%s: Expected type '%s', got '%s': %s", msg, T.name(expected_type), T.name(expr_type), error_msg) --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	analyze_expr = function(expr, scope) --> T.Type or T.Typelist, Variable?  -- TODO
		local type, var_ = analyze_expr_unchecked(expr, scope) --[[SOL OUTPUT--]] 

		D.assert(T.is_type(type)  or  T.is_type_list(type)) --[[SOL OUTPUT--]] 

		if not T.is_type(type) and not T.is_type_list(type) then
			report_error(expr, "expression of type %s: evaluated to non-type: '%s'", expr.ast_type, U.pretty(type)) --[[SOL OUTPUT--]] 
			type = T.AnyTypeList --[[SOL OUTPUT--]]  -- Could be any number of unknown values
		end --[[SOL OUTPUT--]] 

		--report_spam(expr, 'expression of type %s evaluated to %s', expr.ast_type, type)

		return type, var_ --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Will make sure to return a single type, never void or multiple returns
	analyze_expr_single = function(expr, scope)
		local t,v = analyze_expr(expr, scope) --[[SOL OUTPUT--]] 
		if t == T.AnyTypeList then
			return T.Any, v --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if T.is_type_list(t) then
			if #t == 0 then
				report_error(expr, "Analyzing '%s' expression: Expected type, got void", expr.ast_type) --[[SOL OUTPUT--]] 
				return T.Any, v --[[SOL OUTPUT--]] 
			elseif #t == 1 then
				return t[1], v --[[SOL OUTPUT--]] 
			else
				report_error(expr, "Expected single type, got: '%s' when analyzing '%s' expression", t, expr.ast_type) --[[SOL OUTPUT--]] 
				return T.Any, v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			return t, v --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function check_return_types(node, does_return, should_return)
		if should_return then
			assert(T.is_type_list(does_return)) --[[SOL OUTPUT--]] 
			assert(T.is_type_list(should_return)) --[[SOL OUTPUT--]] 

			if not T.could_be_tl(does_return, should_return) then
				local problem_rope = {} --[[SOL OUTPUT--]] 
				T.could_be_tl(does_return, should_return, problem_rope) --[[SOL OUTPUT--]] 
				local problem_str = table.concat(problem_rope, '\n') --[[SOL OUTPUT--]] 
				report_warning(node, "Return statement does not match function return type declaration, returns: '%s', expected: '%s'. %s", does_return, should_return, problem_str) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_expr_single_custom(expr, scope, is_pre_analyze)
		if not is_pre_analyze then
			return analyze_expr_single(expr, scope) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if expr.ast_type == 'IdExpr' then
			local base_var = scope:get_var( expr.name ) --[[SOL OUTPUT--]] 

			if base_var then
				return base_var.type or T.Any, base_var --[[SOL OUTPUT--]] 
			else
				report_error(expr, "Unknown identifier '%s'", expr.name) --[[SOL OUTPUT--]] 
				return T.Any, nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		else
			return T.Any, nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	 
	-- analyze a function declaration head - either a named one or a lambda function
	local analyze_function_head = function(node, scope, is_pre_analyze)
		assert(node.return_types == nil or T.is_type_list(node.return_types)) --[[SOL OUTPUT--]] 

		local fun_t = {
			tag = "function",
			args = {},
			rets = node.return_types  -- If any
		} --[[SOL OUTPUT--]] 

		if node.is_mem_fun then
			local name = node.name --[[SOL OUTPUT--]] 
			assert(name.ast_type == 'MemberExpr' and name.indexer == ':') --[[SOL OUTPUT--]] 
			local self_type = analyze_expr_single_custom(name.base, scope, is_pre_analyze) --[[SOL OUTPUT--]] 
			table.insert(fun_t.args, {name = 'self', type = self_type}) --[[SOL OUTPUT--]] 

			node.self_var_type = self_type --[[SOL OUTPUT--]]   -- Assign a type to the local 'self' variable

			--report_spam(node, "self: '%s'", self_type)
		end --[[SOL OUTPUT--]] 

		for i,arg in ipairs(node.arguments) do
			table.insert(fun_t.args, {name = arg.name, type = arg.type or T.Any}) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if node.vararg then
			fun_t.vararg = node.vararg --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		report_spam(node, "analyze_function_head: '%s'", fun_t) --[[SOL OUTPUT--]] 

		return fun_t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--[[ Will analyze body and check its return-statements against fun_t.
	     If fun_t.rets is nil (no type deduced) then this function will fill it in via deduction.
	--]]
	local function analyze_function_body(node, fun_t)
		local func_scope = node.scope --[[SOL OUTPUT--]] 

		-- Declare arguments as variables:
		if node.is_mem_fun then
			assert(node.self_var_type) --[[SOL OUTPUT--]]  -- Set by analyze_function_head
			local v = declare_local(node, func_scope, 'self') --[[SOL OUTPUT--]] 
			v.type = node.self_var_type --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for _,arg in ipairs(node.arguments) do
			local v = declare_local(node, func_scope, arg.name) --[[SOL OUTPUT--]] 
			v.type = arg.type --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if node.vararg then
			local v = declare_local(node, func_scope, '...') --[[SOL OUTPUT--]] 
			v.type = node.vararg --[[SOL OUTPUT--]] 
			assert(T.is_type(v.type)) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		---

		local ret_t = analyze_statlist(node.body, func_scope, fun_t) --[[SOL OUTPUT--]] 
		ret_t = ret_t and T.as_type_list(ret_t) or T.Void --[[SOL OUTPUT--]] 

		if fun_t.rets then
			if not T.could_be_tl(ret_t, fun_t.rets) then
				report_error(node, "Return statement(s) does not match function return type declaration, returns: '%s', expected: '%s'",
					T.name(ret_t), T.name(fun_t.rets)) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			-- Deduce return type:
			if ret_t then
				fun_t.rets = ret_t --[[SOL OUTPUT--]] 
			else
				fun_t.rets = T.Void --[[SOL OUTPUT--]]   -- No returns  == void
			end --[[SOL OUTPUT--]] 
			--report_spam(node, 'function deduced return type: %s', fun_t.rets)
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function do_indexing(node, type, name)
		--report_spam(node, "Looking for member %q in %s", name, type)

		type = T.follow_identifiers(type) --[[SOL OUTPUT--]] 

		if type.tag == 'variant' then
			local indexed_type = nil --[[SOL OUTPUT--]] 

			for _,v in ipairs(type.variants) do
				indexed_type = T.variant(indexed_type, do_indexing(node, v, name)) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return indexed_type --[[SOL OUTPUT--]] 
		elseif type.tag == 'object' then
			local obj = type --[[SOL OUTPUT--]] 
			local indexed_type = obj.members[name] --[[SOL OUTPUT--]] 

			if not indexed_type and obj.metatable then
				local indexer = obj.metatable.members['__index'] --[[SOL OUTPUT--]] 
				if indexer then
					if indexer.tag == 'function' then
						report_spam(node, "metatable has __index function") --[[SOL OUTPUT--]] 
						if indexer.rets and #indexer.rets>0 then
							return indexer.rets[1] --[[SOL OUTPUT--]] 
						else
							-- TODO: warnings should be written on __index set
							report_error(node, "Unexpected __index function - no returns values") --[[SOL OUTPUT--]] 
							return T.Any --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					else
						report_spam(node, "Looking up member %q in metatbale __index", name) --[[SOL OUTPUT--]] 
						return do_indexing(node, indexer, name) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			indexed_type = T.broaden( indexed_type ) --[[SOL OUTPUT--]]  -- Previous value may have been 'false' - we should allow 'true' now:

			if obj.derived then
				for _,v in ipairs(obj.derived) do
					indexed_type = T.variant(indexed_type, do_indexing(node, v, name)) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return indexed_type --[[SOL OUTPUT--]] 
		elseif T.isa(type, T.String) then
			-- TODO:  'example':upper()
			return T.Any --[[SOL OUTPUT--]] 
		elseif T.is_any(type) then
			return T.Any --[[SOL OUTPUT--]] 
		else
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function generator_types(expr, fun_t, arg_ts)
		--------------------------------------------------------
		-- SPECIAL: 'pairs':
		if fun_t.intrinsic_name == 'pairs' then
			if #arg_ts ~= 1 then
				report_error(expr, "Too many arguments to 'pairs'") --[[SOL OUTPUT--]] 
			else
				local function pairs_type(typ, error_rope)
					typ = T.follow_identifiers(typ) --[[SOL OUTPUT--]] 

					if typ == T.Any or typ.tag == 'table' then
						return { T.Any, T.Any } --[[SOL OUTPUT--]] 
					elseif typ.tag == 'object' then
						return { T.String, T.Any } --[[SOL OUTPUT--]] 
					elseif typ.tag == 'map' then
						assert( typ.key_type ) --[[SOL OUTPUT--]] 
						assert( typ.value_type ) --[[SOL OUTPUT--]] 
						return { typ.key_type, typ.value_type } --[[SOL OUTPUT--]] 
					elseif typ.tag == 'list' then
						--report_warning(expr, "Calling 'pairs' on a list - did you mean to use 'ipairs'?")
						report_error(expr, "Calling 'pairs' on a list - did you mean to use 'ipairs'?") --[[SOL OUTPUT--]] 
						assert( typ.type ) --[[SOL OUTPUT--]] 
						return { T.Uint, typ.type } --[[SOL OUTPUT--]] 
					elseif typ.tag == 'variant' then
						local types = nil --[[SOL OUTPUT--]] 

						for _,v in ipairs(typ.variants) do
							types = T.combine_type_lists(types, pairs_type(v, error_rope)) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						assert(types == nil  or  #types == 2) --[[SOL OUTPUT--]] 
						return types --[[SOL OUTPUT--]] 
					else
						table.insert(error_rope, string.format("Incompatible type: '%s'", T.name(typ))) --[[SOL OUTPUT--]] 
						return nil --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local error_rope = {} --[[SOL OUTPUT--]] 
				local types = pairs_type( arg_ts[1], error_rope ) --[[SOL OUTPUT--]] 
				if types then
					assert(#types == 2) --[[SOL OUTPUT--]] 
					return types --[[SOL OUTPUT--]] 
				else
					report_error(expr, "'pairs' called on incompatible type: " .. table.concat(error_rope, '\n')) --[[SOL OUTPUT--]] 
					return { T.Any, T.Any } --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 


		--------------------------------------------------------
		-- SPECIAL: 'ipairs':
		if fun_t.intrinsic_name == 'ipairs' then
			if #arg_ts ~= 1 then
				report_error(expr, "Too many arguments to 'ipairs'") --[[SOL OUTPUT--]] 
			else
				local function ipairs_type(typ, error_rope)
					typ = T.follow_identifiers(typ) --[[SOL OUTPUT--]] 

					if typ == T.Any then
						return {T.Uint, T.Any} --[[SOL OUTPUT--]] 
					elseif typ.tag == 'table' or T.is_empty_table(typ) then
						report_warning(expr, "Calling 'ipairs' on unknown table") --[[SOL OUTPUT--]] 
						return {T.Uint, T.Any} --[[SOL OUTPUT--]]  -- Presumably a list?
					elseif typ.tag == 'list' then
						return {T.Uint, typ.type} --[[SOL OUTPUT--]] 
					elseif typ.tag == 'variant' then
						local types = nil --[[SOL OUTPUT--]] 

						for _,v in ipairs(typ.variants) do
							types = T.combine_type_lists(types, ipairs_type(v, error_rope)) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						assert(types == nil  or  #types == 2) --[[SOL OUTPUT--]] 
						return types --[[SOL OUTPUT--]] 
					else
						table.insert(error_rope, T.name(typ)) --[[SOL OUTPUT--]] 
						return nil --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local error_rope = {} --[[SOL OUTPUT--]] 
				local types = ipairs_type( arg_ts[1], error_rope ) --[[SOL OUTPUT--]] 
				if types then
					assert(#types == 2) --[[SOL OUTPUT--]] 
					return types --[[SOL OUTPUT--]] 
				else
					report_error(expr, "'ipairs' called on incompatible type: " .. table.concat(error_rope, ', ')) --[[SOL OUTPUT--]] 
					return { T.Uint, T.Any } --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--------------------------------------------------------

		return T.AnyTypeList --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function check_arguments(expr, fun_t, arg_ts)
		assert(fun_t.args) --[[SOL OUTPUT--]] 
		local fun_name = fun_t.name or "lambda" --[[SOL OUTPUT--]] 
		D.assert(type(fun_name) == 'string', "fun_name: %s", fun_name) --[[SOL OUTPUT--]] 

		-- check arguments:
		local i = 1 --[[SOL OUTPUT--]] 
		while true do
			--report_spam(expr, "Checking argument %i", i)

			if i <= #fun_t.args then
				if fun_t.args[i].name == 'self' and i ~= 1 then
					report_error(expr, "'self' must be the first arguemnt") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local expected = fun_t.args[i].type --[[SOL OUTPUT--]] 

				if i <= #arg_ts then
					local given = arg_ts[i] --[[SOL OUTPUT--]] 

					if given.tag == 'varargs' then
						-- When calling with ..., if ... is empty we get nil:s
						given = T.variant(given.type, T.Nil) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					--report_spam(expr, "Checking argument %i: can we convert from '%s' to '%s'?", i, given, expected)


					if T.is_variant(given) then
						-- ensure  string?  ->  int?   does NOT pass
						given = T.variant_remove(given, T.Nil) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					--report_info(expr, "Checking argument %i: could %s be %s ?", i, T.name(arg_ts[i]), expected)
					
					if not T.could_be(given, expected) then
						local problem_rope = {} --[[SOL OUTPUT--]] 
						T.could_be(given, expected, problem_rope) --[[SOL OUTPUT--]] 
						local err_msg = table.concat(problem_rope, '\n') --[[SOL OUTPUT--]] 
						report_error(expr, "%s argument %i: could not convert from '%s' to '%s': %s",
						                    fun_name, i, T.name_verbose(given), T.name_verbose(expected), err_msg) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					if i == 1 and fun_t.args[i].name == 'self' then
						report_error(expr, "Missing object argument ('self'). Did you forget to call with : ?") --[[SOL OUTPUT--]] 
					elseif not T.is_nilable(expected) then
						report_error(expr, "Missing non-nilable argument %i: expected '%s'", i, expected) --[[SOL OUTPUT--]] 
					elseif _G.g_spam then
						report_spam(expr, "Ignoring missing argument %i: it's nilable: '%s'", i, expected) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			elseif i <= #arg_ts then
				if fun_t.vararg then
					local given    = arg_ts[i] --[[SOL OUTPUT--]] 
					local expected = fun_t.vararg --[[SOL OUTPUT--]] 

					assert(expected.tag == 'varargs') --[[SOL OUTPUT--]] 
					expected = expected.type --[[SOL OUTPUT--]] 

					assert(T.is_type(given)) --[[SOL OUTPUT--]] 
					assert(T.is_type(expected)) --[[SOL OUTPUT--]] 

					report_spam(expr, "Check varargs. Given: '%s', expected '%s'", given, expected) --[[SOL OUTPUT--]] 

					if given.tag == 'varargs' then
						given = given.type --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if not T.could_be(given, expected) then
						report_error(expr, "%s argument %i: could not convert from '%s' to '%s' (varargs)", fun_name, i, given, expected) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					report_error(expr, "Too many arguments to function %s, expected %i", fun_name, #fun_t.args) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				break --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			i = i + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_require( module_name, req_where )
		return T.as_type_list( on_require( module_name, req_where ) ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function handle_setmetatable(expr, args, arg_ts)
		if #args ~= 2 then
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if args[1].ast_type ~= 'IdExpr' then
			report_warning(expr, "setmetatable: first argument must be an identifier, got %s", args[1].ast_type) --[[SOL OUTPUT--]] 
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if arg_ts[2].tag ~= 'object' then
			report_warning(expr, "setmetatable: second argument must be an object") --[[SOL OUTPUT--]] 
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local target_var = args[1].variable --[[SOL OUTPUT--]] 
		D.assert(target_var) --[[SOL OUTPUT--]] 
		local target_type = target_var.type --[[SOL OUTPUT--]] 

		if target_type then
			target_type = T.follow_identifiers( target_type ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if not target_type or target_type.tag == 'table' then
			target_type = { tag = 'object', members = {} } --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if target_type.tag ~= 'object' then
			report_error(expr, "setmetatable: first argument must name an object; got: %s", target_type) --[[SOL OUTPUT--]] 
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		target_type = U.shallow_clone(target_type) --[[SOL OUTPUT--]] 
		target_type.metatable = arg_ts[2] --[[SOL OUTPUT--]] 

		report_spam(expr, "Setting metatable") --[[SOL OUTPUT--]] 

		target_var.type = target_type --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_fun_call(expr, typ, args, arg_ts, report_errors)
		report_spam(expr, "analyze_fun_call, typ: '%s'", typ) --[[SOL OUTPUT--]] 
		report_spam(expr, "analyze_fun_call, arg_ts: '%s'", arg_ts) --[[SOL OUTPUT--]] 

		typ = T.follow_identifiers(typ) --[[SOL OUTPUT--]] 

		--[[
		-- TODO
		while T.isa(fun_t, T.Table) do
			fun_t = fun_t.members[ '__call' ]
		end
		--]]

		if T.is_any(typ) then
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if typ.tag == 'variant' then
			local ret = nil --[[SOL OUTPUT--]] 

			for _,v in ipairs(typ.variants) do
				ret = T.combine_type_lists(ret, analyze_fun_call(expr, v, args, arg_ts, report_errors)) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			D.assert( T.is_type_list(ret) ) --[[SOL OUTPUT--]] 
			return ret --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if typ.tag ~= 'function' then
			if report_errors then
				report_error(expr, "Not a function: '%s'", typ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local fun_t = typ --[[SOL OUTPUT--]] 

		--------------------------------------------------------
		-- Check special functions:

		if fun_t.intrinsic_name == 'require' then
			if #arg_ts == 1 and arg_ts[1].tag == 'string_literal' then
				--U.printf('"require" called with argument: %q', arg_ts[1])
				if on_require then
					return analyze_require( arg_ts[1].value, where_is(expr) ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				report_warning(expr, '"require" called with indeducible argument') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--------------------------------------------------------

		if fun_t.intrinsic_name == 'pairs' or fun_t.intrinsic_name == 'ipairs' then
			-- generators returns function that returns 'it_types':
			local it_types = generator_types(expr, fun_t, arg_ts) --[[SOL OUTPUT--]] 

			if it_types ~= T.AnyTypeList then
				--report_info(expr, "Generator recognized: %s", it_types)
			end --[[SOL OUTPUT--]] 

			--var<T.Function> ret = {  -- FIXME
			local ret = {
				tag    = 'function',
				args   = {},
				vararg = T.Any,
				rets   = it_types,
			} --[[SOL OUTPUT--]] 
			return { ret } --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--------------------------------------------------------

		if fun_t.intrinsic_name == 'setmetatable' then
			handle_setmetatable(expr, args, arg_ts) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--------------------------------------------------------

		check_arguments(expr, fun_t, arg_ts) --[[SOL OUTPUT--]] 

		--------------------------------------------------------
		-- Return types

		if fun_t.rets then
			D.assert( T.is_type_list(fun_t.rets) ) --[[SOL OUTPUT--]] 
			return fun_t.rets --[[SOL OUTPUT--]] 
		else
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 



	-- Returns a list of types
	local function call_function(expr, scope)
		--------------------------------------------------------
		-- Pick out function type:
		report_spam(expr, "Analyzing function base...") --[[SOL OUTPUT--]] 
		local fun_type = analyze_expr_single(expr.base, scope) --[[SOL OUTPUT--]] 
		report_spam(expr, "function base analyzed.") --[[SOL OUTPUT--]] 

		--------------------------------------------------------
		-- get argument types (they will be evaluated regardless of function type):

		local args = U.shallow_clone( expr.arguments ) --[[SOL OUTPUT--]] 

		local called_as_mem_fun = (expr.base.ast_type == 'MemberExpr' and expr.base.indexer == ':') --[[SOL OUTPUT--]] 

		if called_as_mem_fun then
			local obj_expr = expr.base.base --[[SOL OUTPUT--]] 
			table.insert(args, 1, obj_expr) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local arg_ts = {} --[[SOL OUTPUT--]] 
		for i,v in ipairs(args) do
			arg_ts[i], _ = analyze_expr_single(v, scope) --[[SOL OUTPUT--]] 
			assert(arg_ts[i], "missing type") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 


		--------------------------------------------------------
		-- Do we know the function type?

		local function try_call(typ, report_errors)
			typ = T.follow_identifiers(typ) --[[SOL OUTPUT--]] 

			if T.is_any(typ) then
				report_spam(expr, "Function call cannot be deduced - calling something of unknown type: '%s'", fun_type) --[[SOL OUTPUT--]] 
				return T.AnyTypeList --[[SOL OUTPUT--]] 

			elseif typ.tag == 'function' then
				local fun_t = typ --[[SOL OUTPUT--]] 
				local is_mem_fun = (#fun_t.args > 0 and fun_t.args[1].name == 'self') --[[SOL OUTPUT--]] 

				if called_as_mem_fun and not is_mem_fun then
					report_error(expr, "Calling non-member function as member function") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if not called_as_mem_fun and is_mem_fun then
					report_warning(expr, "Member function called as non-member function") --[[SOL OUTPUT--]] 
					--report_info(expr, "expr.base.ast_type: " .. expr.base.ast_type)
					--report_info(expr, "expr.base.indexer: " .. expr2str(expr.base.indexer))
				end --[[SOL OUTPUT--]] 

				local rets = analyze_fun_call(expr, fun_t, args, arg_ts, report_errors) --[[SOL OUTPUT--]] 
				D.assert( rets==nil or T.is_type_list(rets) ) --[[SOL OUTPUT--]] 
				return rets --[[SOL OUTPUT--]] 

			elseif typ.tag == 'variant' then
				local rets = nil --[[SOL OUTPUT--]] 
				for _,v in ipairs(typ.variants) do
					local list = try_call(v, report_errors) --[[SOL OUTPUT--]] 
					rets = T.combine_type_lists(rets, list) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				D.assert( T.is_type_list(rets) ) --[[SOL OUTPUT--]] 
				return rets --[[SOL OUTPUT--]] 

			elseif typ.tag == 'object' and typ.metatable and typ.metatable.members['__call'] then
				report_spam(expr, "__call") --[[SOL OUTPUT--]] 
				local call_t = typ.metatable.members['__call'] --[[SOL OUTPUT--]] 

				local ext_args   = U.list_concat({expr.base}, args) --[[SOL OUTPUT--]] 
				local ext_arg_ts = U.list_concat({fun_type}, arg_ts) --[[SOL OUTPUT--]] 

				local rets = analyze_fun_call(expr, call_t, ext_args, ext_arg_ts, report_errors) --[[SOL OUTPUT--]] 
				D.assert( rets==nil or T.is_type_list(rets) ) --[[SOL OUTPUT--]] 
				return rets --[[SOL OUTPUT--]] 

			elseif report_errors then
				report_error(expr, "Cannot call '%s'", typ) --[[SOL OUTPUT--]] 
				return nil --[[SOL OUTPUT--]] 
			else
				return nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local rets = try_call(fun_type, false) --[[SOL OUTPUT--]] 

		if rets then
			report_spam(expr, "Function deduced to returning: '%s'", rets) --[[SOL OUTPUT--]] 
			D.assert( T.is_type_list(rets) ) --[[SOL OUTPUT--]] 
			return rets --[[SOL OUTPUT--]] 
		else
			-- Show errors:
			report_error(expr, "Cannot call '%s'", fun_type) --[[SOL OUTPUT--]] 
			try_call(fun_type, true) --[[SOL OUTPUT--]] 
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 



	-- for k,v in some_expr
	-- this functions returns a list of types for k,v in the example above
	local function extract_iterator_type(expr, scope)
		report_spam(expr, "extract_iterator_type...") --[[SOL OUTPUT--]] 

		local gen_t = analyze_expr_single(expr, scope) --[[SOL OUTPUT--]] 

		report_spam(expr, "extract_iterator_type, gen_t: '%s'", gen_t) --[[SOL OUTPUT--]] 

		gen_t = T.follow_identifiers(gen_t) --[[SOL OUTPUT--]] 
		if gen_t == T.Any then
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if gen_t.tag ~= 'function' then
			local suggestion = 'pairs' --[[SOL OUTPUT--]] 
			if T.isa(gen_t, T.List) then
				suggestion = 'ipairs' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			report_error(expr, "Generator function expected, got '%s' - did you forget to use '%s'?", gen_t, suggestion) --[[SOL OUTPUT--]] 

			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local fun = gen_t --[[SOL OUTPUT--]] 
		--report_info(expr, "Generator deducted to %s", fun.rets)
		return fun.rets --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 



	local analyze_simple_expr_unchecked --[[SOL OUTPUT--]] 


	analyze_expr_unchecked = function(expr, scope)
		assert(expr) --[[SOL OUTPUT--]] 
		assert(type(expr) == 'table') --[[SOL OUTPUT--]] 
		if not expr.ast_type then
			error("Not an expression: " .. expr2str(expr)) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		assert(expr.ast_type) --[[SOL OUTPUT--]] 

		report_spam(expr, "Analyzing %s...", expr.ast_type) --[[SOL OUTPUT--]] 


		if expr.ast_type == 'IdExpr' then
			if expr.name == '_' then
				report_error(expr, "You may not read from discard variable '_'") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local var_ = scope:get_var( expr.name ) --[[SOL OUTPUT--]] 

			if var_ then
				if var_.forward_declared then
					report_error(expr, "Use of forward-declared variable '%s', forward-declared here: %s",
						expr.name, var_.where) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				var_.references = var_.references + 1 --[[SOL OUTPUT--]] 
			else
				if expr.name ~= '_' then  -- Implicit '_' var is OK
					report_error(expr, "Implicit global %q", expr.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				var_ = scope:create_global( expr.name, where_is(expr) ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--report_spam(expr, "IdExpr '%s': var_.type: '%s'", var_.name, var_.type)

			local type = var_.type or T.Any --[[SOL OUTPUT--]] 
			if var_.namespace then
				var_.type = var_.type or T.Object --[[SOL OUTPUT--]] 
				type = var_.type --[[SOL OUTPUT--]] 

				if T.is_empty_table(type) then
					type = {
						tag     = 'object';
						members = {};
					} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if type.tag == 'object' then
					if type.namespace then
						assert(type.namespace == var_.namespace) --[[SOL OUTPUT--]] 
					else
						type = U.shallow_clone(type) --[[SOL OUTPUT--]] 
						type.namespace = var_.namespace --[[SOL OUTPUT--]] 
						var_.type = type --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					report_error(expr, "Variable '%s' used as namespace but is not an object (it's '%s')", var_.name, type) --[[SOL OUTPUT--]] 
					var_.namespace = nil --[[SOL OUTPUT--]]  -- Only warn once
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			
			--report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.ast_type, type)

			D.assert(T.is_type(type)  or  T.is_type_list(type)) --[[SOL OUTPUT--]] 

			-- Store for quick access later on:
			expr.variable = var_ --[[SOL OUTPUT--]] 

			return type, var_ --[[SOL OUTPUT--]] 

		else
			local type = analyze_simple_expr_unchecked(expr, scope) --[[SOL OUTPUT--]] 

			report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.ast_type, type) --[[SOL OUTPUT--]] 
			D.assert(T.is_type(type)  or  T.is_type_list(type)) --[[SOL OUTPUT--]] 

			return type, nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	-- Return type
	analyze_simple_expr_unchecked = function(expr, scope)
		if expr.ast_type == 'NumberExpr' then
			-- TODO: 0xff, 42 is int,  42.0 is num
			local str = expr.value.data --[[SOL OUTPUT--]] 
			local t = T.from_num_literal( str ) --[[SOL OUTPUT--]] 
			if t then
				return t --[[SOL OUTPUT--]] 
			else
				report_error(expr, 'Failed to parse number: %q', str) --[[SOL OUTPUT--]] 
				return T.Num --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'StringExpr' then
			return T.from_string_literal( expr.value.data ) --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'BooleanExpr' then
			assert(expr.value == true or expr.value == false) --[[SOL OUTPUT--]] 
			if expr.value == true then
				return T.True --[[SOL OUTPUT--]] 
			else
				return T.False --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'NilExpr' then
			return T.Nil --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'BinopExpr' then
			local op = expr.op --[[SOL OUTPUT--]] 
			local lt = analyze_expr_single( expr.lhs, scope ) --[[SOL OUTPUT--]] 
			local rt = analyze_expr_single( expr.rhs, scope ) --[[SOL OUTPUT--]] 

			--report_spam(expr, "Binop: %s %s %s", lt, op, rt)

			if NumOps[op] then
				if T.could_be(lt, T.Num) and T.could_be(rt, T.Num) then
					return T.combine( lt, rt ) --[[SOL OUTPUT--]]   -- int,int -> int,   int,num -> num,  etc
				else
					report_error(expr,
						"Invalid types for operator %q: %s and %s", op, T.name(lt), T.name(rt)) --[[SOL OUTPUT--]] 
					return T.Num --[[SOL OUTPUT--]]  -- Good guess
				end --[[SOL OUTPUT--]] 

			elseif NumCompOps[op] then
				if T.could_be(lt, T.Num) and T.could_be(rt, T.Num) then
					return T.Bool --[[SOL OUTPUT--]] 
				elseif T.could_be(lt, T.String) and T.could_be(rt, T.String) then
					-- String comparisons OK
					return T.Bool --[[SOL OUTPUT--]] 
				else
					report_error(expr,
						"Invalid types for operator %q: %s and %s", op, T.name(lt), T.name(rt)) --[[SOL OUTPUT--]] 
					return T.Num --[[SOL OUTPUT--]]  -- Good guess
				end --[[SOL OUTPUT--]] 

			elseif op == '..' then
				if T.could_be(lt, T.String) or T.could_be(rt, T.String) then
					-- TODO: overloaded '..'
					return T.String --[[SOL OUTPUT--]] 
				else
					report_error(expr,
						"Cannot concatenate %s with %s", T.name(lt), T.name(rt)) --[[SOL OUTPUT--]] 
					return T.String --[[SOL OUTPUT--]]  -- Good guess
				end --[[SOL OUTPUT--]] 

			elseif op == '==' or op== '~=' then
				lt = T.simplify(lt) --[[SOL OUTPUT--]] 
				rt = T.simplify(rt) --[[SOL OUTPUT--]] 

				if T.is_variant(lt) and T.is_variant(rt) then
					-- ensure  string? == int?   does NOT pass:
					lt = T.variant_remove(lt, T.Nil) --[[SOL OUTPUT--]] 
					rt = T.variant_remove(rt, T.Nil) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				-- Make sure we aren't comparing string to int:s:
				if (not T.could_be(lt, rt)) and (not T.could_be(rt, lt)) then
					-- Apples and oranges
					report_error(expr, "Comparing incompatible types: '%s' and '%s'", lt, rt) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				return T.Bool --[[SOL OUTPUT--]] 

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
						--"Operator 'and' expected boolean expression to the left, got %s from expression %s", T.name(lt), expr2str(expr.lhs))
						"Operator 'and' expected boolean expression to the left, got '%s'", T.name(lt)) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				-- Iff left is false, then left, else right
				-- The left argument is returned iff it is evaluated to 'false' or 'nil'
				-- So we could return 'nil' (iff lt is nil:able), 'false' (iff lt is false:able) or right
				local types = rt --[[SOL OUTPUT--]] 
				
				if T.could_be(lt, T.False) then
					types = T.variant(types, T.False) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				
				if T.could_be(lt, T.Nil) then
					types = T.variant(types, T.Nil) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				return types --[[SOL OUTPUT--]] 

			elseif op == 'or' then
				if not T.is_useful_boolean(lt) then
					report_warning(expr,
						--"Operator 'or' expected boolean expression to the left, got %s from expression %s", T.name(lt), expr2str(expr.lhs))
						"Operator 'or' expected boolean expression to the left, got '%s'", T.name(lt)) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				-- If first argument is true, then the left is returned, else the right
				-- So we could return the right type or
				-- or we could return the left type, but only cases where the left type is NOT nil or false

				--return T.variant( lt, rt )
				local types = T.make_variant( lt ) --[[SOL OUTPUT--]]   -- Anything on the left...
				if not T.is_any(types) then
					report_spam(expr, "Binop: removing Nil and False from 'or'") --[[SOL OUTPUT--]] 
					types = T.variant_remove(types, T.Nil) --[[SOL OUTPUT--]]       -- ...except nil...
					types = T.variant_remove(types, T.False) --[[SOL OUTPUT--]]     -- ...except false...
				end --[[SOL OUTPUT--]] 
				types = T.variant(types, rt) --[[SOL OUTPUT--]]          -- ...or anything on the right
				return types --[[SOL OUTPUT--]] 
			else
				report_error(expr, "Unknown binary operator %q", expr.op) --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'UnopExpr' then
			local arg_t = analyze_expr_single(expr.rhs, scope) --[[SOL OUTPUT--]] 

			if expr.op == '-' then
				if T.could_be(arg_t, T.Num) then
					return T.Num --[[SOL OUTPUT--]] 
				elseif T.could_be(arg_t, T.Int) then
					return T.Int --[[SOL OUTPUT--]] 
				else
					report_error(expr, "Unary minus expected numeric argument, got %s", arg_t) --[[SOL OUTPUT--]] 
					return T.Num --[[SOL OUTPUT--]]  -- Good guess
				end --[[SOL OUTPUT--]] 

			elseif expr.op == 'not' then
				if not T.is_useful_boolean(arg_t) then
					report_warning(expr, "'not' operator expected boolean or nil:able, got '%s'", arg_t) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				return T.Bool --[[SOL OUTPUT--]] 

			elseif expr.op == '#' then
				if not T.could_be(arg_t, T.List) and not T.could_be(arg_t, T.String) then
					report_error(expr, "'#' operator expected list or string, got %s", arg_t) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				return T.Uint --[[SOL OUTPUT--]] 

			else
				report_error(expr, 'Unknown operator %q', expr.op) --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'DotsExpr' then
			local t = scope:get_var_args() --[[SOL OUTPUT--]] 
			if t then
				assert(t.tag == 'varargs') --[[SOL OUTPUT--]] 
				return t --[[SOL OUTPUT--]] 
			else
				report_error(expr, "No ... in scope") --[[SOL OUTPUT--]] 
				return {
					tag  = 'varargs',
					type = T.Any 
				} --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'CallExpr' then        -- foo(arg, ...)
			--U.printf('CallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope) --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'TableCallExpr' then   -- foo{arg}
			--U.printf('TableCallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope) --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'StringCallExpr' then  -- foo'arg'
			--U.printf('StringCallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope) --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'IndexExpr' then
			-- base[index]
			-- TODO: var
			local base_t  = analyze_expr_single(expr.base, scope) --[[SOL OUTPUT--]] 
			local index_t = analyze_expr_single(expr.index, scope) --[[SOL OUTPUT--]] 

			if T.is_any(base_t) then
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if T.is_empty_table(base_t) then
				-- Indexing what? We don't know
				report_warning(expr, 'Indexing unkown table') --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local list = T.find(base_t, T.List) --[[SOL OUTPUT--]]  -- TODO: find all lists and variant the reuslts
			if list then
				report_spam(expr, "List index") --[[SOL OUTPUT--]] 
				check_type_is_a("List index", expr.index, index_t, T.Uint, 'error') --[[SOL OUTPUT--]] 
				if list.type then
					report_spam(expr, "List index: indexing %s, element type is %s", list, list.type) --[[SOL OUTPUT--]] 
					return list.type --[[SOL OUTPUT--]] 
				else
					return T.Any --[[SOL OUTPUT--]]  -- FIXME
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local map = T.find(base_t, T.Map) --[[SOL OUTPUT--]]  -- TODO: find all maps and variant the results
			if map then
				report_spam(expr, "Map index") --[[SOL OUTPUT--]] 
				check_type_is_a("Map index", expr.index, index_t, map.key_type, 'error') --[[SOL OUTPUT--]] 
				return T.variant(map.value_type, T.Nil) --[[SOL OUTPUT--]]   -- Nil on not found
			end --[[SOL OUTPUT--]] 

			if T.find(base_t, T.Table) then
				report_spam(expr, "Table index") --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			report_error(expr, 'Cannot index type %s with %s - not a list, table or map', base_t, index_t) --[[SOL OUTPUT--]] 
			--error("FATAL")
			return T.Any --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'MemberExpr' then
			-- .  or  :
			local base_t = analyze_expr_single(expr.base, scope) --[[SOL OUTPUT--]] 
			local name = expr.ident.data --[[SOL OUTPUT--]] 

			if T.is_any(base_t) then
				return T.Any --[[SOL OUTPUT--]] 
			else
				local t = do_indexing(expr, base_t, name) --[[SOL OUTPUT--]] 
				if t then
					return t --[[SOL OUTPUT--]] 
				else
					--report_warning(expr, "Failed to find member '%s'", name) -- TODO
					return T.Any --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'LambdaFunctionExpr' then
			-- Lambda function
			local is_pre_analyze = false --[[SOL OUTPUT--]] 
			local fun_t = analyze_function_head( expr, scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
			analyze_function_body( expr, fun_t ) --[[SOL OUTPUT--]] 
			return fun_t --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'ConstructorExpr' then
			-- TODO    { foo = 32, bar = 15 }
			--[[ v.entry_list contains entries on the form

				{
					type  : 'ident_key' or 'key' or 'value',
					key   : ident or expr or nil,
					value : expr,
				}

				'key'       means:  { [expr] = val }   - For maps
				'ident_key' means:  { ident  = val }   - For objects
				'value'     means:  {      val     }   - For lists

				Mixing is allowed in Lua, but not in Sol
			--]]
			if #expr.entry_list == 0 then
				-- {}
				-- Assume empty object?
				--report_warning(expr, "Explicit type missing - is this an empty table, list, map, object - what?")
				report_spam(expr, "Explicit type missing - is this an empty table, list, map, object - what?") --[[SOL OUTPUT--]] 
				return T.create_empty_table() --[[SOL OUTPUT--]] 
			else
				local   key_type    = T.make_variant() --[[SOL OUTPUT--]]  -- in maps
				local   value_type  = T.make_variant() --[[SOL OUTPUT--]] 
				local obj_members = {} --[[SOL OUTPUT--]] 

				local count = { ['key'] = 0, ['ident_key'] = 0, ['value'] = 0 } --[[SOL OUTPUT--]] 
				for _,e in pairs(expr.entry_list) do
					count[e.type] = count[e.type] + 1 --[[SOL OUTPUT--]] 

					local this_val_type = analyze_expr_single(e.value, scope) --[[SOL OUTPUT--]] 
					if this_val_type.tag == 'varargs' then
						this_val_type = this_val_type.type --[[SOL OUTPUT--]]  -- Many of these
					end --[[SOL OUTPUT--]] 

					value_type = T.extend_variant( value_type, this_val_type ) --[[SOL OUTPUT--]] 

					if e.type == 'key' then
						assert(e.key) --[[SOL OUTPUT--]] 
						if not e.key.ast_type then
							report_error(expr, "Bad map key: %s", expr2str(e.key)) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						local this_key_type = analyze_expr_single(e.key, scope) --[[SOL OUTPUT--]] 
						key_type = T.extend_variant( key_type, this_key_type ) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if e.type == 'ident_key' then
						obj_members[ e.key ] = this_val_type --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				key_type   = T.simplify( key_type ) --[[SOL OUTPUT--]] 
				value_type = T.simplify( value_type ) --[[SOL OUTPUT--]] 

				if count['key'] == #expr.entry_list then
					-- A map
					return {
						tag        = 'map',
						key_type   = key_type,
						value_type = value_type
					} --[[SOL OUTPUT--]] 

				elseif count['value'] == #expr.entry_list then
					-- A list
					return {
						tag  = 'list',
						type = value_type
					} --[[SOL OUTPUT--]] 

				elseif count['ident_key'] == #expr.entry_list then
					return {
						tag     = 'object',
						members = obj_members
					} --[[SOL OUTPUT--]] 

				else
					if count['value'] == 0 then
						report_error(expr, "Mixed initialization - please use [] on everything or nothing") --[[SOL OUTPUT--]] 
					else
						report_error(expr, "Mixed initialization - all or none of the values must have explicit keys") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					return T.Any --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'ParenthesesExpr' then
			local t = analyze_expr_single( expr.inner, scope ) --[[SOL OUTPUT--]] 
			return t --[[SOL OUTPUT--]] 

		else
			print("Unknown expression AST type: ", expr.ast_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		report_error(expr, "Failed to figure out type of %s", expr.ast_type) --[[SOL OUTPUT--]] 

		return T.Any --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- eg:  check_condition(stat, 'while', some_expr, scope)
	-- examples:   if some_expr then ...
	-- examples:   while true then ...
	local check_condition = function(stat, name, expr, scope)
		if expr.ast_type == 'BooleanExpr' then
			-- 'true' or 'false' as explici argument - that's OK
			-- e.g. for   while true do  ... break ... end
		else
			local t = analyze_expr_single(expr, scope) --[[SOL OUTPUT--]] 
			if not T.is_useful_boolean(t) then
				report_error(expr, "Not a useful boolean expression in %q, type is '%s'", name, t) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function decl_var_type(stat, var_, deduced_type)
		D.assert( T.is_type(deduced_type) ) --[[SOL OUTPUT--]] 

		if var_.type then
			-- .type must have been deduced by pre-parsing
			check_type_is_a("Variable declaration", stat, deduced_type, var_.type, 'error') --[[SOL OUTPUT--]] 
		else
			if deduced_type == T.Nil then
				--sol_warning(stat, "Initializing value with nil - type cannot be deduced")
				var_.type  = T.Nilable --[[SOL OUTPUT--]] 
			else
				var_.type  = T.broaden( deduced_type ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		var_.namespace = deduced_type.namespace --[[SOL OUTPUT--]]   -- If any
	end --[[SOL OUTPUT--]] 


	local function assign_to_obj_member(stat, scope,
		                                 is_pre_analyze, is_declare, extend_class,
		                                 obj_t, name, right_type)
	 											--> T.Type -- TODO: have this here


		report_spam(stat, "Exisiting object") --[[SOL OUTPUT--]] 

		local left_type = obj_t.members[name] --[[SOL OUTPUT--]] 

		if left_type and left_type.pre_analyzed then
			if right_type.pre_analyzed and is_pre_analyze then
				report_error(stat, "Name clash?") --[[SOL OUTPUT--]] 
			else
				D.assert(not right_type.pre_analyzed) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			-- The member type was reached by the pre-analyzer - overwrite with refined info:
			
			--obj_t.members[name] = nil  -- TODO: makes compilation hang!
			left_type = nil --[[SOL OUTPUT--]] 

			report_spam(stat, "Replacing pre-analyzed type with refined type: '%s'", right_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if left_type then
			report_spam(stat, "Object already has member") --[[SOL OUTPUT--]] 
			left_type = T.broaden( left_type ) --[[SOL OUTPUT--]]  -- Previous value may have been 'false' - we should allow 'true' now:

			if not T.could_be(right_type, left_type) then
				report_error(stat, "[B] type clash: cannot assign to '%s' (type '%s') with '%s'", name, left_type, right_type) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return obj_t --[[SOL OUTPUT--]] 
		else
			if not obj_t.members[name] then
				if not is_declare then
					local close_name = loose_lookup(obj_t.members, name) --[[SOL OUTPUT--]] 

					if close_name then
						report_warning(stat, "Could not find '%s' - Did you mean '%s'?", name, close_name) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				report_spam(stat, "Adding member") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--[[
			We do not broaden the type here, to make sure the following code works:

			typedef Foo = { tag : 'foo '}

			function fun() -> Foo
				local ret = {}
				ret.tag = 'foo'  -- No broadeding! tag is 'foo', not string
				return ret
			end
			--]]

			if extend_class then
				report_info(stat, "Extending class with %q", name) --[[SOL OUTPUT--]] 
				obj_t.members[name] = right_type --[[SOL OUTPUT--]] 
			else
				obj_t = U.shallow_clone( obj_t ) --[[SOL OUTPUT--]] 
				obj_t.members = U.shallow_clone( obj_t.members ) --[[SOL OUTPUT--]] 
				obj_t.members[name] = right_type --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return obj_t --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function do_assignment(stat, scope, left_expr, right_type, is_pre_analyze)
		assert(not T.is_type_list(right_type)) --[[SOL OUTPUT--]] 

		local is_declare = (stat.ast_type == 'FunctionDeclStatement') --[[SOL OUTPUT--]] 

		if right_type.namespace then
			report_error(stat, "Cannot assign namespace outside of declaration") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		report_spam(stat, 'do_assignment, left_expr.ast_type: %s', left_expr.ast_type) --[[SOL OUTPUT--]] 

		if left_expr.ast_type == 'MemberExpr' then
			-- foo.bar = ...
			local name = left_expr.ident.data --[[SOL OUTPUT--]] 

			local base_t, base_var = analyze_expr_single_custom(left_expr.base, scope, is_pre_analyze) --[[SOL OUTPUT--]] 

			if base_var then
				-- self.foo = 32 will actually add the member 'foo' to the class definition!
				-- think ctors and the like
				local extend_class = (base_var.name == 'self') --[[SOL OUTPUT--]] 


				if not base_var.type or T.is_empty_table(base_var.type) then
					report_spam(stat, "New object") --[[SOL OUTPUT--]] 
					base_var.type = { tag = 'object', members = {} } --[[SOL OUTPUT--]] 
					extend_class = false --[[SOL OUTPUT--]]  -- bad idea
				end --[[SOL OUTPUT--]] 

				report_spam(stat, "Assigning to %s.%s", base_var.name, name) --[[SOL OUTPUT--]] 

				local var_t = T.follow_identifiers(base_var.type) --[[SOL OUTPUT--]] 

				if var_t.tag == 'variant' then
					extend_class = false --[[SOL OUTPUT--]] 

					local variant = T.clone_variant(var_t) --[[SOL OUTPUT--]] 

					-- TODO: recurse
					for i,v in ipairs(variant.variants) do
						if v.tag == 'object' then
							variant.variants[i] = assign_to_obj_member(stat, scope,
								                                        is_pre_analyze, is_declare, extend_class,
								                                        v, name, right_type) --[[SOL OUTPUT--]] 	
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				elseif var_t.tag == 'object' then
					base_var.type = assign_to_obj_member(stat, scope,
						                                 is_pre_analyze, is_declare, extend_class,
						                                 var_t, name, right_type) --[[SOL OUTPUT--]] 	
					return --[[SOL OUTPUT--]] 
				elseif T.is_any(var_t) then
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_warning(stat, "[B] Trying to index type 'any' with '%s'", name) --[[SOL OUTPUT--]] 
				else
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_warning(stat, "[B] Trying to index non-object of type '%s' with '%s'", var_t, name) --[[SOL OUTPUT--]] 
					--D.break_()
				end --[[SOL OUTPUT--]] 

			else -- no variable we can update the type of
				-- e.g.:   foo.bar.baz
				report_warning(stat, "do_assignment: tried to index non-variable") --[[SOL OUTPUT--]] 
				assert(base_t) --[[SOL OUTPUT--]] 
				base_t = T.follow_identifiers(base_t) --[[SOL OUTPUT--]] 
				--assert(base_t ~= T.EmptyTable)

				if base_t.tag == 'object' then
					report_spam(stat, "Exisiting object") --[[SOL OUTPUT--]] 

					local left_type = base_t.members[name] --[[SOL OUTPUT--]] 

					if left_type and left_type.pre_analyzed then
						-- The member type was reached by the pre-analyzer - overwrite with refined info:
						assert(not right_type.pre_analyzed) --[[SOL OUTPUT--]] 
						--var_t.members[name] = nil  -- TODO: makes compilation hang!
						left_type = nil --[[SOL OUTPUT--]] 

						report_spam(stat, "Replacing pre-analyzed type with refined type: '%s'", right_type) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if left_type then
						report_spam(stat, "Object already has member") --[[SOL OUTPUT--]] 
						left_type = T.broaden( left_type ) --[[SOL OUTPUT--]]  -- Previous value may have been 'false' - we should allow 'true' now:

						if not T.could_be(right_type, left_type) then
							report_error(stat, "[A] type clash: cannot assign to '%s' (type '%s') with '%s'", name, left_type, right_type) --[[SOL OUTPUT--]] 
							return false --[[SOL OUTPUT--]] 
						else
							return true --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					else
						if not is_declare and not base_t.members[name] then
							local close_name = loose_lookup(base_t.members, name) --[[SOL OUTPUT--]] 

							if close_name then
								report_warning(stat, "Could not find '%s' - Did you mean '%s'?", name, close_name) --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						report_spam(stat, "Adding member") --[[SOL OUTPUT--]] 
						report_warning(stat, "Adding member %q to %q", name, base_t) --[[SOL OUTPUT--]] 

						--[[
						We do not broaden the type here, to make sure the following code works:

						typedef Foo = { tag : 'foo '}

						function fun() -> Foo
							local ret = {}
							ret.tag = 'foo'  -- No broadeding! tag is 'foo', not string
							return ret
						end
						--]]
						base_t.members[name] = right_type --[[SOL OUTPUT--]] 
						return true --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				elseif T.is_any(base_t) then
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_warning(stat, "[A] Trying to index type 'any' with '%s'", name) --[[SOL OUTPUT--]] 
				else
					report_warning(stat, "[A] Trying to index non-object of type '%s' with '%s'", base_t, name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if left_expr.ast_type == 'IndexExpr' then
			-- foo[bar] = ...  -- TODO
		end --[[SOL OUTPUT--]] 

		if left_expr.ast_type == 'IdExpr' and left_expr.name == '_' then
			-- Assigning to _ is always OK
			return true --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local left_type = analyze_expr_single( left_expr, scope ) --[[SOL OUTPUT--]] 

		if left_type.namespace then
			report_error(stat, "Cannot assign to a namespace outside of declaration") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--if not T.isa(right_type, left_type) then
		if not T.could_be(right_type, left_type) then
			local problem_rope = {} --[[SOL OUTPUT--]] 
			T.could_be(right_type, left_type, problem_rope) --[[SOL OUTPUT--]] 
			local problem_str = table.concat(problem_rope, '\n') --[[SOL OUTPUT--]] 
			report_error(stat, "[C] type clash: cannot assign to type '%s' with '%s': %s", left_type, right_type, problem_str) --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_typedef(stat, scope)
		local name = stat.type_name --[[SOL OUTPUT--]] 

		if stat.namespace_name then
			local v = scope:get_var( stat.namespace_name ) --[[SOL OUTPUT--]]  -- TODO: var

			if not v then
				report_error(stat, "namespaced typedef: %s is not a previously defined variable", stat.namespace_name) --[[SOL OUTPUT--]] 
				return --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			v.namespace = v.namespace or {} --[[SOL OUTPUT--]] 
			local ns = v.namespace --[[SOL OUTPUT--]] 
			if ns[name] then
				report_error(stat, "type %s.%s already declared as '%s'", v.name, name, ns[name]) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if stat.type then
				report_spam(stat, "Declaring type %s.%s as '%s'", v.name, name, stat.type) --[[SOL OUTPUT--]] 
			else
				report_spam(stat, "Forward-declaring type %s.%s", v.name, name) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			ns[name] = stat.type --[[SOL OUTPUT--]] 
		else
			local old = scope:get_scoped_type(name) --[[SOL OUTPUT--]] 
			if old then
				report_error(stat, "type %q already declared as '%s'", name, old) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			scope:declare_type(name, stat.type, where_is(stat)) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if stat.base_types and #stat.base_types > 0 then
			report_spam(stat, "%s inherits %i types", name, #stat.base_types) --[[SOL OUTPUT--]] 

			local child_type = T.follow_identifiers(stat.type) --[[SOL OUTPUT--]] 

			if child_type.tag ~= 'object' then
				report_error(stat, "Only objects can have base-types (child: '%s')", child_type) --[[SOL OUTPUT--]] 
			else
				for _,base in ipairs(stat.base_types) do
					report_spam(stat, "%s inheriting %s", name, base.name) --[[SOL OUTPUT--]] 

					if base.tag ~= 'identifier' then
						report_error(stat, "You can only inherit other typedef:s") --[[SOL OUTPUT--]] 
						break --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					local base_type = T.follow_identifiers(base) --[[SOL OUTPUT--]] 
					if base_type.tag ~= 'object' then
						--report_error(stat, "'%s' cannot inherit non-object '%s'", name, base_type)
						report_error(stat, "'%s' cannot inherit non-object '%s'", name, expr2str(base)) --[[SOL OUTPUT--]] 
						break --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					for id,id_type in pairs(base_type.members) do
						if child_type.members[id] then
							if not T.isa(child_type.members[id], id_type) then
								report_error(stat, "Child type '%s' overrides '%s' with differing type.", name, id) --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						else
							-- Inherit:
							child_type.members[id] = id_type --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					base_type.derived = base_type.derived or {} --[[SOL OUTPUT--]] 
					table.insert(base_type.derived, stat.type) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Iff it is a return statement, will returns a list of types
	-- Else nil
	-- 'scope_fun' contains info about the enclosing function
	local analyze_statement = function(stat, scope, scope_fun)
		assert(scope) --[[SOL OUTPUT--]] 
		local is_pre_analyze = false --[[SOL OUTPUT--]] 

		report_spam(stat, "analyze_statement %s", stat.ast_type) --[[SOL OUTPUT--]] 

		if stat.ast_type == 'AssignmentStatement' then
			local nlhs = #stat.lhs --[[SOL OUTPUT--]] 
			local nrhs = #stat.rhs --[[SOL OUTPUT--]] 
			assert(nrhs > 0) --[[SOL OUTPUT--]] 
			if nrhs == 1 then
				local rt = analyze_expr(stat.rhs[1], scope) --[[SOL OUTPUT--]] 
				rt = T.as_type_list(rt) --[[SOL OUTPUT--]] 
				if rt == T.AnyTypeList then
					-- Nothing to do
				elseif nlhs > #rt then
					report_error(stat, "Unequal number of variables and values: left hand side has %i variables, right hand side evaluates to %s", nlhs, rt) --[[SOL OUTPUT--]] 
				elseif nlhs < #rt then
					report_warning(stat, "Assignment discards values: left hand side has %i variables, right hand side evaluates to %s", nlhs, rt) --[[SOL OUTPUT--]] 
				else
					for i,v in ipairs(rt) do
						do_assignment(stat, scope, stat.lhs[i], rt[i], is_pre_analyze) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				if #stat.lhs ~= #stat.rhs then
					report_error(stat, "Unequal number of variables and values") --[[SOL OUTPUT--]] 
				else
					for i = 1,nrhs do
						local rti = analyze_expr_single(stat.rhs[i], scope) --[[SOL OUTPUT--]] 
						do_assignment(stat, scope, stat.lhs[i], rti, is_pre_analyze) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'CallStatement' then
			analyze_expr(stat.expression, scope) --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'VarDeclareStatement' then
			report_spam(stat, "VarDeclareStatement") --[[SOL OUTPUT--]] 

			-- Analyze init_list before declaring variables to prevent
			-- local x = x

			local init_types = {} --[[SOL OUTPUT--]] 

			if #stat.init_list == 1 then
				init_types = analyze_expr( stat.init_list[1], scope ) --[[SOL OUTPUT--]] 
			else
				for _,exp in ipairs(stat.init_list) do
					init_types[#init_types + 1] = analyze_expr_single( exp, scope ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local explicit_types = stat.type_list --[[SOL OUTPUT--]] 

			-- Declare variables:
			local is_local = (stat.type ~= 'global') --[[SOL OUTPUT--]] 
			local vars = {} --[[SOL OUTPUT--]] 
			for _,name in ipairs(stat.name_list) do
				report_spam(stat, "Declaration: %s %s", stat.type, name) --[[SOL OUTPUT--]] 
				local v = declare_var(stat, scope, name, is_local) --[[SOL OUTPUT--]] 
				--v.type = nil -- Ignore any forward-deduced type
				vars[#vars + 1] = v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if explicit_types then
				if #explicit_types ~= 1 and #explicit_types ~= #vars then
					report_error(stat, "Uneven number of explicit types (%i) and variables (%i) in 'local' declaration. Either supply just one type, or one type per variable.", #explicit_types, #vars) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if #explicit_types == 1 and #explicit_types ~= #vars then
					-- One type to be applied to all - just duplicate: 

					explicit_types = { explicit_types[1] } --[[SOL OUTPUT--]] 

					while #explicit_types < #vars do
						table.insert(explicit_types, explicit_types[1]) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local N = #vars --[[SOL OUTPUT--]] 
				for i = 1,N do
					local v = vars[i] --[[SOL OUTPUT--]] 
					v.type = explicit_types[i] --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if #stat.init_list == 0 then
				-- local a,b
				if stat.type == 'var' then
					report_error(stat, "'var' must be initialized at declaration") --[[SOL OUTPUT--]] 
				elseif explicit_types then
					for _,v in ipairs(vars) do
						if not T.is_nilable(v.type) then
							report_error(stat, "Variable '%s' of non-nilable type '%s' missing its definition",
								v.name, T.name(v.type)) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					for _,v in ipairs(vars) do
						if not v.type then   -- It could have a forward-type (local foo; foo = function() ... )
							sol_warning(stat, "Un-initialized local - type cannot be deduced!") --[[SOL OUTPUT--]] 
							v.type = T.Nilable --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif #stat.init_list == 1 then
				-- local a,b = foo()
				local t = init_types --[[SOL OUTPUT--]] 
				if t == T.AnyTypeList then
					-- Nothing to do
				else
					local deduced_types = T.as_type_list( t ) --[[SOL OUTPUT--]] 
					local nt = #deduced_types --[[SOL OUTPUT--]] 
					
					if #vars < nt then
						-- Ignoring a few return values is OK
					elseif #vars > nt then
						report_error(stat, "Too many variables in 'local' declaration. Right hand side has type %s",
							T.name(t)) --[[SOL OUTPUT--]] 
					else
						local N = #vars --[[SOL OUTPUT--]] 
						for i = 1,N do
							local v = vars[i] --[[SOL OUTPUT--]] 
							decl_var_type(stat, v, deduced_types[i]) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			elseif #vars ~= #stat.init_list then
				-- local a,b,c = 1,2
				report_error(stat, "Uneven number of variables and values in local declaration. Variables: %i, inits: %i",
					#vars, #stat.init_list) --[[SOL OUTPUT--]] 
			else
				-- local a,b,c = 1,2,3
				local N = #vars --[[SOL OUTPUT--]] 
				for i = 1,N do
					local v = vars[i] --[[SOL OUTPUT--]] 
					local deduced_type = init_types[i] --[[SOL OUTPUT--]] 
					assert( T.is_type(deduced_type) ) --[[SOL OUTPUT--]] 
					decl_var_type(stat, v, deduced_type) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if stat.type == 'var' and not explicit_types then
				for _,v in ipairs(vars) do
					if v.type==nil or T.is_any(v.type) then
						report_error(stat, "Undeducible type - the type of a 'var' must be compile-time deducible") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'IfStatement' then
			check_condition( stat, 'if', stat.clauses[1].condition, scope ) --[[SOL OUTPUT--]] 

			local ret = analyze_statlist( stat.clauses[1].body, scope, scope_fun ) --[[SOL OUTPUT--]] 

			for i = 2, #stat.clauses do
				local st = stat.clauses[i] --[[SOL OUTPUT--]] 
				if st.condition then
					check_condition( stat, 'elseif', st.condition, scope ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				ret = T.combine_type_lists(ret, analyze_statlist( st.body, scope, scope_fun )) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return ret --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'WhileStatement' then
			check_condition( stat, 'while', stat.condition, scope ) --[[SOL OUTPUT--]] 
			local ret = analyze_statlist(stat.body, scope, scope_fun) --[[SOL OUTPUT--]] 
			return ret --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'DoStatement' then
			local ret = analyze_statlist(stat.body, scope, scope_fun) --[[SOL OUTPUT--]] 
			return ret --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'ReturnStatement' then
			local what_to_return = nil --[[SOL OUTPUT--]] 
			if #stat.arguments == 0 then
				what_to_return = T.Void --[[SOL OUTPUT--]] 
			elseif #stat.arguments == 1 then
				what_to_return = T.as_type_list( analyze_expr( stat.arguments[1], scope ) ) --[[SOL OUTPUT--]] 
			else
				local type_list = {} --[[SOL OUTPUT--]] 
				for i = 1, #stat.arguments do
					local t = analyze_expr_single( stat.arguments[i], scope ) --[[SOL OUTPUT--]] 
					type_list[i] = t --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				what_to_return = type_list --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			--if scope_fun then
				check_return_types(stat, what_to_return, scope_fun.rets) --[[SOL OUTPUT--]] 
			--end
			return what_to_return --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'BreakStatement' then
			-- TODO

		elseif stat.ast_type == 'RepeatStatement' then
			local ret = analyze_statlist(stat.body, stat.scope, scope_fun) --[[SOL OUTPUT--]] 
			check_condition( stat, 'repeat', stat.condition, stat.scope ) --[[SOL OUTPUT--]] 
			return ret --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'FunctionDeclStatement' then
			assert(stat.scope.parent == scope) --[[SOL OUTPUT--]] 
			local is_pre_analyze = false --[[SOL OUTPUT--]] 
			local fun_t = analyze_function_head( stat, scope, is_pre_analyze ) --[[SOL OUTPUT--]] 

			--[[ Assign type before recursing on body.
			     This is so that recursive function can typecheck the calls to itself
			]]--
			if stat.var_name then
				--[[ e.g:
					"local function foo(bar)"
					"global function foo(bar)"
				--]]
				fun_t.name = stat.var_name --[[SOL OUTPUT--]] 

				report_spam(stat, "local function, name: %q", stat.name) --[[SOL OUTPUT--]] 

				local v = declare_var(stat, scope, stat.var_name, stat.is_local) --[[SOL OUTPUT--]] 
				v.type = fun_t --[[SOL OUTPUT--]] 
			else
				-- function foo:bar(arg)
				D.assert(stat.name) --[[SOL OUTPUT--]] 
				fun_t.name = format_expr(stat.name) --[[SOL OUTPUT--]] 

				if stat.name.ast_type ~= 'MemberExpr' then
					-- e.g.  "function foo(bar)"
					report_warning(stat, "non-local function, name: %q", stat.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				do_assignment(stat, scope, stat.name, fun_t, is_pre_analyze) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			-- Now analyze body:
			analyze_function_body( stat, fun_t ) --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'GenericForStatement' then
			assert(stat.scope.parent == scope) --[[SOL OUTPUT--]] 

			if #stat.generators > 1 then
				report_warning(stat, "Sol currently only support one generator") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local types = extract_iterator_type( stat.generators[1], scope ) --[[SOL OUTPUT--]] 

			if types ~= T.AnyTypeList then
				if #types ~= #stat.var_names then
					report_error(stat, "Expected %i variables", #types) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			for i = 1,#stat.var_names do
				local v = declare_local(stat, stat.scope, stat.var_names[i]) --[[SOL OUTPUT--]] 
				if types ~= T.AnyTypeList then
					v.type = types[i] --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local ret = analyze_statlist(stat.body, stat.scope, scope_fun) --[[SOL OUTPUT--]] 
			return ret --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'NumericForStatement' then
			assert(stat.scope.parent == scope) --[[SOL OUTPUT--]] 

			local function check_num_arg(what, t)
				if not T.isa(t, T.Num) then
					report_error(stat, "Numeric for loop expected numeric %s, got %s", what, t) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local start_t = analyze_expr_single(stat.start, stat.scope) --[[SOL OUTPUT--]] 
			local end_t   = analyze_expr_single(stat.end_, stat.scope) --[[SOL OUTPUT--]] 

			check_num_arg('start', start_t) --[[SOL OUTPUT--]] 
			check_num_arg('end',   end_t) --[[SOL OUTPUT--]] 

			local iter_t = T.combine(start_t, end_t) --[[SOL OUTPUT--]] 

			if stat.step then
				local step_t   = analyze_expr_single(stat.step, stat.scope) --[[SOL OUTPUT--]] 
				check_num_arg('step', step_t) --[[SOL OUTPUT--]] 
				iter_t = T.combine(iter_t, step_t) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local iter_var = declare_local(stat, stat.scope, stat.var_name) --[[SOL OUTPUT--]] 
			iter_var.type = iter_t --[[SOL OUTPUT--]] 
			
			local ret = analyze_statlist(stat.body, stat.scope, scope_fun) --[[SOL OUTPUT--]] 
			return ret --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'LabelStatement' then

		elseif stat.ast_type == 'GotoStatement' then

		elseif stat.ast_type == 'Eof' then

		elseif stat.ast_type == 'Typedef' then
			analyze_typedef( stat, scope ) --[[SOL OUTPUT--]] 

		else
			print("Unknown AST type: ", stat.ast_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return nil --[[SOL OUTPUT--]]    -- Returns nothing
	end --[[SOL OUTPUT--]] 


	local function pre_analyze_statement(stat, scope)
		local is_pre_analyze = true --[[SOL OUTPUT--]] 

		if stat.ast_type == 'Typedef' then
			--analyze_typedef( stat, scope )

		elseif stat.ast_type == 'VarDeclareStatement' then
			-- HACK for forward-declaring namespaces:
			if true then
				for _,name in ipairs(stat.name_list) do
					local is_local = (stat.type ~= 'global') --[[SOL OUTPUT--]] 
					local v = declare_var(stat, scope, name, is_local) --[[SOL OUTPUT--]] 
					v.forward_declared = true --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				if #stat.name_list == 1 and #stat.init_list == 1 then
					local init = stat.init_list[1] --[[SOL OUTPUT--]] 
					if init.ast_type == 'ConstructorExpr' then
						if #init.entry_list == 0 then
							-- {}
							local is_local = (stat.type ~= 'global') --[[SOL OUTPUT--]] 
							local v = declare_var(stat, scope, stat.name_list[1], is_local) --[[SOL OUTPUT--]] 
							v.forward_declared = true --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'AssignmentStatement' then
			-- Could be a    foo = function( ... )   where foo has been forward declared earlier without a type

			if #stat.lhs == 1 and #stat.rhs == 1 then
				if stat.lhs[1].ast_type == 'IdExpr' then
					if stat.rhs[1].ast_type == 'LambdaFunctionExpr' then
						--do_assignment(stat, scope, stat.lhs[1], fun_t)

						local var_name = stat.lhs[1].name --[[SOL OUTPUT--]] 

						local v = nil --[[SOL OUTPUT--]] 

						if true then
							v = scope:get_var( var_name ) --[[SOL OUTPUT--]] 

							if v then
								-- Assigning to something declared in an outer scope
							else
								-- Leave error reporting out of pre-analyzer
								--v = scope:create_local( var_name, where_is(stat) )
								--v.forward_declared = true
								return --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						else
							v = scope:get_var( var_name ) --[[SOL OUTPUT--]] 
							if not v then
								report_error(stat, "Implicit global '%s'", var_name) --[[SOL OUTPUT--]] 
								v = scope:create_global( var_name, where_is(stat) ) --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					
						if v.type then
							report_error(stat, "Cannot forward declare '%s': it already has type '%s'", v.name, v.type) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						local fun_t = analyze_function_head( stat.rhs[1], scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
						fun_t.pre_analyzed = true --[[SOL OUTPUT--]]  -- Rmember that this is a temporary 'guess'

						v.type = fun_t --[[SOL OUTPUT--]] 

						report_spam(stat, "Forward-declared '%s' as '%s'", v.name, fun_t) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'FunctionDeclStatement' then
			assert(stat.scope.parent == scope) --[[SOL OUTPUT--]] 

			if stat.name then
				report_spam(stat, "Pre-analyzing function %s...", stat.name) --[[SOL OUTPUT--]] 
			else
				return --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local fun_t = analyze_function_head( stat, scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
			fun_t.pre_analyzed = true --[[SOL OUTPUT--]]  -- Rmember that this is a temporary 'guess'
			if stat.var_name then
				fun_t.name = stat.var_name --[[SOL OUTPUT--]] 
			else
				fun_t.name = 'its_complicated' --[[SOL OUTPUT--]]  -- TODO
			end --[[SOL OUTPUT--]] 

			if stat.is_local then
				-- e.g.  "local function foo(bar)"
				report_warning(stat, "TODO: local function, name: %q", stat.name) --[[SOL OUTPUT--]] 
			else
				-- function foo(arg)      -- global - not OK
				-- or
				-- function foo.bar(arg)  -- namespaced - OK
				-- function foo:bar(arg)  -- member - OK
				if stat.name.ast_type ~= 'MemberExpr' then
					-- e.g.  "function foo(bar)"
					report_warning(stat, "global function, name: %q", stat.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				report_spam(stat, "Pre-analyzed function head for %q as '%s'", stat.name, fun_t) --[[SOL OUTPUT--]] 

				do_assignment(stat, scope, stat.name, fun_t, is_pre_analyze) --[[SOL OUTPUT--]] 

				report_spam(stat, "Assigned.") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Returns the list of types returned in these statements
	-- or nil if no returns statements where found
	analyze_statlist = function(stat_list, scope, scope_fun)
		assert(stat_list) --[[SOL OUTPUT--]] 
		assert(scope) --[[SOL OUTPUT--]] 
		local return_types = nil --[[SOL OUTPUT--]] 

		local list_scope = stat_list.scope --[[SOL OUTPUT--]] 
		--assert(list_scope.parent == scope)
		assert(list_scope) --[[SOL OUTPUT--]] 

		-- Look for function declarations:
		-- This is so that we don't need to forward-declare function
		-- like we have to in lesser languages.

		for _, stat in ipairs(stat_list.body) do
			pre_analyze_statement(stat, list_scope) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 


		-- end_
		for _, stat in ipairs(stat_list.body) do
			local stat_rets = analyze_statement(stat, list_scope, scope_fun) --[[SOL OUTPUT--]] 
			return_types = T.combine_type_lists(return_types, stat_rets) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return return_types --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local top_scope = ast.scope --[[SOL OUTPUT--]]   -- HACK
	local module_function = {
		tag = "function",
		args = {}
		-- name = ???
		-- rets = ???
	} --[[SOL OUTPUT--]] 
	local ret = analyze_statlist(ast, top_scope, module_function) --[[SOL OUTPUT--]] 

	if _G.g_ignore_errors or error_count == 0 then
		return true, ret --[[SOL OUTPUT--]] 
	else
		return false, string.format("%i errors", error_count) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return analyze --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 