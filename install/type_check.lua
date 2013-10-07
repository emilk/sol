--[[ DO NOT MODIFY - COMPILED FROM sol/type_check.sol on 2013 Oct 07  22:08:42 --]] local U   = require 'util' --[[SOL OUTPUT--]] 
local set = U.set --[[SOL OUTPUT--]] 
local T   = require 'type' --[[SOL OUTPUT--]] 
local P   = require 'parser' --[[SOL OUTPUT--]] 
local S   = require 'scope' --[[SOL OUTPUT--]] 
local D   = require 'sol_debug' --[[SOL OUTPUT--]] 


local NumOps = {
	['+'] = '__add',
	['-'] = '__sub',
	['*'] = '__mul',
	['/'] = '__div',
	['%'] = '__mod',
	['^'] = '__pow',
} --[[SOL OUTPUT--]] 
local NumCompOps = set{
	'<', '<=', '>', '>='
} --[[SOL OUTPUT--]] 


local function rope_to_msg(rope)
	local str = U.trim( table.concat(rope, '\n') ) --[[SOL OUTPUT--]] 
	if str == '' then
		return str --[[SOL OUTPUT--]] 
	else
		return U.quote_or_indent(str) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

local function loose_lookup(table, id)
	if true then
		return nil --[[SOL OUTPUT--]] 
	else
		D.assert(type(id) == 'string') --[[SOL OUTPUT--]] 

		if table[id] then
			return id --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local MAX_DIST = 2 --[[SOL OUTPUT--]] 

		if #id < MAX_DIST then
			-- Don't suggest 'x' over 'y'
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local edit_distance = require 'edit_distance' --[[SOL OUTPUT--]] 

		local closest_dist = math.huge --[[SOL OUTPUT--]] 
		local closest_key  = nil --[[SOL OUTPUT--]] 

		for k,_ in pairs(table) do
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
end --[[SOL OUTPUT--]] 


local function expr2str(e) 
	local ignore_set = U.set{'var_', 'scope', 'tokens'} --[[SOL OUTPUT--]] 
	return U.serialize(e, ignore_set) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function format_expr(e)
	local output = require 'output' --[[SOL OUTPUT--]] 
	local strip_white_space = true --[[SOL OUTPUT--]] 
	local str = output(e, '', strip_white_space) --[[SOL OUTPUT--]] 
	str = U.trim(str) --[[SOL OUTPUT--]] 
	return str --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 





local function analyze(ast, filename, on_require, settings)
	local analyze_statlist, analyze_expr, analyze_expr_single_var, analyze_expr_single --[[SOL OUTPUT--]] 
	local analyze_expr_unchecked --[[SOL OUTPUT--]] 

	local top_scope = ast.scope --[[SOL OUTPUT--]]   -- HACK
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
				a = U.quote_or_indent( format_expr(a) ) --[[SOL OUTPUT--]] 
			elseif T.is_type(a) then
 				a = U.quote_or_indent( T.name(a) ) --[[SOL OUTPUT--]] 
			elseif T.is_type_list(a) then
				a = U.quote_or_indent( T.names(a) ) --[[SOL OUTPUT--]] 
			elseif type( a ) ~= 'string' and type( a ) ~= 'number' then
				-- bool/table
				a = tostring( a ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			buf[i] = a --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local str = U.trim( string.format( fmt, unpack( buf ) ) ) --[[SOL OUTPUT--]] 

		if U.count_line_breaks(str) == 0 then
			return str --[[SOL OUTPUT--]] 
		else
			return str..'\n' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report(type, where, fmt, ...)
		local inner_msg = fancy_format(fmt, ...) --[[SOL OUTPUT--]] 
		local msg = string.format('%s: %s: %s', type, where, inner_msg) --[[SOL OUTPUT--]] 
		return msg --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_spam(node, fmt, ...)
		if _G.g_spam then
			print( report('Spam', where_is(node), fmt, ...) ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_info(node, fmt, ...)
		print( report('Info', where_is(node), fmt, ...) ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_error(node, fmt, ...)
		if settings.is_sol then
			U.printf_err( "%s", report('ERROR', where_is(node), fmt, ...) ) --[[SOL OUTPUT--]] 
			error_count = error_count + 1 --[[SOL OUTPUT--]] 
		else
			-- Forgive lua code
			print( report('WARNING', where_is(node), fmt, ...) ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_warning(node, fmt, ...)
		if _G.g_warnings_as_errors then
			report_error(node, fmt, ...) --[[SOL OUTPUT--]] 
		else
			print( report('WARNING', where_is(node), fmt, ...) ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function report_solc_todo(node, fmt, ...)
		--print( report('SOLC_TODO', where_is(node), fmt, ...) )
	end --[[SOL OUTPUT--]] 

	local function sol_warning(node, fmt, ...)
		if settings.is_sol then
			report_warning(node, fmt, ...) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function sol_error(node, fmt, ...)
		if settings.is_sol then
			report_error(node, fmt, ...) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function inform_at(issue_name, where, fmt, ...)
		local level = settings.issues[issue_name] --[[SOL OUTPUT--]] 
		assert(level) --[[SOL OUTPUT--]] 
		if level ~= 'SPAM' or _G.g_spam then
			print( report(level, where, fmt, ...)) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function inform(issue_name, node, fmt, ...)
		return inform_at(issue_name, where_is(node), fmt, ...) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--local member_missing_reporter = report_warning -- TODO
	local member_missing_reporter = report_spam --[[SOL OUTPUT--]] 

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



	local function discard_scope(scope)
		for _,v in scope:locals_iterator() do
			if v.name ~= '_' then
				local var_type = v.var_type or 'Variable' --[[SOL OUTPUT--]] 
				if v.num_reads == 0 then
					if v.type and v.type.tag == 'function' then
						print( report('WARNING', v.where, "Unused function %q", v.name) ) --[[SOL OUTPUT--]] 
					else
						local var_type_to_warning_name = {
							['Argument']      = 'unused-parameter';
							['Loop variable'] = 'unused-loop-variable';
						} --[[SOL OUTPUT--]] 
						local issue_name = var_type_to_warning_name[var_type] or 'unused-variable' --[[SOL OUTPUT--]] 
						
						inform_at(issue_name , v.where, "%s %q is never read (use _ to silence this warning)", var_type, v.name) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if v.num_writes == 0 then
					inform_at('unassigned-variable' , v.where, "%s %q is never written to (use _ to silence this warning)", var_type, v.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- second bool: returns true if all paths returns
	local function analyze_closed_off_statlist(stat_list, scope_fun)
		return analyze_statlist(stat_list, stat_list.scope, scope_fun) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 



	local function declare_local(node, scope, name, typ)
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		local old = scope:get_scoped(name) --[[SOL OUTPUT--]] 

		if old and old.forward_declared then
			old.forward_declared = false --[[SOL OUTPUT--]]  -- Properly declared now
			-- TODO: move to proper scope!
			assert(not old.is_global) --[[SOL OUTPUT--]] 
			assert(old.scope == scope) --[[SOL OUTPUT--]] 
			old.where = where_is(node) --[[SOL OUTPUT--]]  -- Update position of forward-declare
			old.type  = typ or old.type --[[SOL OUTPUT--]] 
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if old then
			if name ~= "st" and name ~= "_" then  -- HACK
				report_error(node, "%q already declared in this scope, in %s", name, old.where) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		report_spam(node, "Declaring local %q", name) --[[SOL OUTPUT--]] 
		local v = scope:create_local(name, where_is(node)) --[[SOL OUTPUT--]] 
		v.type = typ --[[SOL OUTPUT--]] 
		return v --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function declare_global(node, scope, name, typ)
		D.assert(type(name) == 'string') --[[SOL OUTPUT--]] 
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		if name ~= '_' then
			if not scope:is_module_level() then
				sol_error(node, "Global variables should be declared in the top scope") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local old = scope:get_var(name) --[[SOL OUTPUT--]] 

		if old and old.forward_declared then
			old.forward_declared = false --[[SOL OUTPUT--]]  -- Properly declared now
			-- TODO: move to proper scope!
			assert(old.is_global) --[[SOL OUTPUT--]] 
			assert(old.scope == scope) --[[SOL OUTPUT--]] 
			old.where = where_is(node) --[[SOL OUTPUT--]]  -- Update position of forward-declare
			old.type  = typ or old.type --[[SOL OUTPUT--]] 
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if old then
			report_error(node, "global %q already declared in %s", name, old.where) --[[SOL OUTPUT--]] 
			return old --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		report_spam(node, "Declaring global %q", name) --[[SOL OUTPUT--]] 
		return scope:create_global(name, where_is(node), typ) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function declare_var(node, scope, name, is_local, typ)
		if is_local then
			return declare_local(node, scope, name, typ) --[[SOL OUTPUT--]] 
		else
			return declare_global(node, scope, name, typ) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function check_type_is_a(msg, expr, expr_type, expected_type, severity)
		if T.could_be(expr_type, expected_type) then
			return true --[[SOL OUTPUT--]] 
		else
			local error_rope = {} --[[SOL OUTPUT--]] 
			T.could_be(expr_type, expected_type, error_rope) --[[SOL OUTPUT--]] 
			local error_msg = rope_to_msg(error_rope) --[[SOL OUTPUT--]] 
			local reporter = (severity == 'error' and report_error or report_warning) --[[SOL OUTPUT--]] 
			reporter(expr, "%s: Expected type %s, got %s: %s", msg, T.name(expected_type), T.name(expr_type), error_msg) --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	analyze_expr = function(expr, scope)
		local types, var_ = analyze_expr_unchecked(expr, scope) --[[SOL OUTPUT--]] 

		D.assert(T.is_type_list(types)) --[[SOL OUTPUT--]] 

		return types, var_ --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Will make sure to return a single type, never void or multiple returns
	analyze_expr_single_var = function(expr, scope)
		local t,v = analyze_expr(expr, scope) --[[SOL OUTPUT--]] 
		if t == T.AnyTypeList then
			return T.Any, v --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if #t == 0 then
			report_error(expr, "Analyzing '%s' expression: Expected type, got void", expr.ast_type) --[[SOL OUTPUT--]] 
			return T.Any, v --[[SOL OUTPUT--]] 
		elseif #t == 1 then
			return t[1], v --[[SOL OUTPUT--]] 
		else
			report_error(expr, "When analyzing '%s' expression: Expected single type, got: %s", expr.ast_type, t) --[[SOL OUTPUT--]] 
			return T.Any, v --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	analyze_expr_single = function(expr, scope)
		-- Ignore the variable
		local t,_ = analyze_expr_single_var(expr, scope) --[[SOL OUTPUT--]] 
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function check_return_types(node, does_return, should_return)
		if should_return then
			assert(T.is_type_list(does_return)) --[[SOL OUTPUT--]] 
			assert(T.is_type_list(should_return)) --[[SOL OUTPUT--]] 

			if not T.could_be_tl(does_return, should_return) then
				local problem_rope = {} --[[SOL OUTPUT--]] 
				T.could_be_tl(does_return, should_return, problem_rope) --[[SOL OUTPUT--]] 
				local problem_str = rope_to_msg(problem_rope) --[[SOL OUTPUT--]] 
				report_error(node, "Return statement does not match function return type declaration, returns: %s, expected: %s.\n%s", does_return, should_return, problem_str) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_expr_single_custom(expr, scope, is_pre_analyze)
		if is_pre_analyze then
			if expr.ast_type == 'IdExpr' then
				local base_var = scope:get_var( expr.name ) --[[SOL OUTPUT--]] 

				if base_var then
					return base_var.type or T.Any, base_var --[[SOL OUTPUT--]] 
				else
					report_error(expr, "Pre-analyzer: Unknown identifier %q", expr.name) --[[SOL OUTPUT--]] 
					return T.Any, nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			else
				return T.Any, nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			return analyze_expr_single_var(expr, scope) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	 
	-- analyze a function declaration head - either a named one or a lambda function
	local analyze_function_head = function(node, scope, is_pre_analyze)
		assert(node.return_types == nil or T.is_type_list(node.return_types)) --[[SOL OUTPUT--]] 

		local fun_t = {
			tag = 'function',
			args = {},
			rets = node.return_types  -- If any
		} --[[SOL OUTPUT--]] 

		if node.is_mem_fun then
			local name_expr = node.name_expr --[[SOL OUTPUT--]] 
			assert(name_expr.ast_type == 'MemberExpr' and name_expr.indexer == ':') --[[SOL OUTPUT--]] 
			local self_type,_ = analyze_expr_single_custom(name_expr.base, scope, is_pre_analyze) --[[SOL OUTPUT--]] 
			if self_type.instance_type then
				report_spam(node, "Class method detected - setting 'self' type as the instance type") --[[SOL OUTPUT--]] 
				self_type = self_type.instance_type --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			table.insert(fun_t.args, {name = 'self', type = self_type}) --[[SOL OUTPUT--]] 

			node.self_var_type = self_type --[[SOL OUTPUT--]]   -- Assign a type to the local 'self' variable

			--report_spam(node, "self: '%s'", self_type)
		end --[[SOL OUTPUT--]] 

		for _,arg in ipairs(node.arguments) do
			table.insert(fun_t.args, {name = arg.name, type = arg.type or T.Any}) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if node.vararg then
			fun_t.vararg = node.vararg --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--report_spam(node, "analyze_function_head: %s", fun_t)

		return fun_t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--[[ Will analyze body and check its return-statements against fun_t.
	     If fun_t.rets is nil (no type deduced) then this function will fill it in via deduction.
	--]]
	local function analyze_function_body(node, _, fun_t)
		if not node.body then
			-- body-less function - used by lua_intrinsics.sol
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local func_scope = node.scope --[[SOL OUTPUT--]] 

		-- Declare arguments as variables:
		if node.is_mem_fun then
			assert(node.self_var_type) --[[SOL OUTPUT--]]  -- Set by analyze_function_head
			local v = declare_local(node, func_scope, 'self') --[[SOL OUTPUT--]] 
			v.type = node.self_var_type --[[SOL OUTPUT--]] 
			v.num_writes = 1 --[[SOL OUTPUT--]] 
			v.num_reads  = 1 --[[SOL OUTPUT--]]   -- It must have been for the function to be found (silences warnings)
			v.var_type = 'Argument' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		for _,arg in ipairs(node.arguments) do
			local v = declare_local(node, func_scope, arg.name) --[[SOL OUTPUT--]] 
			v.type = arg.type --[[SOL OUTPUT--]] 
			v.num_writes = 1 --[[SOL OUTPUT--]] 
			v.var_type = 'Argument' --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if node.vararg then
			local v = declare_local(node, func_scope, '...') --[[SOL OUTPUT--]] 
			v.type = node.vararg --[[SOL OUTPUT--]] 
			v.num_writes = 1 --[[SOL OUTPUT--]] 
			v.var_type = 'Argument' --[[SOL OUTPUT--]] 
			assert(T.is_type(v.type)) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		---

		local ret_t, all_paths_return = analyze_statlist(node.body, func_scope, fun_t) --[[SOL OUTPUT--]] 
		discard_scope(func_scope) --[[SOL OUTPUT--]] 

		if fun_t.rets then
			if ret_t and not T.could_be_tl(ret_t, fun_t.rets) then
				report_error(node, "Return statement(s) does not match function return type declaration, returns: %s, expected: %s",
					T.name(ret_t), T.name(fun_t.rets)) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if not T.is_void(fun_t.rets) and fun_t.rets ~= T.AnyTypeList and not all_paths_return then
				report_error(node, "Not all code paths return a value - expected %s", fun_t.rets) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			-- Deduce return type:
			if ret_t then
				if not T.is_void(ret_t) and ret_t ~= T.AnyTypeList and not all_paths_return then
					report_error(node, "Not all code paths return a value, but some return %s", ret_t) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if not all_paths_return and #ret_t > 0 then
					ret_t = U.shallow_clone(ret_t) --[[SOL OUTPUT--]] 
					for ix,_ in ipairs(ret_t) do
						ret_t[ix] = T.make_nilable(ret_t[ix]) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				fun_t.rets = ret_t --[[SOL OUTPUT--]] 
			else
				fun_t.rets = T.Void --[[SOL OUTPUT--]]   -- No returns  == void
			end --[[SOL OUTPUT--]] 
			--report_spam(node, 'function deduced return type: %s', fun_t.rets)
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function check_arguments(expr, fun_t, arg_ts)
		assert(fun_t.args) --[[SOL OUTPUT--]] 
		assert(fun_t.name) --[[SOL OUTPUT--]] 
		local fun_name = fun_t.name --[[SOL OUTPUT--]] 
		D.assert(type(fun_name) == 'string', "fun_name: %s", fun_name) --[[SOL OUTPUT--]] 
		local all_passed = false --[[SOL OUTPUT--]] 

		-- check arguments:
		local i = 1 --[[SOL OUTPUT--]] 
		while true do
			--report_spam(expr, "Checking argument %i", i)

			if i <= #fun_t.args then
				if fun_t.args[i].name == 'self' and i ~= 1 then
					report_error(expr, "%s: 'self' must be the first argument", fun_name) --[[SOL OUTPUT--]] 
					all_passed = false --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local expected = fun_t.args[i].type --[[SOL OUTPUT--]] 

				if i == #arg_ts and arg_ts[i].tag == 'varargs' then
					-- When calling with ..., if ... is empty we get nil:s
					local given = T.variant(arg_ts[i].type, T.Nil) --[[SOL OUTPUT--]] 

					-- check against the remaining expected types:
					while i <= #fun_t.args do
						local expected = fun_t.args[i].type --[[SOL OUTPUT--]] 

						if not T.could_be(given, expected) then
							local problem_rope = {} --[[SOL OUTPUT--]] 
							T.could_be(given, expected, problem_rope) --[[SOL OUTPUT--]] 
							local err_msg = rope_to_msg(problem_rope) --[[SOL OUTPUT--]] 
							report_error(expr, "%s: var-arg argument %i: could not convert from %s to %s: %s",
							                    fun_name, i, given, expected, err_msg) --[[SOL OUTPUT--]] 
							all_passed = false --[[SOL OUTPUT--]] 
							break --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						i = i + 1 --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					break --[[SOL OUTPUT--]] 

				elseif i <= #arg_ts then
					local given = arg_ts[i] --[[SOL OUTPUT--]] 

					if given.tag == 'varargs' then
						report_error(expr, "Var-args must be the last argument") --[[SOL OUTPUT--]] 
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
						local err_msg = rope_to_msg(problem_rope) --[[SOL OUTPUT--]] 
						report_error(expr, "%s: argument %i: could not convert from %s to %s: %s",
						                    fun_name, i, given, expected, err_msg) --[[SOL OUTPUT--]] 
						all_passed = false --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					if i == 1 and fun_t.args[i].name == 'self' then
						report_error(expr, "%s: Missing object argument ('self'). Did you forget to call with : ?", fun_name) --[[SOL OUTPUT--]] 
						all_passed = false --[[SOL OUTPUT--]] 
					elseif not T.is_nilable(expected) then
						report_error(expr, "%s: Missing non-nilable argument %i: expected %s", fun_name, i, expected) --[[SOL OUTPUT--]] 
						all_passed = false --[[SOL OUTPUT--]] 
					elseif _G.g_spam then
						report_spam(expr, "%s: Ignoring missing argument %i: it's nilable: %s", fun_name, i, expected) --[[SOL OUTPUT--]] 
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

					report_spam(expr, "Check varargs. Given: %s, expected %s", given, expected) --[[SOL OUTPUT--]] 

					if given.tag == 'varargs' then
						given = given.type --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if not T.could_be(given, expected) then
						report_error(expr, "%s: argument %i: could not convert from %s to varargs %s",
							                 fun_name, i, given, expected) --[[SOL OUTPUT--]] 
						all_passed = false --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					report_error(expr, "%s: Too many arguments - got %i, expected %i", fun_name, #arg_ts, #fun_t.args) --[[SOL OUTPUT--]] 
					all_passed = false --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				break --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			i = i + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return all_passed --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function try_match_index(node, index_top, member)
		D.assert(T.is_type(index_top)) --[[SOL OUTPUT--]] 
		return T.visit_and_combine(index_top, function(index)
			index = T.follow_identifiers(index) --[[SOL OUTPUT--]] 

			if index.tag == 'function' then
				report_spam(node, "metatable has __index function") --[[SOL OUTPUT--]] 
				-- First member is the 'self'

				-- e.g. index only accepts "x" or "y" or "z"
				-- Ignoring mis-matches gives much better error messages

				local indexer_fun = index --[[SOL OUTPUT--]] 
				if #indexer_fun.args == 2 then
					local expected_t = indexer_fun.args[2].type --[[SOL OUTPUT--]] 
					if not T.isa(member, expected_t) then
						return nil --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					if not check_arguments(node, indexer_fun, { T.Any, member }) then
						return nil --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if indexer_fun.rets and #indexer_fun.rets > 0 then
					return indexer_fun.rets[1] --[[SOL OUTPUT--]] 
				else
					-- TODO: warnings should be written on __index set
					report_error(node, "Unexpected __index function - no returns values") --[[SOL OUTPUT--]] 
					return T.Any --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif index.tag == 'map' then
				-- Vector3.__index = extern : { 'x' or 'y' or 'z' or 1 or 2 or 3  =>  number }
				if T.isa(member, index.value_type) then
					return index.key_type --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			end --[[SOL OUTPUT--]] 

			return nil --[[SOL OUTPUT--]] 
		end) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function do_member_lookup(node, start_type, name, suggestions)
		return T.visit_and_combine(start_type, function(type)
			if type.tag == 'object' then
				local obj = type --[[SOL OUTPUT--]] 
				local member_type = obj.members[name] --[[SOL OUTPUT--]] 

				if not member_type and obj.class_type then
					member_type = do_member_lookup(node, obj.class_type, name, suggestions) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if not member_type and obj.metatable then
					local index = obj.metatable.members['__index'] --[[SOL OUTPUT--]] 

					if index then
						local given_t = {tag='string_literal', value=name} --[[SOL OUTPUT--]] 
						local t = try_match_index(node, index, given_t) --[[SOL OUTPUT--]] 

						if t then
							return t --[[SOL OUTPUT--]] 
						else
							report_spam(node, "Looking up member %q in metatbale __index", name) --[[SOL OUTPUT--]] 
							return do_member_lookup(node, index, name, suggestions) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				member_type = T.broaden( member_type ) --[[SOL OUTPUT--]]  -- Previous value may have been 'false' - we should allow 'true' now:

				if obj.derived then
					for _,v in ipairs(obj.derived) do
						member_type = T.variant(member_type, do_member_lookup(node, v, name, suggestions)) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if suggestions and not member_type then
					local close_name = loose_lookup(obj.members, name) --[[SOL OUTPUT--]] 

					if close_name then
						suggestions[#suggestions + 1] = close_name --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				return member_type --[[SOL OUTPUT--]] 

			--elseif T.isa(type, T.String) then
			elseif type == T.String or type.tag == 'string_literal' then
				-- TODO:  'example':upper()
				return T.Any --[[SOL OUTPUT--]] 

			--elseif T.is_any(type) then
			elseif type == T.Any then
				return T.Any --[[SOL OUTPUT--]] 

			else
				return nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end) --[[SOL OUTPUT--]] 
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
						if typ.value_type == T.True then
							-- A set!
							return { typ.key_type } --[[SOL OUTPUT--]] 
						else
							return { typ.key_type, typ.value_type } --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
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
						if error_rope then
							table.insert(error_rope, string.format("Incompatible type: '%s'", T.name(typ))) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						return nil --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				local types = pairs_type( arg_ts[1] ) --[[SOL OUTPUT--]] 
				if types then
					assert(#types == 2) --[[SOL OUTPUT--]] 
					return types --[[SOL OUTPUT--]] 
				else
					local error_rope = {} --[[SOL OUTPUT--]] 
					pairs_type( arg_ts[1], error_rope ) --[[SOL OUTPUT--]] 
					report_error(expr, "'pairs' called on incompatible type: " .. rope_to_msg(error_rope)) --[[SOL OUTPUT--]] 
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
						sol_warning(expr, "Calling 'ipairs' on unknown table") --[[SOL OUTPUT--]] 
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
					report_error(expr, "'ipairs' called on incompatible type: " .. rope_to_msg(error_rope)) --[[SOL OUTPUT--]] 
					return { T.Uint, T.Any } --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--------------------------------------------------------

		return T.AnyTypeList --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_require( module_name, req_where )
		return T.as_type_list( on_require( module_name, req_where ) ) --[[SOL OUTPUT--]]   -- TODO: remove as_type_list
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
			report_warning(expr, "setmetatable: first argument should name an object; got: %s", target_type) --[[SOL OUTPUT--]] 
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if not T.should_extend_in_situ(target_type) then
			target_type = U.shallow_clone(target_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		target_type.metatable = arg_ts[2] --[[SOL OUTPUT--]] 

		report_spam(expr, "Setting metatable") --[[SOL OUTPUT--]] 

		target_var.type = target_type --[[SOL OUTPUT--]] 

		--report_info(expr, "setmetatable: %s", target_type)
	end --[[SOL OUTPUT--]] 


	local function analyze_fun_call(expr, typ, args, arg_ts, report_errors)
		report_spam(expr, "analyze_fun_call, typ: %s", typ) --[[SOL OUTPUT--]] 
		report_spam(expr, "analyze_fun_call, arg_ts: %s", arg_ts) --[[SOL OUTPUT--]] 

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
				report_error(expr, "Not a function: %s", typ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local fun_t = typ --[[SOL OUTPUT--]] 
		D.assert(fun_t.name) --[[SOL OUTPUT--]] 

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

			local ret = {
				tag    = 'function',
				args   = {},
				vararg = { tag='varargs', type=T.Any },
				rets   = it_types,
				name   = '<pairs/ipairs iterator>',
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


	local function try_calling(expr, fun_type, args, arg_ts, called_as_mem_fun, report_errors)
		--------------------------------------------------------
		-- Do we know the function type?

		local function try_call(typ, report_errors)
			typ = T.follow_identifiers(typ) --[[SOL OUTPUT--]] 

			if T.is_any(typ) then
				-- TODO: Upgrade to a warning!
				report_spam(expr, "Function call cannot be deduced - calling something of unknown type: %s", fun_type) --[[SOL OUTPUT--]] 
				return T.AnyTypeList --[[SOL OUTPUT--]] 

			elseif typ.tag == 'function' then
				local fun_t = typ --[[SOL OUTPUT--]] 
				local is_mem_fun = (#fun_t.args > 0 and fun_t.args[1].name == 'self') --[[SOL OUTPUT--]] 

				if called_as_mem_fun and not is_mem_fun then
					report_error(expr, "Calling non-member function as member function") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if not called_as_mem_fun and is_mem_fun then
					local first_is_self = (#args>0 and args[1].ast_type == 'IdExpr' and args[1].name == 'self') --[[SOL OUTPUT--]] 
					if first_is_self then
						-- Foo.bar(self)  is considered calling is as a member function
					else
						report_warning(expr, "Member function called as non-member function") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
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
				report_error(expr, "Cannot call %s of type %s", expr, typ) --[[SOL OUTPUT--]] 
				return nil --[[SOL OUTPUT--]] 
			else
				return nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local rets = try_call(fun_type, report_errors) --[[SOL OUTPUT--]] 
		return rets --[[SOL OUTPUT--]] 
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
		for ix,v in ipairs(args) do
			if ix < #args then
				arg_ts[ix] = analyze_expr_single(v, scope) --[[SOL OUTPUT--]] 
			else
				-- Last argument may evaluate to several values
				local types, _ = analyze_expr(v, scope) --[[SOL OUTPUT--]] 
				if types == T.AnyTypeList then
					arg_ts[ix] = { tag = 'varargs', type = T.Any } --[[SOL OUTPUT--]] 
				elseif #types == 0 then
					report_error(expr, "Last argument evaluates to no values") --[[SOL OUTPUT--]] 
				else
					for _,t in ipairs(types) do
						table.insert(arg_ts, t) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local rets = try_calling(expr, fun_type, args, arg_ts, called_as_mem_fun, false) --[[SOL OUTPUT--]] 

		if rets then
			report_spam(expr, "Function deduced to returning: %s", rets) --[[SOL OUTPUT--]] 
			D.assert( T.is_type_list(rets) ) --[[SOL OUTPUT--]] 
			return rets --[[SOL OUTPUT--]] 
		else
			report_error(expr, "Expected %s to be a fucntion, got %s", expr.base, fun_type) --[[SOL OUTPUT--]] 
			try_calling(expr, fun_type, args, arg_ts, called_as_mem_fun, true) --[[SOL OUTPUT--]]  -- Report errors
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	--[[
	Will look for the meta-method 'name'.
	If found, will match arguments and return the type that it returns, or default_ret if no returns.
	Returns nil on no mm found
	--]]
	local function try_metamethod(expr, t, name, args, arg_ts, default_ret)
		local mm = T.find_meta_method(t, name) --[[SOL OUTPUT--]] 
		if mm then
			local rets = try_calling(expr, mm, args, arg_ts, false, false) --[[SOL OUTPUT--]] 
			if rets then
				if #rets == 1 then
					return rets[1] --[[SOL OUTPUT--]] 
				else
					report_error(expr, "Bad metamethod %q: expected only one return type", name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return default_ret --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- for k,v in some_expr
	-- this functions returns a list of types for k,v in the example above
	local function extract_iterator_type(expr, scope)
		report_spam(expr, "extract_iterator_type...") --[[SOL OUTPUT--]] 

		--[-[
		local types, _ = analyze_expr(expr, scope) --[[SOL OUTPUT--]] 
		if types == T.AnyTypeList then
			-- e.g.   for line in src:gmatch("[^\n]*\n?") do
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		local gen_t = types[1] --[[SOL OUTPUT--]] 
		--]]	
		--local gen_t = analyze_expr_single(expr, scope) -- TODO: var

		D.assert(gen_t) --[[SOL OUTPUT--]] 

		report_spam(expr, "extract_iterator_type, gen_t: %s", gen_t) --[[SOL OUTPUT--]] 

		gen_t = T.follow_identifiers(gen_t) --[[SOL OUTPUT--]] 
		if gen_t == T.Any then
			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if gen_t.tag ~= 'function' then
			local suggestion = 'pairs' --[[SOL OUTPUT--]] 
			if T.isa(gen_t, T.List) then
				suggestion = 'ipairs' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			report_error(expr, "Generator function expected, got %s - did you forget to use '%s'?", gen_t, suggestion) --[[SOL OUTPUT--]] 

			return T.AnyTypeList --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local fun_t = gen_t --[[SOL OUTPUT--]] 

		local arg_ts = {} --[[SOL OUTPUT--]] 
		for i = 2,#types do
			arg_ts[i-1] = types[i] --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		check_arguments(expr, fun_t, arg_ts) --[[SOL OUTPUT--]] 

		return fun_t.rets or T.AnyTypeList --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 



	local analyze_simple_expr_unchecked --[[SOL OUTPUT--]] 


	analyze_expr_unchecked = function(expr, scope)
		assert(expr) --[[SOL OUTPUT--]] 
		assert(type(expr) == 'table') --[[SOL OUTPUT--]] 
		assert(expr.ast_type) --[[SOL OUTPUT--]] 

		report_spam(expr, "Analyzing %s...", expr.ast_type) --[[SOL OUTPUT--]] 


		if expr.ast_type == 'IdExpr' then
			if expr.name == '_' then
				report_error(expr, "You may not read from discard variable '_'") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local var_ = scope:get_var( expr.name, 'ignore_fwd_decl' ) --[[SOL OUTPUT--]] 

			if var_ then
				if var_.forward_declared then
					report_error(expr, "Use of forward-declared variable %q, forward-declared in %s",
						expr.name, var_.where) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				var_.num_reads = var_.num_reads + 1 --[[SOL OUTPUT--]] 
			else
				if expr.name ~= '_' then  -- Implicit '_' var is OK
					report_error(expr, "Implicit global %q", expr.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				var_ = top_scope:create_global( expr.name, where_is(expr) ) --[[SOL OUTPUT--]] 
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
						if T.should_extend_in_situ(type) then
							type.namespace = var_.namespace --[[SOL OUTPUT--]] 
						else
							type = U.shallow_clone(type) --[[SOL OUTPUT--]] 
							type.namespace = var_.namespace --[[SOL OUTPUT--]] 
							var_.type = type --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					report_error(expr, "Variable %q used as namespace but is not an object - it's %s", var_.name, type) --[[SOL OUTPUT--]] 
					var_.namespace = nil --[[SOL OUTPUT--]]  -- Only warn once
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			
			--report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.ast_type, type)

			--D.assert(T.is_type(type)  or  T.is_type_list(type))
			D.assert( T.is_type(type) ) --[[SOL OUTPUT--]] 

			-- Store for quick access later on:
			expr.variable = var_ --[[SOL OUTPUT--]] 

			return { type }, var_ --[[SOL OUTPUT--]] 

		-- Anything that can return multiple values:
		elseif expr.ast_type == 'CallExpr' then        -- foo(arg, ...)
			--U.printf('CallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope), nil --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'TableCallExpr' then   -- foo{arg}
			--U.printf('TableCallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope), nil --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'StringCallExpr' then  -- foo'arg'
			--U.printf('StringCallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope), nil --[[SOL OUTPUT--]] 

		else
			local type = analyze_simple_expr_unchecked(expr, scope) --[[SOL OUTPUT--]] 

			report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.ast_type, type) --[[SOL OUTPUT--]] 
			D.assert(T.is_type(type)) --[[SOL OUTPUT--]] 

			return { type }, nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	-- Return type
	analyze_simple_expr_unchecked = function(expr, scope)
		if expr.ast_type == 'NumberExpr' then
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


		elseif expr.ast_type == 'ExternExpr' then
			-- Definitions is in C - could be anything
			return T.Any --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'BinopExpr' then
			local op = expr.op --[[SOL OUTPUT--]] 
			local lt = analyze_expr_single( expr.lhs, scope ) --[[SOL OUTPUT--]] 
			local rt = analyze_expr_single( expr.rhs, scope ) --[[SOL OUTPUT--]] 

			--report_spam(expr, "Binop: %s %s %s", lt, op, rt)

			if NumOps[op] then
				local l_mm_ret = try_metamethod(expr, lt, NumOps[op], {expr.lhs, expr.rhs}, {lt,rt}, lt) --[[SOL OUTPUT--]] 
				if l_mm_ret then return l_mm_ret --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

				local r_mm_ret = try_metamethod(expr, rt, NumOps[op], {expr.lhs, expr.rhs}, {lt,rt}, rt) --[[SOL OUTPUT--]] 
				if r_mm_ret then return r_mm_ret --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

				if T.could_be(lt, T.Num) and T.could_be(rt, T.Num) then
					report_spam(expr, "Combining types %s and %s", lt, rt) --[[SOL OUTPUT--]] 
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
					report_error(expr, "Comparing incompatible types: %s and %s", lt, rt) --[[SOL OUTPUT--]] 
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
					report_warning(expr, "Operator 'and' expected boolean expression to the left, got %s", lt) --[[SOL OUTPUT--]] 
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
					report_warning(expr, "Operator 'or' expected boolean expression to the left, got %s", lt) --[[SOL OUTPUT--]] 
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
				local mm_ret = try_metamethod(expr, arg_t, '__unm', {expr.rhs}, {arg_t}, arg_t) --[[SOL OUTPUT--]] 
				if mm_ret then return mm_ret --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

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
					report_warning(expr, "'not' operator expected boolean or nil:able, got %s", arg_t) --[[SOL OUTPUT--]] 
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
			local v = scope:get_local('...') --[[SOL OUTPUT--]] 
			if v then
				v.num_reads = v.num_reads + 1 --[[SOL OUTPUT--]] 
				local t = v.type --[[SOL OUTPUT--]] 
				assert(t) --[[SOL OUTPUT--]] 
				if t then
					assert(t.tag == 'varargs') --[[SOL OUTPUT--]] 
					return t --[[SOL OUTPUT--]] 
				else
					return {
						tag  = 'varargs',
						type = T.Any 
					} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				report_error(expr, "No ... in scope") --[[SOL OUTPUT--]] 
				return {
					tag  = 'varargs',
					type = T.Any 
				} --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'IndexExpr' then
			-- base[index]
			local base_t  = analyze_expr_single(expr.base,  scope) --[[SOL OUTPUT--]] 
			local index_t = analyze_expr_single(expr.index, scope) --[[SOL OUTPUT--]] 

			D.assert(T.is_type(base_t)) --[[SOL OUTPUT--]] 

			local ret = T.visit_and_combine(base_t, function(t)
				D.assert(T.is_type(t)) --[[SOL OUTPUT--]] 

				if T.is_any(t) then
					return T.Any --[[SOL OUTPUT--]] 

				elseif T.is_empty_table(t) then
					-- Indexing what? We don't know
					sol_warning(expr, 'Indexing unkown table') --[[SOL OUTPUT--]] 
					return T.Any --[[SOL OUTPUT--]] 

				elseif t.tag == 'table' then
					return T.Any --[[SOL OUTPUT--]] 

				elseif t.tag == 'list' then
					assert(t.type) --[[SOL OUTPUT--]] 
					check_type_is_a("List index", expr.index, index_t, T.Uint, 'error') --[[SOL OUTPUT--]] 
					return t.type --[[SOL OUTPUT--]] 

				elseif t.tag == 'map' then
					report_spam(expr, "Map index") --[[SOL OUTPUT--]] 
					check_type_is_a("Map index", expr.index, index_t, t.key_type, 'error') --[[SOL OUTPUT--]] 
					return T.variant(t.value_type, T.Nil) --[[SOL OUTPUT--]]   -- Nil on not found

				elseif t.tag == 'object' then
					if t.metatable then
						-- e.g.  v[3]  where v is a Vector3
						local index = t.metatable.members['__index'] --[[SOL OUTPUT--]] 
						if index then
							return try_match_index(expr, index, index_t) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if T.could_be(index_t, T.String) then
						-- Indexing the keys of an object - OK.
						sol_warning(expr, "Indexing object with string") --[[SOL OUTPUT--]] 
						return T.Any --[[SOL OUTPUT--]]   -- TODO: combine types of members?
					end --[[SOL OUTPUT--]] 
					
					return nil --[[SOL OUTPUT--]] 

				else
					-- Not indexable
					return nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end) --[[SOL OUTPUT--]] 

			if ret then
				return ret --[[SOL OUTPUT--]] 
			else
				report_error(expr, 'Cannot index type %s with %s', base_t, index_t) --[[SOL OUTPUT--]] 
				return T.Any --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'MemberExpr' then
			-- .  or  :
			local base_t = analyze_expr_single(expr.base, scope) --[[SOL OUTPUT--]] 
			local name = expr.ident.data --[[SOL OUTPUT--]] 

			if T.is_any(base_t) then
				return T.Any --[[SOL OUTPUT--]] 
			else
				local suggestions = {} --[[SOL OUTPUT--]] 
				local t = do_member_lookup(expr, base_t, name, suggestions) --[[SOL OUTPUT--]] 
				if t then
					return t --[[SOL OUTPUT--]] 
				else
					if #suggestions > 0 then
						report_warning(expr, "%s: Failed to find member %q - did you mean %q?", expr, name, table.concat(suggestions, " or ")) --[[SOL OUTPUT--]] 
					else
						member_missing_reporter(expr, "%s: Failed to find member %q (%s)", expr, name, expr) --[[SOL OUTPUT--]]  -- TODO: warn
					end --[[SOL OUTPUT--]] 
					return T.Any --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif expr.ast_type == 'LambdaFunctionExpr' then
			-- Lambda function
			local is_pre_analyze = false --[[SOL OUTPUT--]] 
			local fun_t = analyze_function_head( expr, scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
			fun_t.name = '<lambda>' --[[SOL OUTPUT--]] 
			analyze_function_body( expr, scope, fun_t ) --[[SOL OUTPUT--]] 
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
				local map_keys    = {} --[[SOL OUTPUT--]] 
				local key_type    = T.make_variant() --[[SOL OUTPUT--]]  -- in maps
				local value_type  = T.make_variant() --[[SOL OUTPUT--]] 
				local obj_members = {} --[[SOL OUTPUT--]] 

				local count = { ['key'] = 0, ['ident_key'] = 0, ['value'] = 0 } --[[SOL OUTPUT--]] 
				for _,e in ipairs(expr.entry_list) do
					count[e.type] = count[e.type] + 1 --[[SOL OUTPUT--]] 

					local this_val_type = analyze_expr_single(e.value, scope) --[[SOL OUTPUT--]] 
					
					--if this_val_type == T.Nil then -- TODO!
					if e.value.ast_type == 'NilExpr' then
						inform('nil-in-list', expr, "Nil in list.") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if this_val_type.tag == 'varargs' then
						this_val_type = this_val_type.type --[[SOL OUTPUT--]]  -- Many of these
					end --[[SOL OUTPUT--]] 

					value_type = T.extend_variant( value_type, this_val_type ) --[[SOL OUTPUT--]] 

					if e.type == 'key' then
						local this_key_type = analyze_expr_single(e.key, scope) --[[SOL OUTPUT--]] 
						key_type = T.extend_variant( key_type, this_key_type ) --[[SOL OUTPUT--]] 

						if this_key_type.tag == 'int_literal' or
						   this_key_type.tag == 'num_literal' or
						   this_key_type.tag == 'string_literal'
						then
							if map_keys[ this_key_type.value ] then
								report_error(e.value, "Map key %q declared twice", this_key_type.value) --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
							map_keys[ this_key_type.value ] = true --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					if e.type == 'ident_key' then
						if obj_members[ e.key ] then
							report_error(e.value, "Object member %q declared twice", e.key) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
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

		elseif expr.ast_type == 'CastExpr' then
			local expr_type = analyze_expr_single( expr.expr, scope ) --[[SOL OUTPUT--]] 
			local cast_to   = expr.type --[[SOL OUTPUT--]] 
			check_type_is_a("Cast", expr, expr_type, cast_to, 'error') --[[SOL OUTPUT--]] 
			return cast_to --[[SOL OUTPUT--]] 

		else
			print("Unknown expression AST type: ", expr.ast_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		report_error(expr, "Failed to figure out type of %s", expr.ast_type) --[[SOL OUTPUT--]] 

		return T.Any --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- eg:  check_condition('while', some_expr, scope)
	-- examples:   if some_expr then ...
	-- examples:   while true then ...
	local check_condition = function(name, expr, scope)
		local t = analyze_expr_single(expr, scope) --[[SOL OUTPUT--]] 

		if expr.ast_type == 'BooleanExpr' then
			-- 'true' or 'false' as explicit argument - that's OK
			-- e.g. for   while true do  ... break ... end
		else
			if not T.is_useful_boolean(t) then
				report_error(expr, "Not a useful boolean expression in %q, type is %s", name, t) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- TODO: tow type args: explicit (if any) and deduced (right hand side, if any)
	-- if explicit: use it, and ensure deduced and pre-analyzed type (v.type) is compatible
	-- if no explicit, use a combinarion of deduced and pre-analyzed.
	local function decl_var_type(stat, v, deduced_type, explicit_type)
		local pre_analyzed_type = v.type --[[SOL OUTPUT--]] 

		--report_info(stat, "decl_var_type %q pre-analyzed: %s, explicit: %s, deduced: %s\n", v.name, pre_analyzed_type, explicit_type, deduced_type)

		if deduced_type and deduced_type.tag == 'function' and deduced_type.name == '<lambda>' then
			-- Give the lmabda-function a more helpful name:
			deduced_type.name = v.name --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if explicit_type then
			-- TODO: remove explicit types and rely on casts
			if deduced_type then
				check_type_is_a("Variable declaration", stat, deduced_type, explicit_type, 'error') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			if pre_analyzed_type then
				check_type_is_a("Variable declaration", stat, pre_analyzed_type, explicit_type, 'error') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			v.type = explicit_type --[[SOL OUTPUT--]] 

		elseif pre_analyzed_type then
			if deduced_type then
				--report_spam(stat, "decl_var_type %q pre-analyzed: %s, deduced: %s\n", v.name, pre_analyzed_type, deduced_type)

				if pre_analyzed_type.tag == 'object' then
					-- Combine with deduced type(s):
					local comb_obj = U.shallow_clone( pre_analyzed_type ) --[[SOL OUTPUT--]] 
					comb_obj.members = U.shallow_clone( comb_obj.members ) --[[SOL OUTPUT--]] 

					T.visit(deduced_type, function(t)
						if t.tag == 'object' then
							for name, mem_type in pairs(t.members) do
								--report_spam(stat, "Combining member %q, deduced: %s", name, mem_type)
								comb_obj.members[name] = T.variant(comb_obj.members[name], mem_type) --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end) --[[SOL OUTPUT--]] 

					report_spam(stat, "decl_var_type %q pre-analyzed: %s, deduced: %s, combined: %s\n", v.name, pre_analyzed_type, deduced_type, comb_obj) --[[SOL OUTPUT--]] 

					v.type = comb_obj --[[SOL OUTPUT--]] 
				else
					check_type_is_a("Variable declaration", stat, deduced_type, pre_analyzed_type, 'error') --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		else
			if deduced_type == T.Nil then
				inform('nil-init', stat, "Initializing %q with nil - type cannot be deduced", v.name) --[[SOL OUTPUT--]] 
				v.type = T.Nilable --[[SOL OUTPUT--]] 

			elseif deduced_type then
				v.type = T.broaden( deduced_type ) --[[SOL OUTPUT--]] 

			else
				--v.type = T.Any
				sol_warning(stat, "Can't deduce type of %q", v.name) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		v.namespace = deduced_type and deduced_type.namespace --[[SOL OUTPUT--]]   -- If any
		v.num_writes = v.num_writes + 1 --[[SOL OUTPUT--]] 

		--report_info(stat, "decl_var_type %q pre-analyzed: %s, explicit: %s, deduced: %s, RESULT: %s\n", v.name, pre_analyzed_type, explicit_type, deduced_type, v.type)
	end --[[SOL OUTPUT--]] 


	local function assign_to_obj_member(stat, _,
		                                 is_pre_analyze, is_declare, extend_existing_type,
		                                 obj_t, name, right_type)
	 											--> T.Type -- TODO: have this here


		report_spam(stat, "Exisiting object") --[[SOL OUTPUT--]] 

		local left_type = obj_t.members[name] --[[SOL OUTPUT--]] 

		if left_type and left_type.pre_analyzed then
			if right_type.pre_analyzed and is_pre_analyze then
				report_error(stat, "Name clash: %q, previously declared in %s", name, left_type.where) --[[SOL OUTPUT--]] 
			else
				D.assert(not right_type.pre_analyzed) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			-- The member type was reached by the pre-analyzer - overwrite with refined info:
			
			--obj_t.members[name] = nil  -- TODO: makes compilation hang!
			left_type = nil --[[SOL OUTPUT--]] 

			report_spam(stat, "Replacing pre-analyzed type with refined type: %s", right_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if left_type then
			report_spam(stat, "Object already has member") --[[SOL OUTPUT--]] 
			left_type = T.broaden( left_type ) --[[SOL OUTPUT--]]  -- Previous value may have been 'false' - we should allow 'true' now:

			if not T.could_be(right_type, left_type) then
				report_error(stat, "[B] type clash: cannot assign to %q (of type %s) with %s", name, left_type, right_type) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return obj_t --[[SOL OUTPUT--]] 
		else
			if not obj_t.members[name] then
				if not is_declare then
					local close_name = loose_lookup(obj_t.members, name) --[[SOL OUTPUT--]] 

					if close_name then
						report_warning(stat, "Could not find %q - Did you mean %q?", name, close_name) --[[SOL OUTPUT--]] 
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

			--extend_existing_type = true -- don't do this

			if extend_existing_type then
				report_spam(stat, "Extending class with %q - class: %s", name, tostring(obj_t)) --[[SOL OUTPUT--]] 

				--[[
				var foo = Foo:new()
				if ... then
					foo.name = "hello"
				end

				-- Don't change 'Foo' to having a member:  name: string
				-- Just add an optional member:            name: string?
				--]]
				if not T.is_class(right_type) then
					right_type = T.make_nilable(right_type) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				obj_t.members[name] = right_type --[[SOL OUTPUT--]] 
			else
				D.assert(not T.should_extend_in_situ(obj_t)) --[[SOL OUTPUT--]] 
				obj_t = U.shallow_clone( obj_t ) --[[SOL OUTPUT--]] 
				obj_t.members = U.shallow_clone( obj_t.members ) --[[SOL OUTPUT--]] 
				obj_t.members[name] = right_type --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return obj_t --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function do_assignment(stat, scope, left_expr, right_type, is_pre_analyze)
		assert(not T.is_type_list(right_type)) --[[SOL OUTPUT--]] 

		if right_type.tag == 'function' and right_type.name == '<lambda>' then
			-- Give the lmabda-function a more helpful name:
			right_type.name = format_expr(left_expr) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local is_declare = stat.ast_type == 'FunctionDeclStatement'
			or right_type.tag == 'function' --[[SOL OUTPUT--]] 

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
				local extend_existing_type = (base_var.name == 'self') --[[SOL OUTPUT--]] 


				if not base_var.type or T.is_empty_table(base_var.type) then
					report_spam(stat, "New object") --[[SOL OUTPUT--]] 
					base_var.type = { tag = 'object', members = {} } --[[SOL OUTPUT--]] 
					extend_existing_type = false --[[SOL OUTPUT--]]  -- bad idea
				end --[[SOL OUTPUT--]] 

				report_spam(stat, "Assigning to %s.%s", base_var.name, name) --[[SOL OUTPUT--]] 

				local var_t = T.follow_identifiers(base_var.type) --[[SOL OUTPUT--]] 

				-- TODO: use T.visit_and_combine
				if var_t.tag == 'variant' then
					--var extend_variant_member = extend_existing_type
					local extend_variant_member = false --[[SOL OUTPUT--]] 

					local variant = T.clone_variant(var_t) --[[SOL OUTPUT--]] 

					-- TODO: recurse
					for i,v in ipairs(variant.variants) do
						if v.tag == 'object' then
							variant.variants[i] = assign_to_obj_member(stat, scope,
								                                        is_pre_analyze, is_declare, extend_variant_member,
								                                        v, name, right_type) --[[SOL OUTPUT--]] 	
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				elseif var_t.tag == 'object' then
					local extend_object = extend_existing_type or T.is_class(var_t) or T.is_instance(var_t) --[[SOL OUTPUT--]] 

					base_var.type = assign_to_obj_member(stat, scope,
						                                 is_pre_analyze, is_declare, extend_object,
						                                 var_t, name, right_type) --[[SOL OUTPUT--]] 	
					return --[[SOL OUTPUT--]] 
				elseif T.is_any(var_t) then
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					sol_warning(stat, "[B] Indexing type 'any' with %q", name) --[[SOL OUTPUT--]] 
				else
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_warning(stat, "[B] Looking up %q in non-object of type %s", name, var_t) --[[SOL OUTPUT--]] 
					--D.break_()
				end --[[SOL OUTPUT--]] 

			else -- no variable we can update the type of
				-- e.g.:   foo.bar.baz
				report_solc_todo(stat, "Left hand side of assignment: tried to access non-variable: %s", left_expr.base) --[[SOL OUTPUT--]] 
				assert(base_t) --[[SOL OUTPUT--]] 

				local success = false --[[SOL OUTPUT--]] 
				local fail    = false --[[SOL OUTPUT--]] 

				T.visit(base_t, function(t)
					if T.is_any(t) then
						-- not an object? then no need to extend the type
						-- eg.   local foo = som_fun()   foo.var_ = ...
						sol_warning(stat, "[A] Member-accessing type 'any' with %q", name) --[[SOL OUTPUT--]] 
						fail = true --[[SOL OUTPUT--]] 

					elseif t.tag == 'object' then
						local left_type = t.members[name] --[[SOL OUTPUT--]] 

						if left_type and left_type.pre_analyzed then
							-- The member type was reached by the pre-analyzer - overwrite with refined info:
							assert(not right_type.pre_analyzed) --[[SOL OUTPUT--]] 
							left_type = nil --[[SOL OUTPUT--]] 

							report_spam(stat, "Replacing pre-analyzed type with refined type: %s", right_type) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						if left_type then
							report_spam(stat, "Object already has member") --[[SOL OUTPUT--]] 
							left_type = T.broaden( left_type ) --[[SOL OUTPUT--]]  -- Previous value may have been 'false' - we should allow 'true' now:

							if not T.could_be(right_type, left_type) then
								report_error(stat, "[A] type clash: cannot assign to %q (of type %s) with %s", name, left_type, right_type) --[[SOL OUTPUT--]] 
								fail = true --[[SOL OUTPUT--]] 
							else
								success = true --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						else
							if not is_declare and not t.members[name] then
								local close_name = loose_lookup(t.members, name) --[[SOL OUTPUT--]] 

								if close_name then
									report_warning(stat, "Could not find %q - Did you mean %q?", name, close_name) --[[SOL OUTPUT--]] 
								end --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 

							report_spam(stat, "Adding member") --[[SOL OUTPUT--]] 
							report_warning(stat, "Adding member %q to %q", name, t) --[[SOL OUTPUT--]] 

							--[[
							We do not broaden the type here, to make sure the following code works:

							typedef Foo = { tag : 'foo '}

							function fun() -> Foo
								local ret = {}
								ret.tag = 'foo'  -- No broadeding! tag is 'foo', not string
								return ret
							end
							--]]
							t.members[name] = right_type --[[SOL OUTPUT--]] 
							success = true --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end) --[[SOL OUTPUT--]] 

				if success then
					return true --[[SOL OUTPUT--]] 
				elseif fail then
					return false --[[SOL OUTPUT--]] 
				else
					report_warning(stat, "[B] Looking up %q in non-object of type %s", name, base_t) --[[SOL OUTPUT--]] 
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

		local left_type, left_var = analyze_expr_single_var( left_expr, scope ) --[[SOL OUTPUT--]] 

		if left_var then
			left_var.num_writes = left_var.num_writes + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if left_type.namespace then
			report_error(stat, "Cannot assign to a namespace outside of declaration") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if left_type.is_pre_analyze or (left_var and left_var.is_pre_analyze) then
			if left_var then
				left_var.type = right_type --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			if settings.is_sol then -- TODO: lua too!
				--if not T.isa(right_type, left_type) then
				if not T.could_be(right_type, left_type) then
					local problem_rope = {} --[[SOL OUTPUT--]] 
					T.could_be(right_type, left_type, problem_rope) --[[SOL OUTPUT--]] 
					local problem_str = rope_to_msg(problem_rope) --[[SOL OUTPUT--]] 
					report_error(stat, "[C] type clash: cannot assign to type %s with %s: %s", left_type, right_type, problem_str) --[[SOL OUTPUT--]] 
					return false --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return true --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local function analyze_typedef(stat, scope)
		local name = stat.type_name --[[SOL OUTPUT--]] 

		-- Assign names:
		if stat.type then
			T.visit(stat.type, function(t)
				if t.tag == 'extern' then
					assert(not t.name) --[[SOL OUTPUT--]] 
					t.name = name --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if stat.namespace_name then
			local v = scope:get_var( stat.namespace_name ) --[[SOL OUTPUT--]] 

			if not v then
				report_error(stat, "namespaced typedef: %s is not a previously defined variable", stat.namespace_name) --[[SOL OUTPUT--]] 
				return --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			v.namespace = v.namespace or {} --[[SOL OUTPUT--]] 
			local ns = v.namespace --[[SOL OUTPUT--]] 
			if ns[name] then
				report_error(stat, "type %s.%s already declared as %s", v.name, name, ns[name]) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if stat.type then
				report_spam(stat, "Declaring type %s.%s as %s", v.name, name, stat.type) --[[SOL OUTPUT--]] 
			else
				report_spam(stat, "Forward-declaring type %s.%s", v.name, name) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			ns[name] = stat.type --[[SOL OUTPUT--]] 
		else
			local old = scope:get_scoped_type(name) --[[SOL OUTPUT--]] 
			if old then
				report_error(stat, "type %q already declared as %s", name, old) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			scope:declare_type(name, stat.type, where_is(stat), stat.is_local) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if stat.base_types and #stat.base_types > 0 then
			report_spam(stat, "%s inherits %i types", name, #stat.base_types) --[[SOL OUTPUT--]] 

			local child_type = T.follow_identifiers(stat.type) --[[SOL OUTPUT--]] 

			if child_type.tag ~= 'object' then
				report_error(stat, "Only objects can have base-types - child: %s", child_type) --[[SOL OUTPUT--]] 
			else
				for _,base in ipairs(stat.base_types) do
					report_spam(stat, "%s inheriting %s", name, base.name) --[[SOL OUTPUT--]] 

					if base.tag ~= 'identifier' then
						report_error(stat, "You can only inherit other typedef:s") --[[SOL OUTPUT--]] 
						break --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					local base_type = T.follow_identifiers(base) --[[SOL OUTPUT--]] 
					if base_type.tag ~= 'object' then
						report_error(stat, "%q cannot inherit non-object %s", name, base) --[[SOL OUTPUT--]] 
						break --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					for id,id_type in pairs(base_type.members) do
						if child_type.members[id] then
							if not T.isa(child_type.members[id], id_type) then
								report_error(stat, "Child type %s overrides %q with differing type.", name, id) --[[SOL OUTPUT--]] 
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

	-- returns the CLASS type
	local function declare_class(stat, scope, name, is_local, rhs)
		report_spam(stat, "Declaring class %q", name) --[[SOL OUTPUT--]] 

		-------------------------------------------------
		-- Start with declaring the type:

		local old = scope:get_scoped_type(name) --[[SOL OUTPUT--]] 
		if old then
			report_error(stat, "class type %q already declared as %q", name, old) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		local class_type = {
			tag     = 'object',
			members = {},
		} --[[SOL OUTPUT--]] 

		local instance_type = {
			tag        = 'object',
			members    = {},
			class_type = class_type,
			metatable  = class_type,  -- It generally will be!
		} --[[SOL OUTPUT--]] 

		class_type.instance_type = instance_type --[[SOL OUTPUT--]] 
		class_type.metatable = class_type --[[SOL OUTPUT--]]  -- This is a common idiom for storing meta-methods (__add, ..) as class members

		-- The name refers to the *instance* type.
		scope:declare_type(name, instance_type, where_is(stat), is_local) --[[SOL OUTPUT--]] 

		-------------------------------------------------

		local rhs_type = analyze_expr_single(rhs, scope) --[[SOL OUTPUT--]] 
		check_type_is_a("Class declaration", stat, rhs_type, T.Table, 'error') --[[SOL OUTPUT--]] 

		-------------------------------------------------
		return class_type --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local function analyze_class_decl(stat, scope)
		local name     = stat.name --[[SOL OUTPUT--]] 
		local is_local = stat.is_local --[[SOL OUTPUT--]] 

		local class_type = declare_class(stat, scope, name, is_local, stat.rhs) --[[SOL OUTPUT--]] 

		-- Now for the variable:
		-- The variable represents the class - not an instance of it!
		local v = declare_var(stat, scope, name, is_local, class_type) --[[SOL OUTPUT--]] 
		D.assert(v.type == class_type) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Returns a list of types the statement returns to scope_fun
	-- If the second return is 'true', all possible code paths return at some point.
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

			--[-[
			if    nlhs == 1
			  and nrhs == 1
			  and stat.lhs[1].ast_type     == 'IdExpr'
			  and stat.rhs[1].ast_type     == 'BinopExpr'
			  and stat.rhs[1].op           == 'or'
			  and stat.rhs[1].lhs.ast_type == 'IdExpr'
			  and stat.rhs[1].lhs.name     == stat.lhs[1].name
			  and not settings.is_sol
			then
				--[[
				  HACK: Foo = Foo or EXPR
				  This is a very common Lua idiom
				--]]
				local name = stat.lhs[1].name --[[SOL OUTPUT--]] 
				local type_expr = stat.rhs[1].rhs --[[SOL OUTPUT--]] 
				local rt = analyze_expr_single(type_expr, scope) --[[SOL OUTPUT--]] 
				do_assignment(stat, scope, stat.lhs[1], rt, is_pre_analyze) --[[SOL OUTPUT--]] 

			elseif nlhs == 1
			  and  nrhs == 1
			  and  stat.lhs[1].ast_type      == 'IdExpr'
			  and  stat.rhs[1].ast_type      == 'CallExpr'
			  and  stat.rhs[1].base.ast_type == 'IdExpr'
			  and  stat.rhs[1].base.name     == 'class'
			  and  not settings.is_sol
			then
				--[[
				HACK: Foo = class(...)
				Common lua idiom
				--]]
				local name = stat.lhs[1].name --[[SOL OUTPUT--]] 
				local is_local = false --[[SOL OUTPUT--]] 
				local class_type = declare_class(stat, scope, name, is_local, stat.rhs[1]) --[[SOL OUTPUT--]] 
				-- Allow Foo(...):
				class_type.metatable = {
					tag='object',
					members = {
						__call = {
							tag    = 'function';
							args   = {};
							vararg = { tag='varargs', type=T.Any };
							rets   = T.AnyTypeList;
							name   = '__call';
						}
					}
				} --[[SOL OUTPUT--]] 
				local v = declare_var(stat, scope, name, is_local, class_type) --[[SOL OUTPUT--]] 
				v.type = class_type --[[SOL OUTPUT--]]  -- FIXME

			elseif nrhs == 1 then
			--]-]
			--if nrhs == 1 then
				local rt, _ = analyze_expr(stat.rhs[1], scope) --[[SOL OUTPUT--]] 
				if rt == T.AnyTypeList then
					local N = nlhs --[[SOL OUTPUT--]] 
					for i=1,N do
						do_assignment(stat, scope, stat.lhs[i], T.Any, is_pre_analyze) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					if nlhs > #rt then
						report_error(stat, "Unequal number of variables and values: left hand side has %i variables, right hand side evaluates to %s", nlhs, rt) --[[SOL OUTPUT--]] 
					elseif nlhs < #rt then
						report_warning(stat, "Assignment discards values: left hand side has %i variables, right hand side evaluates to %s", nlhs, rt) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					local N = math.min(nlhs, #rt) --[[SOL OUTPUT--]] 
					for i=1,N do
						do_assignment(stat, scope, stat.lhs[i], rt[i], is_pre_analyze) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif nlhs ~= nrhs then
				report_error(stat, "Unequal number of variables and values") --[[SOL OUTPUT--]] 

			else
				for i = 1,nrhs do
					local rti = analyze_expr_single(stat.rhs[i], scope) --[[SOL OUTPUT--]] 
					do_assignment(stat, scope, stat.lhs[i], rti, is_pre_analyze) --[[SOL OUTPUT--]] 
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
				init_types, _ = analyze_expr( stat.init_list[1], scope ) --[[SOL OUTPUT--]] 
			else
				for _,exp in ipairs(stat.init_list) do
					init_types[#init_types + 1] = analyze_expr_single( exp, scope ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local explicit_types = stat.type_list --[[SOL OUTPUT--]] 

			-- Declare variables:
			local is_local = (stat.scoping ~= 'global') --[[SOL OUTPUT--]] 
			local vars = {} --[[SOL OUTPUT--]] 
			for _,name in ipairs(stat.name_list) do
				report_spam(stat, "Declaration: %s %s", stat.type, name) --[[SOL OUTPUT--]] 
				local v = declare_var(stat, scope, name, is_local) --[[SOL OUTPUT--]] 
				--v.type = nil -- Ignore any forward-deduced type

				v.var_type = (is_local and 'Local variable' or 'Global variable') --[[SOL OUTPUT--]] 

				vars[#vars + 1] = v --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if explicit_types then
				if #explicit_types ~= 1 and #explicit_types ~= #vars then
					report_error(stat, "Uneven number of explicit types (%i) and variables (%i) in 'local' declaration. Either supply just one type, or one type per variable.", #explicit_types, #vars) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				if #explicit_types == 1 and #explicit_types ~= #vars then
					-- One type to be applied to all - just duplicate: 

					explicit_types = U.shallow_clone( explicit_types ) --[[SOL OUTPUT--]] 

					while #explicit_types < #vars do
						table.insert(explicit_types, explicit_types[1]) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if #stat.init_list == 0 then
				-- local a,b
				if stat.scoping == 'var' then
					report_error(stat, "'var' must always be initialized at declaration") --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

				for ix, v in ipairs(vars) do
					decl_var_type(stat, v, nil, explicit_types and explicit_types[ix]) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif #stat.init_list == 1 then
				-- local a,b = foo()
				if init_types == T.AnyTypeList then
					-- Nothing to do
					for ix, v in ipairs(vars) do
						decl_var_type(stat, v, T.Any, explicit_types and explicit_types[ix]) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					local nt = #init_types --[[SOL OUTPUT--]] 
					
					if #vars < nt then
						-- Ignoring a few return values is OK
						report_warning(stat, "Declaration discards values: left hand side has %i variables, right hand side evaluates to %s", #vars, init_types) --[[SOL OUTPUT--]] 
						--report_spam(stat, "Declaration discards values: left hand side has %i variables, right hand side evaluates to %s", #vars, init_types)
					elseif #vars > nt then
						report_error(stat, "Too many variables in 'local' declaration. Right hand side has type %s",
							T.name(init_types)) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					for ix, v in ipairs(vars) do
						decl_var_type(stat, v, init_types[ix], explicit_types and explicit_types[ix]) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			elseif #vars ~= #stat.init_list then
				-- local a,b,c = 1,2
				report_error(stat, "Uneven number of variables and values in local declaration. Variables: %i, inits: %i",
					#vars, #stat.init_list) --[[SOL OUTPUT--]] 
			else
				-- local a,b,c = 1,2,3
				for ix, v in ipairs(vars) do
					local deduced_type = init_types[ix] --[[SOL OUTPUT--]] 
					assert( T.is_type(deduced_type) ) --[[SOL OUTPUT--]] 
					decl_var_type(stat, v, deduced_type, explicit_types and explicit_types[ix]) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			if stat.scoping == 'var' then
				for ix, v in ipairs(vars) do
					if explicit_types and explicit_types[ix] == T.Any then
						-- explicit any is ok
					elseif v.type==nil or T.is_any(v.type) then
						report_error(stat, "%q has undeducible type - the type of a 'var' must be compile-time deducible", v.name) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'IfStatement' then
			local ret = nil --[[SOL OUTPUT--]] 
			local all_paths_return = true --[[SOL OUTPUT--]] 

			for i = 1, #stat.clauses do
				local st = stat.clauses[i] --[[SOL OUTPUT--]] 
				if i == 1 then
					check_condition( 'if',     st.condition, scope ) --[[SOL OUTPUT--]] 
				elseif st.condition then
					check_condition( 'elseif', st.condition, scope ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local clause_ret, clause_returns = analyze_closed_off_statlist( st.body, scope_fun ) --[[SOL OUTPUT--]] 
				ret = T.combine_type_lists(ret, clause_ret) --[[SOL OUTPUT--]] 
				if not clause_returns then
					all_paths_return = false --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return ret, all_paths_return --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'WhileStatement' then
			local cond_t = check_condition( 'while', stat.condition, scope ) --[[SOL OUTPUT--]] 
			local ret, always_return = analyze_closed_off_statlist(stat.body, scope_fun) --[[SOL OUTPUT--]] 

			if cond_t == T.True then
				-- while true:  Infinite loop
				if always_return then
					return ret, true --[[SOL OUTPUT--]] 
				else
					-- Do we return - don't know - depends on wether there is a goto or a break
					-- Assume 'yes' to silence warnings
					return ret, true --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				return ret, false --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'DoStatement' then
			local ret, all_paths_return = analyze_closed_off_statlist(stat.body, scope_fun) --[[SOL OUTPUT--]] 
			return ret, all_paths_return --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'ReturnStatement' then
			local what_to_return = nil --[[SOL OUTPUT--]] 
			if #stat.arguments == 0 then
				what_to_return = T.Void --[[SOL OUTPUT--]] 
			elseif #stat.arguments == 1 then
				what_to_return, _ = analyze_expr( stat.arguments[1], scope ) --[[SOL OUTPUT--]] 
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
			return what_to_return, true --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'BreakStatement' then
			-- Nothing to do

		elseif stat.ast_type == 'RepeatStatement' then
			local loop_scope = stat.scope --[[SOL OUTPUT--]] 
			local ret, _ = analyze_statlist(stat.body, loop_scope, scope_fun) --[[SOL OUTPUT--]] 
			check_condition( 'repeat', stat.condition, loop_scope ) --[[SOL OUTPUT--]] 
			discard_scope(loop_scope) --[[SOL OUTPUT--]] 
			return ret, false --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'FunctionDeclStatement' then
			assert(stat.scope.parent == scope) --[[SOL OUTPUT--]] 
			local is_pre_analyze = false --[[SOL OUTPUT--]] 
			local fun_t = analyze_function_head( stat, scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
			fun_t.name = format_expr(stat.name_expr) --[[SOL OUTPUT--]] 

			--[[ Assign type before recursing on body.
			     This is so that recursive function can typecheck the calls to itself
			]]--
			if stat.is_aggregate then
				-- function foo:bar(arg)
				if stat.name_expr.ast_type ~= 'MemberExpr' then
					-- e.g.  "function foo(bar)"
					report_warning(stat, "non-local function, name: %q", fun_t.name) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				do_assignment(stat, scope, stat.name_expr, fun_t, is_pre_analyze) --[[SOL OUTPUT--]] 
			else
				--[[ e.g:
					"local function foo(bar)"
					"global function foo(bar)"
				--]]
				report_spam(stat, "free function, name: %q", fun_t.name) --[[SOL OUTPUT--]] 

				local v = declare_var(stat, scope, stat.name_expr.name, stat.is_local, fun_t) --[[SOL OUTPUT--]] 
				v.num_writes = v.num_writes + 1 --[[SOL OUTPUT--]] 
				v.var_type = 'Function' --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			-- Now analyze body:
			analyze_function_body( stat, scope, fun_t ) --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'GenericForStatement' then
			local loop_scope = stat.scope --[[SOL OUTPUT--]] 
			assert(loop_scope.parent == scope) --[[SOL OUTPUT--]] 

			if #stat.generators > 1 then
				report_warning(stat, "Sol currently only support one generator") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local types = extract_iterator_type( stat.generators[1], scope ) --[[SOL OUTPUT--]] 

			if types ~= T.AnyTypeList then
				if #types ~= #stat.var_names then
					report_error(stat, "Expected %i loop variables", #types) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			for i = 1,#stat.var_names do
				local v = declare_local(stat, loop_scope, stat.var_names[i]) --[[SOL OUTPUT--]] 
				v.num_writes = v.num_writes + 1 --[[SOL OUTPUT--]] 
				v.var_type = 'Loop variable' --[[SOL OUTPUT--]] 
				if types ~= T.AnyTypeList then
					v.type = types[i] --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local ret, _ = analyze_statlist(stat.body, loop_scope, scope_fun) --[[SOL OUTPUT--]] 
			discard_scope(loop_scope) --[[SOL OUTPUT--]] 
			return ret, false --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'NumericForStatement' then
			local loop_scope = stat.scope --[[SOL OUTPUT--]] 
			assert(loop_scope.parent == scope) --[[SOL OUTPUT--]] 

			local function check_num_arg(what, t)
				if not T.isa(t, T.Num) then
					report_error(stat, "Numeric for loop expected numeric %s, got %s", what, t) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local start_t = analyze_expr_single(stat.start, loop_scope) --[[SOL OUTPUT--]] 
			local end_t   = analyze_expr_single(stat.end_, loop_scope) --[[SOL OUTPUT--]] 

			check_num_arg('start', start_t) --[[SOL OUTPUT--]] 
			check_num_arg('end',   end_t) --[[SOL OUTPUT--]] 

			local iter_t = T.combine(start_t, end_t) --[[SOL OUTPUT--]] 

			if stat.step then
				local step_t   = analyze_expr_single(stat.step, loop_scope) --[[SOL OUTPUT--]] 
				check_num_arg('step', step_t) --[[SOL OUTPUT--]] 
				iter_t = T.combine(iter_t, step_t) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			local iter_var = declare_local(stat, loop_scope, stat.var_name) --[[SOL OUTPUT--]] 
			iter_var.type = iter_t --[[SOL OUTPUT--]] 
			iter_var.num_writes = iter_var.num_writes + 1 --[[SOL OUTPUT--]] 
			iter_var.num_reads  = iter_var.num_reads  + 1 --[[SOL OUTPUT--]]   -- Actual looping counts
			iter_var.var_type = 'Loop variable' --[[SOL OUTPUT--]] 
			
			local ret, _ = analyze_statlist(stat.body, loop_scope, scope_fun) --[[SOL OUTPUT--]] 
			discard_scope(loop_scope) --[[SOL OUTPUT--]] 
			return ret, false --[[SOL OUTPUT--]] 


		elseif stat.ast_type == 'LabelStatement' then

		elseif stat.ast_type == 'GotoStatement' then

		elseif stat.ast_type == 'Typedef' then
			analyze_typedef( stat, scope ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'ClassDeclStatement' then
			analyze_class_decl( stat, scope ) --[[SOL OUTPUT--]] 

		else
			print("Unknown AST type: ", stat.ast_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return nil, false --[[SOL OUTPUT--]]    -- Returns nothing
	end --[[SOL OUTPUT--]] 


	local function pre_analyze_statement(stat, scope)
		local is_pre_analyze = true --[[SOL OUTPUT--]] 

		if stat.ast_type == 'Typedef' then
			--analyze_typedef( stat, scope )

		elseif stat.ast_type == 'ClassDeclStatement' then
			local v = declare_var(stat, scope, stat.name, stat.is_local) --[[SOL OUTPUT--]] 
			v.forward_declared = true --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'VarDeclareStatement' then
			-- HACK for forward-declaring namespaces:
			if true then
				for _,name in ipairs(stat.name_list) do
					if not scope:get_scoped(name) then -- On double-declare of local
						local is_local = (stat.scoping ~= 'global') --[[SOL OUTPUT--]] 
						local v = declare_var(stat, scope, name, is_local) --[[SOL OUTPUT--]] 
						v.forward_declared = true --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				if #stat.name_list == 1 and #stat.init_list == 1 then
					local init = stat.init_list[1] --[[SOL OUTPUT--]] 
					if init.ast_type == 'ConstructorExpr' then
						if #init.entry_list == 0 then
							-- {}
							local is_local = (stat.scoping ~= 'global') --[[SOL OUTPUT--]] 
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
					if    stat.rhs[1].ast_type     == 'BinopExpr'
					  and stat.rhs[1].op           == 'or'
					  and stat.rhs[1].lhs.ast_type == 'IdExpr'
					  and stat.rhs[1].lhs.name     == stat.lhs[1].name
					  and not settings.is_sol
					then
						--[[
						  HACK: Foo = Foo or EXPR
						  This is a very common Lua idiom
						--]]
						local name = stat.lhs[1].name --[[SOL OUTPUT--]] 

						local v = scope:get_var( name ) --[[SOL OUTPUT--]] 
						if not v then
							sol_error(stat, "Pre-analyze: Declaring global %q", name) --[[SOL OUTPUT--]] 
							v = top_scope:create_global( name, where_is(stat) ) --[[SOL OUTPUT--]] 
							v.pre_analyzed = true --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

					elseif stat.rhs[1].ast_type      == 'CallExpr'
					  and  stat.rhs[1].base.ast_type == 'IdExpr'
					  and  stat.rhs[1].base.name     == 'class'
					  and  not settings.is_sol
					then
						--[[
						HACK: Foo = class(...)
						Common lua idiom
						--]]
						local name = stat.lhs[1].name --[[SOL OUTPUT--]] 
						local is_local = false --[[SOL OUTPUT--]] 
						local class_type = declare_class(stat, scope, name, is_local, stat.rhs[1]) --[[SOL OUTPUT--]] 
						-- Allow Foo(...):
						class_type.metatable = {
							tag='object',
							members = {
								__call = {
									tag    = 'function';
									args   = {};
									vararg = { tag='varargs', type=T.Any };
									rets   = T.AnyTypeList;
									name   = '__call';
								}
							}
						} --[[SOL OUTPUT--]] 
						local v = declare_var(stat, scope, name, is_local, class_type) --[[SOL OUTPUT--]] 
						v.type = class_type --[[SOL OUTPUT--]] 

					else
						local var_name = stat.lhs[1].name --[[SOL OUTPUT--]] 
						local v = scope:get_var( var_name ) --[[SOL OUTPUT--]] 

						if v then
							-- Assigning to something declared in an outer scope
						else
							-- Leave error reporting out of pre-analyzer
							report_error(stat, "Pre-analyze: Declaring implicit global %q", var_name) --[[SOL OUTPUT--]] 
							v = top_scope:create_global( var_name, where_is(stat) ) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						if stat.rhs[1].ast_type == 'LambdaFunctionExpr' then
							--do_assignment(stat, scope, stat.lhs[1], fun_t)
						
							if v.type then
								report_error(stat, "Cannot forward declare %q: it already has type %s", v.name, v.type) --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 

							local fun_t = analyze_function_head( stat.rhs[1], scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
							fun_t.pre_analyzed = true --[[SOL OUTPUT--]]  -- Rmember that this is a temporary 'guess'
							fun_t.where = where_is(stat) --[[SOL OUTPUT--]] 
							fun_t.name = var_name --[[SOL OUTPUT--]] 

							v.type = fun_t --[[SOL OUTPUT--]] 

							report_spam(stat, "Forward-declared %q as %s", v.name, fun_t) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'FunctionDeclStatement' then
			assert(stat.scope.parent == scope) --[[SOL OUTPUT--]] 

			assert(stat.name_expr) --[[SOL OUTPUT--]] 
			report_spam(stat, "Pre-analyzing function %s...", stat.name_expr) --[[SOL OUTPUT--]] 

			local fun_t = analyze_function_head( stat, scope, is_pre_analyze ) --[[SOL OUTPUT--]] 
			fun_t.pre_analyzed = true --[[SOL OUTPUT--]]  -- Rmember that this is a temporary 'guess'
			fun_t.where = where_is(stat) --[[SOL OUTPUT--]] 
			fun_t.name = format_expr(stat.name_expr) --[[SOL OUTPUT--]] 

			if stat.is_aggregate then
				-- function foo.bar(arg)  -- namespaced - OK
				-- function foo:bar(arg)  -- member - OK
				report_spam(stat, "Pre-analyzed function head for %q as %s", fun_t.name, fun_t) --[[SOL OUTPUT--]] 
				do_assignment(stat, scope, stat.name_expr, fun_t, is_pre_analyze) --[[SOL OUTPUT--]] 
				report_spam(stat, "Assigned.") --[[SOL OUTPUT--]] 
			else
				--[[
				local function foo()
				global function foo()

				No need to forward declare these -
				they cannot in any code that is parsed before their declaration!
				]]
				--[[
				report_spam(stat, "Pre-declaring function %q", fun_t.name)
				var v = declare_var(stat, scope, stat.name_expr.name, stat.is_local, fun_t)
				v.forward_declared = true
				--]]
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	-- Returns the list of types returned in these statements
	-- or nil if no returns statements where found
	-- Returns true if all paths returns.
	analyze_statlist = function(stat_list, scope, scope_fun)
		assert(stat_list.scope == scope) --[[SOL OUTPUT--]] 

		local return_types = nil --[[SOL OUTPUT--]] 

		-- Look for function declarations:
		-- This is so that we don't need to forward-declare functions
		-- like we have to in lesser languages.

		for _, stat in ipairs(stat_list.body) do
			pre_analyze_statement(stat, scope) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local all_paths_return = false --[[SOL OUTPUT--]] 

		for _, stat in ipairs(stat_list.body) do
			if stat.ast_type ~= 'Eof' then
				local stat_rets, stat_all_return = analyze_statement(stat, scope, scope_fun) --[[SOL OUTPUT--]] 
				return_types = T.combine_type_lists(return_types, stat_rets) --[[SOL OUTPUT--]] 

				all_paths_return = stat_all_return --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return return_types, all_paths_return --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local module_function = {
		tag = 'function',
		args = {}
		-- name = ???
		-- rets = ???
	} --[[SOL OUTPUT--]] 
	local ret, all_paths_return = analyze_statlist(ast, top_scope, module_function) --[[SOL OUTPUT--]] 

	if ret and not all_paths_return then
		report_error(ast, "Not all paths return a value, but some do") --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if _G.g_ignore_errors or error_count == 0 then
		return true, ret --[[SOL OUTPUT--]] 
	else
		return false, string.format("%i errors", error_count) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return analyze --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 