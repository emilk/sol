local U   = require 'util'
local set = U.set
local T   = require 'type'
local P   = require 'parser'
local S   = require 'scope'
local D   = require 'sol_debug'


var NumOps = set{
	'+', '-', '*', '/', '%', '^'
}
var NumCompOps = set{
	'<', '<=', '>', '>='
}


local function rope_to_msg(rope: [string]) -> string
	local str = U.trim( table.concat(rope, '\n') )
	if str == '' then
		return str
	else
		return U.quote_or_indent(str)
	end
end


local function loose_lookup(table: {string => any}, id: string) -> string?
	D.assert(type(id) == 'string')

	if table[id] then
		return id
	end

	var MAX_DIST = 2

	if #id < MAX_DIST then
		-- Don't suggest 'x' over 'y'
		return nil
	end

	var edit_distance = require 'edit_distance'

	var<number>  closest_dist = math.huge
	var<string?> closest_key  = nil

	for k,_ in pairs(table) do
		D.assert(type(k) == 'string')

		var dist = edit_distance(k, id, MAX_DIST)
		if dist < MAX_DIST then
			--U.printf("Dist between '%s' and '%s' is %d", k, id, dist)
			if dist < closest_dist then
				closest_dist = dist
				closest_key = k
			end
		end
	end

	if closest_dist >= MAX_DIST then
		return nil
	end

	assert(type(closest_key) == 'string')
	return closest_key
end


local function expr2str(e: P.ExprNode) 
	var ignore_set = U.set{'var_', 'scope', 'tokens'}
	return U.serialize(e, ignore_set)
end


local function format_expr(e: P.ExprNode)
	local output = require 'output'
	local strip_white_space = true
	local str = output(e, '', strip_white_space)
	str = U.trim(str)
	return str
end


typedef OnRequireT = function(string, string) -> T.Type or T.Typelist


local function analyze(ast, filename: string, on_require: OnRequireT?, settings)
	local analyze_statlist, analyze_expr, analyze_expr_single_var, analyze_expr_single
	local analyze_expr_unchecked

	local top_scope = ast.scope  -- HACK
	local error_count = 0

	local function where_is(node: P.Node?) -> string
		if node and node.where then
			return node.where
		elseif node and node.tokens and node.tokens[1] then
			local tok = node.tokens[1]
			return string.format('%s:%i', filename, tok.line)
		else
			D.break_()
			return filename .. ':??'
		end
	end

	local function fancy_format(fmt: string, ...)
		var<[any]> buf = {}
		for i = 1, select( '#', ... ) do
			local a = select( i, ... )
			if type(a) == 'table' and a.ast_type then
				a = U.quote_or_indent( format_expr(a) )
			elseif T.is_type(a) then
 				a = U.quote_or_indent( T.name(a) )
			elseif T.is_type_list(a) then
				a = U.quote_or_indent( T.names(a) )
			elseif type( a ) ~= 'string' and type( a ) ~= 'number' then
				-- bool/table
				a = tostring( a )
			end
			buf[i] = a
		end
		return string.format( fmt, unpack( buf ) )
	end


	local function report(type: string, where: string, fmt: string, ...) -> string
		local inner_msg = fancy_format(fmt, ...)
		local msg = string.format('%s: %s: %s', type, where, inner_msg)
		return msg
	end

	local function report_spam(node: P.Node, fmt: string, ...)
		if _G.g_spam then
			print( report('Spam', where_is(node), fmt, ...) )
		end
	end

	local function report_info(node: P.Node, fmt: string, ...)
		print( report('Info', where_is(node), fmt, ...) )
	end

	local function report_warning(node: P.Node, fmt: string, ...)
		print( report('WARNING', where_is(node), fmt, ...) )
	end

	local function sol_warning(node: P.Node, fmt: string, ...)
		if settings.is_sol then
			report_warning(node, fmt, ...)
		end
	end

	local function report_error(node: P.Node, fmt, ...)
		if settings.is_sol then
			U.printf_err( "%s", report('ERROR', where_is(node), fmt, ...) )
			error_count = error_count + 1
		else
			-- Forgive lua code
			print( report('WARNING', where_is(node), fmt, ...) )
		end
	end

	local function sol_error(node: P.Node?, fmt: string, ...)
		if settings.is_sol then
			report_error(node, fmt, ...)
		end
	end

	--local member_missing_reporter = report_warning -- TODO
	local member_missing_reporter = report_spam

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



	local function discard_scope(scope: Scope)
		for _,v in scope:locals_iterator() do
			if v.name ~= '_' then
				local var_type = v.var_type or 'Variable'
				if v.num_reads == 0 then
					if v.type and v.type.tag == 'function' then
						print( report('WARNING', v.where, "Unused function %q", v.name) )
					else
						local warning_name = (var_type == 'Argument' and 'unused-parameter' or 'unused-variable')
						if g_warnings[warning_name] then
							print( report('WARNING', v.where, "%s %q is never read (use _ to silence this warning)", var_type, v.name) )
						end
					end
				end
				if v.num_writes == 0 then
					print( report('WARNING', v.where, "%s %q is never written to (use _ to silence this warning)", var_type, v.name) )
				end
			end
		end
	end


	-- second bool: returns true if all paths returns
	local function analyze_closed_off_statlist(stat_list: P.Statlist, scope_fun: T.Function) -> T.Typelist?, bool
		return analyze_statlist(stat_list, stat_list.scope, scope_fun)
	end



	local function declare_local(node: P.Node, scope: Scope, name: string, typ: T.Type?) -> Variable
		D.assert(node and scope and name)
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		var old = scope:get_scoped(name)

		if old and old.forward_declared then
			old.forward_declared = false -- Properly declared now
			-- TODO: move to proper scope!
			assert(not old.is_global)
			assert(old.scope == scope)
			old.where = where_is(node) -- Update position of forward-declare
			old.type  = typ or old.type
			return old
		end

		if old then
			if name ~= "st" and name ~= "_" then  -- HACK
				report_error(node, "%q already declared in this scope, in %s", name, old.where)
			end
			return old
		end

		report_spam(node, "Declaring local %q", name)
		local v = scope:create_local(name, where_is(node))
		v.type = typ
		return v
	end

	local function declare_global(node, scope: Scope, name: string, typ: T.Type?) -> Variable
		D.assert(type(name) == 'string')
		--report_spam('Declaring variable %q in scope %s', name, tostring(scope))

		if name ~= '_' then
			if not scope:is_module_level() then
				sol_error(node, "Global variables should be declared in the top scope")
			end
		end

		var<Variable?> old = scope:get_var(name)

		if old and old.forward_declared then
			old.forward_declared = false -- Properly declared now
			-- TODO: move to proper scope!
			assert(old.is_global)
			assert(old.scope == scope)
			old.where = where_is(node) -- Update position of forward-declare
			old.type  = typ or old.type
			return old
		end

		if old then
			report_error(node, "global %q already declared in %s", name, old.where)
			return old
		end

		report_spam(node, "Declaring global %q", name)
		return scope:create_global(name, where_is(node), typ)
	end

	local function declare_var(node: P.Node, scope: Scope, name: string, is_local: bool, typ: T.Type?) -> Variable
		if is_local then
			return declare_local(node, scope, name, typ)
		else
			return declare_global(node, scope, name, typ)
		end
	end


	local function check_type_is_a(msg: string, expr: P.Node, expr_type: T.Type, expected_type: T.Type, severity: 'warning' or 'error')
		if T.could_be(expr_type, expected_type) then
			return true
		else
			var<[string]> error_rope = {}
			T.could_be(expr_type, expected_type, error_rope)
			local error_msg = rope_to_msg(error_rope)
			var reporter = (severity == 'error' and report_error or report_warning)
			reporter(expr, "%s: Expected type %s, got %s: %s", msg, T.name(expected_type), T.name(expr_type), error_msg)
			return false
		end
	end


	analyze_expr = function(expr: P.Node, scope: Scope) --> T.Typelist, Variable?  -- TODO
		local types, var_ = analyze_expr_unchecked(expr, scope)

		D.assert(T.is_type_list(types))

		return types, var_
	end


	-- Will make sure to return a single type, never void or multiple returns
	analyze_expr_single_var = function(expr: P.ExprNode, scope: Scope) -> T.Type, Variable?
		local t,v = analyze_expr(expr, scope)
		if t == T.AnyTypeList then
			return T.Any, v
		end

		if #t == 0 then
			report_error(expr, "Analyzing '%s' expression: Expected type, got void", expr.ast_type)
			return T.Any, v
		elseif #t == 1 then
			return t[1], v
		else
			report_error(expr, "When analyzing '%s' expression: Expected single type, got: %s", expr.ast_type, t)
			return T.Any, v
		end
	end

	analyze_expr_single = function(expr: P.ExprNode, scope: Scope) -> T.Type
		-- Ignore the variable
		var t,_ = analyze_expr_single_var(expr, scope)
		return t
	end


	local function check_return_types(node, does_return: T.Typelist, should_return: T.Typelist?)
		if should_return then
			assert(T.is_type_list(does_return))
			assert(T.is_type_list(should_return))

			if not T.could_be_tl(does_return, should_return) then
				var<[string]> problem_rope = {}
				T.could_be_tl(does_return, should_return, problem_rope)
				local problem_str = rope_to_msg(problem_rope)
				report_error(node, "Return statement does not match function return type declaration, returns: %s, expected: %s.\n%s", does_return, should_return, problem_str)
			end
		end
	end


	local function analyze_expr_single_custom(expr, scope: Scope, is_pre_analyze: bool) -> T.Type, Variable?
		if is_pre_analyze then
			if expr.ast_type == 'IdExpr' then
				local base_var = scope:get_var( expr.name )

				if base_var then
					return base_var.type or T.Any, base_var
				else
					report_error(expr, "Pre-analyzer: Unknown identifier %q", expr.name)
					return T.Any, nil
				end

			else
				return T.Any, nil
			end
		else
			return analyze_expr_single_var(expr, scope)
		end
	end

	 
	-- analyze a function declaration head - either a named one or a lambda function
	local analyze_function_head = function(node: P.Node, scope: Scope, is_pre_analyze: bool) -> T.Function
		assert(node.return_types == nil or T.is_type_list(node.return_types))

		var<T.Function> fun_t = {
			tag = 'function',
			args = {},
			rets = node.return_types  -- If any
		}

		if node.is_mem_fun then
			local name_expr = node.name_expr
			assert(name_expr.ast_type == 'MemberExpr' and name_expr.indexer == ':')
			local self_type,_ = analyze_expr_single_custom(name_expr.base, scope, is_pre_analyze)
			if self_type.instance_type then
				report_spam(node, "Class method detected - setting 'self' type as the instance type")
				self_type = self_type.instance_type
			end
			table.insert(fun_t.args, {name = 'self', type = self_type})

			node.self_var_type = self_type  -- Assign a type to the local 'self' variable

			--report_spam(node, "self: '%s'", self_type)
		end

		for _,arg in ipairs(node.arguments) do
			table.insert(fun_t.args, {name = arg.name, type = arg.type or T.Any})
		end

		if node.vararg then
			fun_t.vararg = node.vararg
		end

		report_spam(node, "analyze_function_head: %s", fun_t)

		return fun_t
	end

	--[[ Will analyze body and check its return-statements against fun_t.
	     If fun_t.rets is nil (no type deduced) then this function will fill it in via deduction.
	--]]
	local function analyze_function_body(node: P.Node, scope: Scope, fun_t: T.Function)
		if not node.body then
			-- body-less function - used by lua_intrinsics.sol
			return
		end

		local func_scope = node.scope

		-- Declare arguments as variables:
		if node.is_mem_fun then
			assert(node.self_var_type) -- Set by analyze_function_head
			var v = declare_local(node, func_scope, 'self')
			v.type = node.self_var_type
			v.num_writes = 1
			v.num_reads  = 1  -- It must have been for the function to be found (silences warnings)
			v.var_type = 'Argument'
		end

		for _,arg in ipairs(node.arguments) do
			var v = declare_local(node, func_scope, arg.name)
			v.type = arg.type
			v.num_writes = 1
			v.var_type = 'Argument'
		end

		if node.vararg then
			var v = declare_local(node, func_scope, '...')
			v.type = node.vararg
			v.num_writes = 1
			v.var_type = 'Argument'
			assert(T.is_type(v.type))
		end

		---

		var ret_t, all_paths_return = analyze_statlist(node.body, func_scope, fun_t)
		discard_scope(func_scope)

		if fun_t.rets then
			if ret_t and not T.could_be_tl(ret_t, fun_t.rets) then
				report_error(node, "Return statement(s) does not match function return type declaration, returns: %s, expected: %s",
					T.name(ret_t), T.name(fun_t.rets))
			end

			if fun_t.rets ~= T.Void and fun_t.rets ~= T.AnyTypeList and not all_paths_return then
				report_error(node, "Not all paths returns - expected %s", fun_t.rets)
			end
		else
			-- Deduce return type:
			if ret_t then
				if not all_paths_return and #ret_t > 0 then
					ret_t = U.shallow_clone(ret_t)
					for ix,_ in ipairs(ret_t) do
						ret_t[ix] = T.make_nilable(ret_t[ix])
					end
				end
				fun_t.rets = ret_t

				if fun_t.rets ~= T.Void and fun_t.rets ~= T.AnyTypeList and not all_paths_return then
					report_error(node, "Not all paths returns")
				end
			else
				fun_t.rets = T.Void  -- No returns  == void
			end
			--report_spam(node, 'function deduced return type: %s', fun_t.rets)
		end
	end


	local function check_arguments(expr, fun_t: T.Function, arg_ts: [T.Type]) -> bool
		assert(fun_t.args)
		var fun_name = fun_t.name or "<lambda>"
		D.assert(type(fun_name) == 'string', "fun_name: %s", fun_name)
		local all_passed = false

		-- check arguments:
		local i = 1
		while true do
			--report_spam(expr, "Checking argument %i", i)

			if i <= #fun_t.args then
				if fun_t.args[i].name == 'self' and i ~= 1 then
					report_error(expr, "%s: 'self' must be the first arguemnt", fun_name)
					all_passed = false
				end

				local expected = fun_t.args[i].type

				if i <= #arg_ts then
					local given = arg_ts[i]

					if given.tag == 'varargs' then
						-- When calling with ..., if ... is empty we get nil:s
						given = T.variant(given.type, T.Nil)
						-- TODO: if last given, match against epxected
					end

					--report_spam(expr, "Checking argument %i: can we convert from '%s' to '%s'?", i, given, expected)


					if T.is_variant(given) then
						-- ensure  string?  ->  int?   does NOT pass
						given = T.variant_remove(given, T.Nil)
					end

					--report_info(expr, "Checking argument %i: could %s be %s ?", i, T.name(arg_ts[i]), expected)
					
					if not T.could_be(given, expected) then
						local problem_rope = {}
						T.could_be(given, expected, problem_rope)
						local err_msg = rope_to_msg(problem_rope)
						report_error(expr, "%s: argument %i: could not convert from %s to %s: %s",
						                    fun_name, i, given, expected, err_msg)
						all_passed = false
					end
				else
					if i == 1 and fun_t.args[i].name == 'self' then
						report_error(expr, "%s: Missing object argument ('self'). Did you forget to call with : ?", fun_name)
						all_passed = false
					elseif not T.is_nilable(expected) then
						report_error(expr, "%s: Missing non-nilable argument %i: expected %s", fun_name, i, expected)
						all_passed = false
					elseif _G.g_spam then
						report_spam(expr, "%s: Ignoring missing argument %i: it's nilable: %s", fun_name, i, expected)
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

					report_spam(expr, "Check varargs. Given: %s, expected %s", given, expected)

					if given.tag == 'varargs' then
						given = given.type
					end

					if not T.could_be(given, expected) then
						report_error(expr, "%s: argument %i: could not convert from %s to varargs %s",
							                 fun_name, i, given, expected)
						all_passed = false
					end
				else
					report_error(expr, "%s: Too many arguments - got %i, expected %i", fun_name, #arg_ts, #fun_t.args)
					all_passed = false
				end
			else
				break
			end

			i = i + 1
		end

		return all_passed
	end


	local function do_member_lookup(node: P.Node, type: T.Type, name: string, suggestions: [string]) -> T.Type?
		--report_spam(node, "Looking for member %q in %s", name, type)

		type = T.follow_identifiers(type)

		if type.tag == 'variant' then
			local indexed_type = nil

			for _,v in ipairs(type.variants) do
				indexed_type = T.variant(indexed_type, do_member_lookup(node, v, name, suggestions))
			end

			return indexed_type
		elseif type.tag == 'object' then
			var<T.Object> obj = type
			local indexed_type = obj.members[name]

			if not indexed_type and obj.metatable then
				local indexer = obj.metatable.members['__index']
				if indexer then
					if indexer.tag == 'function' then
						report_spam(node, "metatable has __index function")
						-- First member is the 'self'

						local ignore_indexer = false
						var given_t = {tag='string_literal', value=name}

						var<T.Function> indexer_fun = indexer
						if #indexer_fun.args == 2 then
							var expected_t = indexer_fun.args[2].type
							if not T.isa(given_t, expected_t) then
								-- e.g. indexer only accepts "x" or "y" or "z"
								-- Ignoring mis-matches gives much better error messages
								ignore_indexer = true
							end
						else
							if not check_arguments(node, indexer_fun, { T.Any, given_t }) then
								ignore_indexer = true
							end
						end

						if not ignore_indexer then
							if indexer_fun.rets and #indexer_fun.rets > 0 then
								return indexer_fun.rets[1]
							else
								-- TODO: warnings should be written on __index set
								report_error(node, "Unexpected __index function - no returns values")
								return T.Any
							end
						end
					else
						report_spam(node, "Looking up member %q in metatbale __index", name)
						return do_member_lookup(node, indexer, name, suggestions)
					end
				end
			end

			if not indexed_type and obj.class_type then
				indexed_type = do_member_lookup(node, obj.class_type, name, suggestions)
			end

			indexed_type = T.broaden( indexed_type ) -- Previous value may have been 'false' - we should allow 'true' now:

			if obj.derived then
				for _,v in ipairs(obj.derived) do
					indexed_type = T.variant(indexed_type, do_member_lookup(node, v, name, suggestions))
				end
			end

			if not indexed_type then
				local close_name = loose_lookup(obj.members, name)

				if close_name then
					suggestions[#suggestions + 1] = close_name
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


	local function generator_types(expr, fun_t, arg_ts: [T.Type]) -> [T.Type]
		--------------------------------------------------------
		-- SPECIAL: 'pairs':
		if fun_t.intrinsic_name == 'pairs' then
			if #arg_ts ~= 1 then
				report_error(expr, "Too many arguments to 'pairs'")
			else
				local function pairs_type(typ, error_rope: [string]?) -> T.Typelist?
					typ = T.follow_identifiers(typ)

					if typ == T.Any or typ.tag == 'table' then
						return { T.Any, T.Any }
					elseif typ.tag == 'object' then
						return { T.String, T.Any }
					elseif typ.tag == 'map' then
						if typ.value_type == T.True then
							-- A set!
							return { typ.key_type }
						else
							return { typ.key_type, typ.value_type }
						end
					elseif typ.tag == 'list' then
						--report_warning(expr, "Calling 'pairs' on a list - did you mean to use 'ipairs'?")
						report_error(expr, "Calling 'pairs' on a list - did you mean to use 'ipairs'?")
						assert( typ.type )
						return { T.Uint, typ.type }
					elseif typ.tag == 'variant' then
						var<T.Typelist?> types = nil

						for _,v in ipairs(typ.variants) do
							types = T.combine_type_lists(types, pairs_type(v, error_rope))
						end

						assert(types == nil  or  #types == 2)
						return types
					else
						if error_rope then
							table.insert(error_rope, string.format("Incompatible type: '%s'", T.name(typ)))
						end
						return nil
					end
				end

				local types = pairs_type( arg_ts[1] )
				if types then
					assert(#types == 2)
					return types
				else
					var<[string]> error_rope = {}
					pairs_type( arg_ts[1], error_rope )
					report_error(expr, "'pairs' called on incompatible type: " .. rope_to_msg(error_rope))
					return { T.Any, T.Any }
				end
			end
		end


		--------------------------------------------------------
		-- SPECIAL: 'ipairs':
		if fun_t.intrinsic_name == 'ipairs' then
			if #arg_ts ~= 1 then
				report_error(expr, "Too many arguments to 'ipairs'")
			else
				local function ipairs_type(typ, error_rope: [string]) -> T.Typelist?
					typ = T.follow_identifiers(typ)

					if typ == T.Any then
						return {T.Uint, T.Any}
					elseif typ.tag == 'table' or T.is_empty_table(typ) then
						sol_warning(expr, "Calling 'ipairs' on unknown table")
						return {T.Uint, T.Any} -- Presumably a list?
					elseif typ.tag == 'list' then
						return {T.Uint, typ.type}
					elseif typ.tag == 'variant' then
						var<T.Typelist?> types = nil

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

				var<[string]> error_rope = {}
				local types = ipairs_type( arg_ts[1], error_rope )
				if types then
					assert(#types == 2)
					return types
				else
					report_error(expr, "'ipairs' called on incompatible type: " .. rope_to_msg(error_rope))
					return { T.Uint, T.Any }
				end
			end
		end

		--------------------------------------------------------

		return T.AnyTypeList
	end


	local function analyze_require( module_name: string, req_where: string )
		return T.as_type_list( on_require( module_name, req_where ) )  -- TODO: remove as_type_list
	end


	local function handle_setmetatable(expr: P.Node, args: [P.Node], arg_ts: [T.Type]) -> void
		if #args ~= 2 then
			return
		end

		if args[1].ast_type ~= 'IdExpr' then
			report_warning(expr, "setmetatable: first argument must be an identifier, got %s", args[1].ast_type)
			return
		end

		if arg_ts[2].tag ~= 'object' then
			report_warning(expr, "setmetatable: second argument must be an object")
			return
		end

		var<Variable> target_var = args[1].variable
		D.assert(target_var)
		local target_type = target_var.type

		if target_type then
			target_type = T.follow_identifiers( target_type )
		end

		if not target_type or target_type.tag == 'table' then
			target_type = { tag = 'object', members = {} }
		end

		if target_type.tag ~= 'object' then
			report_error(expr, "setmetatable: first argument must name an object; got: %s", target_type)
			return
		end

		if not T.should_extend_in_situ(target_type) then
			target_type = U.shallow_clone(target_type)
		end
		target_type.metatable = arg_ts[2]

		report_spam(expr, "Setting metatable")

		target_var.type = target_type
	end


	local function analyze_fun_call(expr: P.Node, typ: T.Type, args: [P.Node], arg_ts: [T.Type], report_errors: bool) -> T.Typelist?
		report_spam(expr, "analyze_fun_call, typ: %s", typ)
		report_spam(expr, "analyze_fun_call, arg_ts: %s", arg_ts)

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
			var<T.Typelist?> ret = nil

			for _,v in ipairs(typ.variants) do
				ret = T.combine_type_lists(ret, analyze_fun_call(expr, v, args, arg_ts, report_errors))
			end

			D.assert( T.is_type_list(ret) )
			return ret
		end

		if typ.tag ~= 'function' then
			if report_errors then
				report_error(expr, "Not a function: %s", typ)
			end
			return nil
		end

		var<T.Function> fun_t = typ
		D.assert(fun_t.name)

		--------------------------------------------------------
		-- Check special functions:

		if fun_t.intrinsic_name == 'require' then
			if #arg_ts == 1 and arg_ts[1].tag == 'string_literal' then
				--U.printf('"require" called with argument: %q', arg_ts[1])
				if on_require then
					return analyze_require( arg_ts[1].value, where_is(expr) )
				end
			else
				report_warning(expr, '"require" called with indeducible argument')
			end
		end

		--------------------------------------------------------

		if fun_t.intrinsic_name == 'pairs' or fun_t.intrinsic_name == 'ipairs' then
			-- generators returns function that returns 'it_types':
			local it_types = generator_types(expr, fun_t, arg_ts)

			var<T.Function> ret = {
				tag    = 'function',
				args   = {},
				vararg = { tag='varargs', type=T.Any },
				rets   = it_types,
				name   = '<pairs/ipairs iterator>',
			}
			return { ret }
		end

		--------------------------------------------------------

		if fun_t.intrinsic_name == 'setmetatable' then
			handle_setmetatable(expr, args, arg_ts)
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
	local function call_function(expr: P.Node, scope: Scope) -> T.Typelist
		--------------------------------------------------------
		-- Pick out function type:
		report_spam(expr, "Analyzing function base...")
		local fun_type = analyze_expr_single(expr.base, scope)
		report_spam(expr, "function base analyzed.")

		--------------------------------------------------------
		-- get argument types (they will be evaluated regardless of function type):

		var<[P.ExprNode]> args = U.shallow_clone( expr.arguments )

		var called_as_mem_fun = (expr.base.ast_type == 'MemberExpr' and expr.base.indexer == ':')

		if called_as_mem_fun then
			local obj_expr = expr.base.base
			table.insert(args, 1, obj_expr)
		end

		var<[T.Type]> arg_ts = {}
		for ix,v in ipairs(args) do
			if ix < #args then
				arg_ts[ix] = analyze_expr_single(v, scope)
			else
				-- Last argument may evaluate to several values
				local types = analyze_expr(v, scope)
				if types == T.AnyTypeList then
					arg_ts[ix] = { tag = 'varargs', type = T.Any }
				elseif #types == 0 then
					report_error(expr, "Last argument evaluates to no values")
				else
					for _,t in ipairs(types) do
						table.insert(arg_ts, t)
					end
				end
			end
		end

		--------------------------------------------------------
		-- Do we know the function type?

		local function try_call(typ: T.Type, report_errors: bool) -> T.Typelist?
			typ = T.follow_identifiers(typ)

			if T.is_any(typ) then
				-- TODO: Upgrade to a warning!
				report_spam(expr, "Function call cannot be deduced - calling something of unknown type: %s", fun_type)
				return T.AnyTypeList

			elseif typ.tag == 'function' then
				var<T.Function> fun_t = typ
				local is_mem_fun = (#fun_t.args > 0 and fun_t.args[1].name == 'self')

				if called_as_mem_fun and not is_mem_fun then
					report_error(expr, "Calling non-member function as member function")
				end

				if not called_as_mem_fun and is_mem_fun then
					local first_is_self = (#args>0 and args[1].ast_type == 'IdExpr' and args[1].name == 'self')
					if first_is_self then
						-- Foo.bar(self)  is considered calling is as a member function
					else
						report_warning(expr, "Member function called as non-member function")
					end
					--report_info(expr, "expr.base.ast_type: " .. expr.base.ast_type)
					--report_info(expr, "expr.base.indexer: " .. expr2str(expr.base.indexer))
				end

				local rets = analyze_fun_call(expr, fun_t, args, arg_ts, report_errors)
				D.assert( rets==nil or T.is_type_list(rets) )
				return rets

			elseif typ.tag == 'variant' then
				var<T.Typelist?> rets = nil
				for _,v in ipairs(typ.variants) do
					local list = try_call(v, report_errors)
					rets = T.combine_type_lists(rets, list)
				end
				D.assert( T.is_type_list(rets) )
				return rets

			elseif typ.tag == 'object' and typ.metatable and typ.metatable.members['__call'] then
				report_spam(expr, "__call")
				var<T.Type> call_t = typ.metatable.members['__call']

				var ext_args   = U.list_concat({expr.base}, args)
				var ext_arg_ts = U.list_concat({fun_type}, arg_ts)

				var rets = analyze_fun_call(expr, call_t, ext_args, ext_arg_ts, report_errors)
				D.assert( rets==nil or T.is_type_list(rets) )
				return rets

			elseif report_errors then
				report_error(expr, "Cannot call %s", typ)
				return nil
			else
				return nil
			end
		end

		local rets = try_call(fun_type, false)

		if rets then
			report_spam(expr, "Function deduced to returning: %s", rets)
			D.assert( T.is_type_list(rets) )
			return rets
		else
			-- Show errors:
			report_error(expr, "Cannot call %s", fun_type)
			try_call(fun_type, true)
			return T.AnyTypeList
		end
	end



	-- for k,v in some_expr
	-- this functions returns a list of types for k,v in the example above
	local function extract_iterator_type(expr: P.Node, scope: Scope) -> [T.Type]
		report_spam(expr, "extract_iterator_type...")

		--[-[
		var<T.Typelist> types = analyze_expr(expr, scope)
		if types == T.AnyTypeList then
			-- e.g.   for line in src:gmatch("[^\n]*\n?") do
			return T.AnyTypeList
		end
		local gen_t = types[1]
		--]]	
		--local gen_t = analyze_expr_single(expr, scope) -- TODO: var

		D.assert(gen_t)

		report_spam(expr, "extract_iterator_type, gen_t: %s", gen_t)

		gen_t = T.follow_identifiers(gen_t)
		if gen_t == T.Any then
			return T.AnyTypeList
		end

		if gen_t.tag ~= 'function' then
			var<string> suggestion = 'pairs'
			if T.isa(gen_t, T.List) then
				suggestion = 'ipairs'
			end

			report_error(expr, "Generator function expected, got %s - did you forget to use '%s'?", gen_t, suggestion)

			return T.AnyTypeList
		end

		var<T.Function> fun_t = gen_t

		var arg_ts = {} : [T.Type]
		for i = 2,#types do
			arg_ts[i-1] = types[i]
		end
		check_arguments(expr, fun_t, arg_ts)

		return fun_t.rets or T.AnyTypeList
	end



	local analyze_simple_expr_unchecked


	analyze_expr_unchecked = function(expr: P.Node, scope: Scope) -> T.Typelist, Variable?
		assert(expr)
		assert(type(expr) == 'table')
		assert(expr.ast_type)

		report_spam(expr, "Analyzing %s...", expr.ast_type)


		if expr.ast_type == 'IdExpr' then
			if expr.name == '_' then
				report_error(expr, "You may not read from discard variable '_'")
			end

			var<Variable?> var_ = scope:get_var( expr.name, 'ignore_fwd_decl' )

			if var_ then
				if var_.forward_declared then
					report_error(expr, "Use of forward-declared variable %q, forward-declared in %s",
						expr.name, var_.where)
				end

				var_.num_reads = var_.num_reads + 1
			else
				if expr.name ~= '_' then  -- Implicit '_' var is OK
					report_error(expr, "Implicit global %q", expr.name)
				end
				var_ = top_scope:create_global( expr.name, where_is(expr) )
			end

			--report_spam(expr, "IdExpr '%s': var_.type: '%s'", var_.name, var_.type)

			local type = var_.type or T.Any
			if var_.namespace then
				var_.type = var_.type or T.Object
				type = var_.type

				if T.is_empty_table(type) then
					type = {
						tag     = 'object';
						members = {};
					}
				end

				if type.tag == 'object' then
					if type.namespace then
						assert(type.namespace == var_.namespace)
					else
						if T.should_extend_in_situ(type) then
							type.namespace = var_.namespace
						else
							type = U.shallow_clone(type)
							type.namespace = var_.namespace
							var_.type = type
						end
					end
				else
					report_error(expr, "Variable %q used as namespace but is not an object - it's %s", var_.name, type)
					var_.namespace = nil -- Only warn once
				end
			end
			
			--report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.ast_type, type)

			--D.assert(T.is_type(type)  or  T.is_type_list(type))
			D.assert( T.is_type(type) )

			-- Store for quick access later on:
			expr.variable = var_

			return { type }, var_

		-- Anything that can return multiple values:
		elseif expr.ast_type == 'CallExpr' then        -- foo(arg, ...)
			--U.printf('CallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope), nil

		elseif expr.ast_type == 'TableCallExpr' then   -- foo{arg}
			--U.printf('TableCallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope), nil


		elseif expr.ast_type == 'StringCallExpr' then  -- foo'arg'
			--U.printf('StringCallExpr, base: %q, args: %q', expr2str(expr.base), expr2str(expr.arguments))
			return call_function(expr, scope), nil

		else
			local type = analyze_simple_expr_unchecked(expr, scope)

			report_spam(expr, "analyze_expr_unchecked('%s'): '%s'", expr.ast_type, type)
			D.assert(T.is_type(type))

			return { type }, nil
		end
	end

	-- Return type
	analyze_simple_expr_unchecked = function(expr: P.ExprNode, scope: Scope) -> T.Type
		if expr.ast_type == 'NumberExpr' then
			local str = expr.value.data
			local t = T.from_num_literal( str )
			if t then
				return t
			else
				report_error(expr, 'Failed to parse number: %q', str)
				return T.Num
			end


		elseif expr.ast_type == 'StringExpr' then
			return T.from_string_literal( expr.value.data )


		elseif expr.ast_type == 'BooleanExpr' then
			assert(expr.value == true or expr.value == false)
			if expr.value == true then
				return T.True
			else
				return T.False
			end


		elseif expr.ast_type == 'NilExpr' then
			return T.Nil


		elseif expr.ast_type == 'ExternExpr' then
			-- Definitions is in C - could be anything
			return T.Any


		elseif expr.ast_type == 'BinopExpr' then
			local op = expr.op
			local lt = analyze_expr_single( expr.lhs, scope )
			local rt = analyze_expr_single( expr.rhs, scope )

			--report_spam(expr, "Binop: %s %s %s", lt, op, rt)

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
					report_error(expr, "Comparing incompatible types: %s and %s", lt, rt)
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
					report_warning(expr, "Operator 'and' expected boolean expression to the left, got %s", lt)
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
					report_warning(expr, "Operator 'or' expected boolean expression to the left, got %s", lt)
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
				report_error(expr, "Unknown binary operator %q", expr.op)
				return T.Any
			end


		elseif expr.ast_type == 'UnopExpr' then
			local arg_t = analyze_expr_single(expr.rhs, scope)

			if expr.op == '-' then
				if T.could_be(arg_t, T.Num) then
					return T.Num
				elseif T.could_be(arg_t, T.Int) then
					return T.Int
				else
					report_error(expr, "Unary minus expected numeric argument, got %s", arg_t)
					return T.Num -- Good guess
				end

			elseif expr.op == 'not' then
				if not T.is_useful_boolean(arg_t) then
					report_warning(expr, "'not' operator expected boolean or nil:able, got %s", arg_t)
				end
				return T.Bool

			elseif expr.op == '#' then
				if not T.could_be(arg_t, T.List) and not T.could_be(arg_t, T.String) then
					report_error(expr, "'#' operator expected list or string, got %s", arg_t)
				end
				return T.Uint

			else
				report_error(expr, 'Unknown operator %q', expr.op)
				return T.Any
			end


		elseif expr.ast_type == 'DotsExpr' then
			var v = scope:get_local('...')
			if v then
				v.num_reads = v.num_reads + 1
				var t = v.type
				assert(t)
				if t then
					assert(t.tag == 'varargs')
					return t
				else
					return {
						tag  = 'varargs',
						type = T.Any 
					}
				end
			else
				report_error(expr, "No ... in scope")
				return {
					tag  = 'varargs',
					type = T.Any 
				}
			end


		elseif expr.ast_type == 'IndexExpr' then
			-- base[index]
			-- TODO: var
			local base_t  = analyze_expr_single(expr.base, scope)
			local index_t = analyze_expr_single(expr.index, scope)

			if T.is_any(base_t) then
				return T.Any
			end

			if T.is_empty_table(base_t) then
				-- Indexing what? We don't know
				sol_warning(expr, 'Indexing unkown table')
				return T.Any
			end

			local list = T.find(base_t, T.List) -- TODO: find all lists and variant the reuslts
			if list then
				report_spam(expr, "List index")
				check_type_is_a("List index", expr.index, index_t, T.Uint, 'error')
				if list.type then
					report_spam(expr, "List index: indexing %s, element type is %s", list, list.type)
					return list.type
				else
					return T.Any -- FIXME
				end
			end

			local map = T.find(base_t, T.Map) -- TODO: find all maps and variant the results
			if map then
				report_spam(expr, "Map index")
				check_type_is_a("Map index", expr.index, index_t, map.key_type, 'error')
				return T.variant(map.value_type, T.Nil)  -- Nil on not found
			end

			if T.find(base_t, T.Table) then
				report_spam(expr, "Table index")
				return T.Any
			end

			report_error(expr, 'Cannot index type %s with %s - not a list, table or map', base_t, index_t)
			--error("FATAL")
			return T.Any


		elseif expr.ast_type == 'MemberExpr' then
			-- .  or  :
			local base_t = analyze_expr_single(expr.base, scope)
			local name = expr.ident.data

			if T.is_any(base_t) then
				return T.Any
			else
				var suggestions = {} : [string]
				local t = do_member_lookup(expr, base_t, name, suggestions)
				if t then
					return t
				else
					if #suggestions > 0 then
						report_warning(expr, "Failed to find member %q (%s) - did you mean %s?", name, expr, table.concat(suggestions, " or "))
					else
						member_missing_reporter(expr, "Failed to find member %q (%s)", name, expr) -- TODO: warn
					end
					return T.Any
				end
			end


		elseif expr.ast_type == 'LambdaFunctionExpr' then
			-- Lambda function
			local is_pre_analyze = false
			local fun_t = analyze_function_head( expr, scope, is_pre_analyze )
			fun_t.name = '<lambda>'
			analyze_function_body( expr, scope, fun_t )
			return fun_t


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
				report_spam(expr, "Explicit type missing - is this an empty table, list, map, object - what?")
				return T.create_empty_table()
			else
				var map_keys    = {} : {string or number or int}
				var key_type    = T.make_variant() -- in maps
				var value_type  = T.make_variant()
				var obj_members = {} : {string => T.Type}

				local count = { ['key'] = 0, ['ident_key'] = 0, ['value'] = 0 }
				for _,e in ipairs(expr.entry_list) do
					count[e.type] = count[e.type] + 1

					local this_val_type = analyze_expr_single(e.value, scope)
					if this_val_type.tag == 'varargs' then
						this_val_type = this_val_type.type -- Many of these
					end

					value_type = T.extend_variant( value_type, this_val_type )

					if e.type == 'key' then
						local this_key_type = analyze_expr_single(e.key, scope)
						key_type = T.extend_variant( key_type, this_key_type )

						if this_key_type.tag == 'int_literal' or
						   this_key_type.tag == 'num_literal' or
						   this_key_type.tag == 'string_literal'
						then
							if map_keys[ this_key_type.value ] then
								report_error(e.value, "Map key %q declared twice", this_key_type.value)
							end
							map_keys[ this_key_type.value ] = true
						end
					end

					if e.type == 'ident_key' then
						if obj_members[ e.key ] then
							report_error(e.value, "Object member %q declared twice", e.key)
						end
						obj_members[ e.key ] = this_val_type
					end
				end

				key_type   = T.simplify( key_type )
				value_type = T.simplify( value_type )

				if count['key'] == #expr.entry_list then
					-- A map
					return {
						tag        = 'map',
						key_type   = key_type,
						value_type = value_type
					}

				elseif count['value'] == #expr.entry_list then
					-- A list
					return {
						tag  = 'list',
						type = value_type
					}

				elseif count['ident_key'] == #expr.entry_list then
					return {
						tag     = 'object',
						members = obj_members
					}

				else
					if count['value'] == 0 then
						report_error(expr, "Mixed initialization - please use [] on everything or nothing")
					else
						report_error(expr, "Mixed initialization - all or none of the values must have explicit keys")
					end

					return T.Any
				end
			end


		elseif expr.ast_type == 'ParenthesesExpr' then
			local t = analyze_expr_single( expr.inner, scope )
			return t

		elseif expr.ast_type == 'CastExpr' then
			local expr_type = analyze_expr_single( expr.expr, scope )
			local cast_to   = expr.type
			check_type_is_a("Cast", expr, expr_type, cast_to, 'error')
			return cast_to

		else
			print("Unknown expression AST type: ", expr.ast_type)
		end

		report_error(expr, "Failed to figure out type of %s", expr.ast_type)

		return T.Any
	end


	-- eg:  check_condition('while', some_expr, scope)
	-- examples:   if some_expr then ...
	-- examples:   while true then ...
	local check_condition = function(name, expr, scope: Scope)
		local t = analyze_expr_single(expr, scope)

		if expr.ast_type == 'BooleanExpr' then
			-- 'true' or 'false' as explicit argument - that's OK
			-- e.g. for   while true do  ... break ... end
		else
			if not T.is_useful_boolean(t) then
				report_error(expr, "Not a useful boolean expression in %q, type is %s", name, t)
			end
		end

		return t
	end


	local function decl_var_type(stat, var_, deduced_type: T.Type)
		D.assert( T.is_type(deduced_type) )

		if deduced_type.tag == 'function' and deduced_type.name == '<lambda>' then
			-- Give the lmabda-function a more helpful name:
			deduced_type.name = var_.name
		end

		if var_.type then
			-- .type must have been deduced by pre-parsing
			check_type_is_a("Variable declaration", stat, deduced_type, var_.type, 'error')
		else
			if deduced_type == T.Nil then
				--sol_warning(stat, "Initializing value with nil - type cannot be deduced")
				var_.type  = T.Nilable
			else
				var_.type  = T.broaden( deduced_type )
			end
		end

		var_.namespace = deduced_type.namespace  -- If any
		var_.num_writes = var_.num_writes + 1
	end


	local function assign_to_obj_member(stat: P.Node, _: Scope,
		                                 is_pre_analyze: bool, is_declare: bool, extend_existing_type: bool,
		                                 obj_t: T.Object, name: string, right_type: T.Type) -> T.Type
	 											--> T.Type -- TODO: have this here


		report_spam(stat, "Exisiting object")

		local left_type = obj_t.members[name]

		if left_type and left_type.pre_analyzed then
			if right_type.pre_analyzed and is_pre_analyze then
				report_error(stat, "Name clash: %q, previously declared in %s", name, left_type.where)
			else
				D.assert(not right_type.pre_analyzed)
			end

			-- The member type was reached by the pre-analyzer - overwrite with refined info:
			
			--obj_t.members[name] = nil  -- TODO: makes compilation hang!
			left_type = nil

			report_spam(stat, "Replacing pre-analyzed type with refined type: %s", right_type)
		end

		if left_type then
			report_spam(stat, "Object already has member")
			left_type = T.broaden( left_type ) -- Previous value may have been 'false' - we should allow 'true' now:

			if not T.could_be(right_type, left_type) then
				report_error(stat, "[B] type clash: cannot assign to %q (of type %s) with %s", name, left_type, right_type)
			end

			return obj_t
		else
			if not obj_t.members[name] then
				if not is_declare then
					local close_name = loose_lookup(obj_t.members, name)

					if close_name then
						report_warning(stat, "Could not find %q - Did you mean %q?", name, close_name)
					end
				end

				report_spam(stat, "Adding member")
			end

			--[[
			We do not broaden the type here, to make sure the following code works:

			typedef Foo = { tag : 'foo '}

			function fun() -> Foo
				local ret = {}
				ret.tag = 'foo'  -- No broadeding! tag is 'foo', not string
				return ret
			end
			--]]

			--extend_existing_type = true -- HACK FIXME TODO osv

			if extend_existing_type then
				report_spam(stat, "Extending class with %q - class: %s", name, tostring(obj_t))

				--[[
				var foo = Foo:new()
				if ... then
					foo.name = "hello"
				end

				-- Don't change 'Foo' to having a member:  name: string
				-- Just add an optional member:            name: string?
				--]]
				if not T.is_class(right_type) then
					right_type = T.make_nilable(right_type)
				end

				obj_t.members[name] = right_type
			else
				D.assert(not T.should_extend_in_situ(obj_t))
				obj_t = U.shallow_clone( obj_t )
				obj_t.members = U.shallow_clone( obj_t.members )
				obj_t.members[name] = right_type
			end

			return obj_t
		end
	end


	local function do_assignment(stat: P.Node, scope: Scope, left_expr: P.Node, right_type: T.Type, is_pre_analyze: bool)
		assert(not T.is_type_list(right_type))

		if right_type.tag == 'function' and right_type.name == '<lambda>' then
			-- Give the lmabda-function a more helpful name:
			right_type.name = format_expr(left_expr)
		end

		var is_declare = (stat.ast_type == 'FunctionDeclStatement')

		if right_type.namespace then
			report_error(stat, "Cannot assign namespace outside of declaration")
		end

		report_spam(stat, 'do_assignment, left_expr.ast_type: %s', left_expr.ast_type)

		if left_expr.ast_type == 'MemberExpr' then
			-- foo.bar = ...
			local name = left_expr.ident.data

			local base_t, base_var = analyze_expr_single_custom(left_expr.base, scope, is_pre_analyze)

			if base_var then
				-- self.foo = 32 will actually add the member 'foo' to the class definition!
				-- think ctors and the like
				var extend_existing_type = (base_var.name == 'self')


				if not base_var.type or T.is_empty_table(base_var.type) then
					report_spam(stat, "New object")
					base_var.type = { tag = 'object', members = {} }
					extend_existing_type = false -- bad idea
				end

				report_spam(stat, "Assigning to %s.%s", base_var.name, name)

				local var_t = T.follow_identifiers(base_var.type)

				if var_t.tag == 'variant' then
					--var extend_variant_member = extend_existing_type
					var extend_variant_member = false

					var variant = T.clone_variant(var_t)

					-- TODO: recurse
					for i,v in ipairs(variant.variants) do
						if v.tag == 'object' then
							variant.variants[i] = assign_to_obj_member(stat, scope,
								                                        is_pre_analyze, is_declare, extend_variant_member,
								                                        v, name, right_type)	
						end
					end
				elseif var_t.tag == 'object' then
					var extend_object = extend_existing_type or T.is_class(var_t) or T.is_instance(var_t)

					base_var.type = assign_to_obj_member(stat, scope,
						                                 is_pre_analyze, is_declare, extend_object,
						                                 var_t, name, right_type)	
					return
				elseif T.is_any(var_t) then
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					sol_warning(stat, "[B] Trying to index type 'any' with %q", name)
				else
					-- not an object? then no need to extend the type
					-- eg.   local foo = som_fun()   foo.var_ = ...
					report_warning(stat, "[B] Trying to index non-object of type %s with %q", var_t, name)
					--D.break_()
				end

			else -- no variable we can update the type of
				-- e.g.:   foo.bar.baz
				report_warning(stat, "Left hand side of assignment: tried to index non-variable: %s", left_expr.base)
				assert(base_t)
				base_t = T.follow_identifiers(base_t)
				--assert(base_t ~= T.EmptyTable)

				if base_t.tag == 'object' then
					report_spam(stat, "Exisiting object")

					local left_type = base_t.members[name]

					if left_type and left_type.pre_analyzed then
						-- The member type was reached by the pre-analyzer - overwrite with refined info:
						assert(not right_type.pre_analyzed)
						--var_t.members[name] = nil  -- TODO: makes compilation hang!
						left_type = nil

						report_spam(stat, "Replacing pre-analyzed type with refined type: %s", right_type)
					end

					if left_type then
						report_spam(stat, "Object already has member")
						left_type = T.broaden( left_type ) -- Previous value may have been 'false' - we should allow 'true' now:

						if not T.could_be(right_type, left_type) then
							report_error(stat, "[A] type clash: cannot assign to %q (of type %s) with %s", name, left_type, right_type)
							return false
						else
							return true
						end
					else
						if not is_declare and not base_t.members[name] then
							local close_name = loose_lookup(base_t.members, name)

							if close_name then
								report_warning(stat, "Could not find %q - Did you mean %q?", name, close_name)
							end
						end

						report_spam(stat, "Adding member")
						report_warning(stat, "Adding member %q to %q", name, base_t)

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
					sol_warning(stat, "[A] Trying to index type 'any' with %q", name)
				else
					report_warning(stat, "[A] Trying to index non-object of type %s with %q", base_t, name)
				end
			end
		end

		if left_expr.ast_type == 'IndexExpr' then
			-- foo[bar] = ...  -- TODO
		end

		if left_expr.ast_type == 'IdExpr' and left_expr.name == '_' then
			-- Assigning to _ is always OK
			return true
		end

		local left_type, left_var = analyze_expr_single_var( left_expr, scope )

		if left_var then
			left_var.num_writes = left_var.num_writes + 1
		end

		if left_type.namespace then
			report_error(stat, "Cannot assign to a namespace outside of declaration")
		end

		if left_type.is_pre_analyze or (left_var and left_var.is_pre_analyze) then
			if left_var then
				left_var.type = right_type
			end
		else
			if settings.is_sol then -- TODO: lua too!
				--if not T.isa(right_type, left_type) then
				if not T.could_be(right_type, left_type) then
					local problem_rope = {}
					T.could_be(right_type, left_type, problem_rope)
					local problem_str = rope_to_msg(problem_rope)
					report_error(stat, "[C] type clash: cannot assign to type %s with %s: %s", left_type, right_type, problem_str)
					return false
				end
			end
		end
		return true
	end


	local function analyze_typedef(stat: P.Node, scope: Scope)
		local name = stat.type_name

		if stat.namespace_name then
			var v = scope:get_var( stat.namespace_name ) -- TODO: var

			if not v then
				report_error(stat, "namespaced typedef: %s is not a previously defined variable", stat.namespace_name)
				return
			end

			v.namespace = v.namespace or {}
			local ns = v.namespace
			if ns[name] then
				report_error(stat, "type %s.%s already declared as %s", v.name, name, ns[name])
			end

			if stat.type then
				report_spam(stat, "Declaring type %s.%s as %s", v.name, name, stat.type)
			else
				report_spam(stat, "Forward-declaring type %s.%s", v.name, name)
			end

			ns[name] = stat.type
		else
			local old = scope:get_scoped_type(name)
			if old then
				report_error(stat, "type %q already declared as %s", name, old)
			end
			scope:declare_type(name, stat.type, where_is(stat), stat.is_local)
		end

		if stat.base_types and #stat.base_types > 0 then
			report_spam(stat, "%s inherits %i types", name, #stat.base_types)

			local child_type = T.follow_identifiers(stat.type)

			if child_type.tag ~= 'object' then
				report_error(stat, "Only objects can have base-types - child: %s", child_type)
			else
				for _,base in ipairs(stat.base_types) do
					report_spam(stat, "%s inheriting %s", name, base.name)

					if base.tag ~= 'identifier' then
						report_error(stat, "You can only inherit other typedef:s")
						break
					end

					local base_type = T.follow_identifiers(base)
					if base_type.tag ~= 'object' then
						report_error(stat, "%q cannot inherit non-object %s", name, base)
						break
					end

					for id,id_type in pairs(base_type.members) do
						if child_type.members[id] then
							if not T.isa(child_type.members[id], id_type) then
								report_error(stat, "Child type %s overrides %q with differing type.", name, id)
							end
						else
							-- Inherit:
							child_type.members[id] = id_type
						end
					end

					base_type.derived = base_type.derived or {}
					table.insert(base_type.derived, stat.type)
				end
			end
		end
	end

	-- returns the CLASS type
	local function declare_class(stat: P.Node, scope: Scope, name: string, is_local: bool, rhs: P.Node) -> T.Type
		report_spam(stat, "Declaring class %q", name)

		-------------------------------------------------
		-- Start with declaring the type:

		local old = scope:get_scoped_type(name)
		if old then
			report_error(stat, "class type %q already declared as %q", name, old)
		end
		var class_type = {
			tag     = 'object',
			members = {},
		}

		var instance_type = {
			tag        = 'object',
			members    = {},
			class_type = class_type,
		}

		class_type.instance_type = instance_type

		-- The name refers to the *instance* type.
		scope:declare_type(name, instance_type, where_is(stat), is_local)

		-------------------------------------------------

		local rhs_type = analyze_expr_single(rhs, scope)
		check_type_is_a("Class declaration", stat, rhs_type, T.Table, 'error')

		-------------------------------------------------
		return class_type
	end

	local function analyze_class_decl(stat: P.Node, scope: Scope)
		local name     = stat.name
		local is_local = stat.is_local

		var class_type = declare_class(stat, scope, name, is_local, stat.rhs)

		-- Now for the variable:
		-- The variable represents the class - not an instance of it!
		var v = declare_var(stat, scope, name, is_local, class_type)
		D.assert(v.type == class_type)
	end


	-- Returns a list of types the statement returns to scope_fun
	-- If the second return is 'true', all possible code paths return at some point.
	-- Else nil
	-- 'scope_fun' contains info about the enclosing function
	local analyze_statement = function(stat: P.StatNode, scope: Scope, scope_fun: T.Function) -> T.Typelist?, bool
		assert(scope)
		var is_pre_analyze = false

		report_spam(stat, "analyze_statement %s", stat.ast_type)

		if stat.ast_type == 'AssignmentStatement' then
			local nlhs = #stat.lhs
			local nrhs = #stat.rhs
			assert(nrhs > 0)

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
				var name = stat.lhs[1].name
				var type_expr = stat.rhs[1].rhs
				var rt = analyze_expr_single(type_expr, scope)
				do_assignment(stat, scope, stat.lhs[1], rt, is_pre_analyze)

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
				var name = stat.lhs[1].name
				var is_local = false
				var class_type = declare_class(stat, scope, name, is_local, stat.rhs[1])
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
				}
				var v = declare_var(stat, scope, name, is_local, class_type)
				v.type = class_type -- FIXME

			elseif nrhs == 1 then
				local rt = analyze_expr(stat.rhs[1], scope)
				if rt == T.AnyTypeList then
					var N = nlhs
					for i=1,N do
						do_assignment(stat, scope, stat.lhs[i], T.Any, is_pre_analyze)
					end
				else
					if nlhs > #rt then
						report_error(stat, "Unequal number of variables and values: left hand side has %i variables, right hand side evaluates to %s", nlhs, rt)
					elseif nlhs < #rt then
						report_warning(stat, "Assignment discards values: left hand side has %i variables, right hand side evaluates to %s", nlhs, rt)
					end

					var N = math.min(nlhs, #rt)
					for i=1,N do
						do_assignment(stat, scope, stat.lhs[i], rt[i], is_pre_analyze)
					end
				end

			elseif nlhs ~= nrhs then
				report_error(stat, "Unequal number of variables and values")

			else
				for i = 1,nrhs do
					local rti = analyze_expr_single(stat.rhs[i], scope)
					do_assignment(stat, scope, stat.lhs[i], rti, is_pre_analyze)
				end
			end

		elseif stat.ast_type == 'CallStatement' then
			analyze_expr(stat.expression, scope)


		elseif stat.ast_type == 'VarDeclareStatement' then
			report_spam(stat, "VarDeclareStatement")

			-- Analyze init_list before declaring variables to prevent
			-- local x = x

			var<[T.Type]> init_types = {}

			if #stat.init_list == 1 then
				init_types = analyze_expr( stat.init_list[1], scope )
			else
				for _,exp in ipairs(stat.init_list) do
					init_types[#init_types + 1] = analyze_expr_single( exp, scope )
				end
			end

			var explicit_types = stat.type_list

			-- Declare variables:
			var is_local = (stat.scoping ~= 'global')
			var<[Variable]> vars = {}
			for _,name in ipairs(stat.name_list) do
				report_spam(stat, "Declaration: %s %s", stat.type, name)
				local v = declare_var(stat, scope, name, is_local)
				--v.type = nil -- Ignore any forward-deduced type

				v.var_type = (is_local and 'Local variable' or 'Global variable')

				vars[#vars + 1] = v
			end

			if explicit_types then
				if #explicit_types ~= 1 and #explicit_types ~= #vars then
					report_error(stat, "Uneven number of explicit types (%i) and variables (%i) in 'local' declaration. Either supply just one type, or one type per variable.", #explicit_types, #vars)
				end

				if #explicit_types == 1 and #explicit_types ~= #vars then
					-- One type to be applied to all - just duplicate: 

					explicit_types = U.shallow_clone( explicit_types )

					while #explicit_types < #vars do
						table.insert(explicit_types, explicit_types[1])
					end
				end

				local N = #vars
				for i = 1,N do
					var v = vars[i]
					v.type = explicit_types[i]
				end
			end

			if #stat.init_list == 0 then
				-- local a,b
				if stat.scoping == 'var' then
					report_error(stat, "'var' must be initialized at declaration")
				elseif explicit_types then
					for _,v in ipairs(vars) do
						if not T.is_nilable(v.type) then
							report_error(stat, "Variable %q of non-nilable type %s missing its definition", v.name, v.type)
						end
					end
				else
					for _,v in ipairs(vars) do
						if not v.type then   -- It could have a forward-type (local foo; foo = function() ... )
							sol_warning(stat, "Un-initialized local - type cannot be deduced!")
							v.type = T.Nilable
						end
					end
				end

			elseif #stat.init_list == 1 then
				-- local a,b = foo()
				if init_types == T.AnyTypeList then
					-- Nothing to do
					for _,v in ipairs(vars) do
						v.num_writes = v.num_writes + 1
					end
				else
					local nt = #init_types
					
					if #vars < nt then
						-- Ignoring a few return values is OK
						report_warning(stat, "Declaration discards values: left hand side has %i variables, right hand side evaluates to %s", #vars, init_types)
						--report_spam(stat, "Declaration discards values: left hand side has %i variables, right hand side evaluates to %s", #vars, init_types)
					elseif #vars > nt then
						report_error(stat, "Too many variables in 'local' declaration. Right hand side has type %s",
							T.name(init_types))
					end

					local N = math.min(nt, #vars)
					for i = 1,N do
						local v = vars[i]
						decl_var_type(stat, v, init_types[i])
					end
				end
			elseif #vars ~= #stat.init_list then
				-- local a,b,c = 1,2
				report_error(stat, "Uneven number of variables and values in local declaration. Variables: %i, inits: %i",
					#vars, #stat.init_list)
			else
				-- local a,b,c = 1,2,3
				local N = #vars
				for i = 1,N do
					local v = vars[i]
					local deduced_type = init_types[i]
					assert( T.is_type(deduced_type) )
					decl_var_type(stat, v, deduced_type)
				end
			end

			if stat.scoping == 'var' and not explicit_types then
				for _,v in ipairs(vars) do
					if v.type==nil or T.is_any(v.type) then
						report_error(stat, "Undeducible type - the type of a 'var' must be compile-time deducible")
					end
				end
			end


		elseif stat.ast_type == 'IfStatement' then
			local ret = nil
			local all_paths_return = true

			for i = 1, #stat.clauses do
				local st = stat.clauses[i]
				if i == 1 then
					check_condition( 'if',     st.condition, scope )
				elseif st.condition then
					check_condition( 'elseif', st.condition, scope )
				end
				var clause_ret, clause_returns = analyze_closed_off_statlist( st.body, scope_fun )
				ret = T.combine_type_lists(ret, clause_ret)
				if not clause_returns then
					all_paths_return = false
				end
			end

			return ret, all_paths_return


		elseif stat.ast_type == 'WhileStatement' then
			local cond_t = check_condition( 'while', stat.condition, scope )
			local ret, always_return = analyze_closed_off_statlist(stat.body, scope_fun)

			if cond_t == T.True then
				-- while true:  Infinite loop
				if always_return then
					return ret, true
				else
					-- Do we return - don't know - depends on wether there is a goto or a break
					-- Assume 'yes' to silence warnings
					return ret, true
				end
			else
				return ret, false
			end


		elseif stat.ast_type == 'DoStatement' then
			local ret, all_paths_return = analyze_closed_off_statlist(stat.body, scope_fun)
			return ret, all_paths_return


		elseif stat.ast_type == 'ReturnStatement' then
			var<[T.Type]?> what_to_return = nil
			if #stat.arguments == 0 then
				what_to_return = T.Void
			elseif #stat.arguments == 1 then
				what_to_return = analyze_expr( stat.arguments[1], scope )
			else
				var<[T.Type]> type_list = {}
				for i = 1, #stat.arguments do
					local t = analyze_expr_single( stat.arguments[i], scope )
					type_list[i] = t
				end
				what_to_return = type_list
			end
			--if scope_fun then
				check_return_types(stat, what_to_return, scope_fun.rets)
			--end
			return what_to_return, true

		elseif stat.ast_type == 'BreakStatement' then
			-- TODO

		elseif stat.ast_type == 'RepeatStatement' then
			var loop_scope = stat.scope
			var ret, _ = analyze_statlist(stat.body, loop_scope, scope_fun)
			check_condition( 'repeat', stat.condition, loop_scope )
			discard_scope(loop_scope)
			return ret, false

		elseif stat.ast_type == 'FunctionDeclStatement' then
			assert(stat.scope.parent == scope)
			var is_pre_analyze = false
			var fun_t = analyze_function_head( stat, scope, is_pre_analyze )
			fun_t.name = format_expr(stat.name_expr)

			--[[ Assign type before recursing on body.
			     This is so that recursive function can typecheck the calls to itself
			]]--
			if stat.is_aggregate then
				-- function foo:bar(arg)
				if stat.name_expr.ast_type ~= 'MemberExpr' then
					-- e.g.  "function foo(bar)"
					report_warning(stat, "non-local function, name: %q", fun_t.name)
				end
				do_assignment(stat, scope, stat.name_expr, fun_t, is_pre_analyze)
			else
				--[[ e.g:
					"local function foo(bar)"
					"global function foo(bar)"
				--]]
				report_spam(stat, "free function, name: %q", fun_t.name)

				var v = declare_var(stat, scope, stat.name_expr.name, stat.is_local, fun_t)
				v.num_writes = v.num_writes + 1
				v.var_type = 'Function'
			end

			-- Now analyze body:
			analyze_function_body( stat, scope, fun_t )


		elseif stat.ast_type == 'GenericForStatement' then
			var loop_scope = stat.scope
			assert(loop_scope.parent == scope)

			if #stat.generators > 1 then
				report_warning(stat, "Sol currently only support one generator")
			end

			local types = extract_iterator_type( stat.generators[1], scope )

			if types ~= T.AnyTypeList then
				if #types ~= #stat.var_names then
					report_error(stat, "Expected %i loop variables", #types)
				end
			end

			for i = 1,#stat.var_names do
				local v = declare_local(stat, loop_scope, stat.var_names[i])
				v.num_writes = v.num_writes + 1
				v.var_type = 'Loop variable'
				if types ~= T.AnyTypeList then
					v.type = types[i]
				end
			end

			local ret, _ = analyze_statlist(stat.body, loop_scope, scope_fun)
			discard_scope(loop_scope)
			return ret, false


		elseif stat.ast_type == 'NumericForStatement' then
			var loop_scope = stat.scope
			assert(loop_scope.parent == scope)

			local function check_num_arg(what, t: T.Type)
				if not T.isa(t, T.Num) then
					report_error(stat, "Numeric for loop expected numeric %s, got %s", what, t)
				end
			end

			local start_t = analyze_expr_single(stat.start, loop_scope)
			local end_t   = analyze_expr_single(stat.end_, loop_scope)

			check_num_arg('start', start_t)
			check_num_arg('end',   end_t)

			local iter_t = T.combine(start_t, end_t)

			if stat.step then
				local step_t   = analyze_expr_single(stat.step, loop_scope)
				check_num_arg('step', step_t)
				iter_t = T.combine(iter_t, step_t)
			end

			local iter_var = declare_local(stat, loop_scope, stat.var_name)
			iter_var.type = iter_t
			iter_var.num_writes = iter_var.num_writes + 1
			iter_var.num_reads  = iter_var.num_reads  + 1  -- Actual looping counts
			iter_var.var_type = 'Loop variable'
			
			local ret, _ = analyze_statlist(stat.body, loop_scope, scope_fun)
			discard_scope(loop_scope)
			return ret, false


		elseif stat.ast_type == 'LabelStatement' then

		elseif stat.ast_type == 'GotoStatement' then

		elseif stat.ast_type == 'Typedef' then
			analyze_typedef( stat, scope )

		elseif stat.ast_type == 'ClassDeclStatement' then
			analyze_class_decl( stat, scope )

		else
			print("Unknown AST type: ", stat.ast_type)
		end

		return nil, false   -- Returns nothing
	end


	local function pre_analyze_statement(stat: P.StatNode, scope: Scope)
		var is_pre_analyze = true

		if stat.ast_type == 'Typedef' then
			--analyze_typedef( stat, scope )

		elseif stat.ast_type == 'ClassDeclStatement' then
			var v = declare_var(stat, scope, stat.name, stat.is_local)
			v.forward_declared = true

		elseif stat.ast_type == 'VarDeclareStatement' then
			-- HACK for forward-declaring namespaces:
			if true then
				for _,name in ipairs(stat.name_list) do
					var is_local = (stat.scoping ~= 'global')
					var v = declare_var(stat, scope, name, is_local)
					v.forward_declared = true
				end
			else
				if #stat.name_list == 1 and #stat.init_list == 1 then
					local init = stat.init_list[1]
					if init.ast_type == 'ConstructorExpr' then
						if #init.entry_list == 0 then
							-- {}
							var is_local = (stat.scoping ~= 'global')
							var v = declare_var(stat, scope, stat.name_list[1], is_local)
							v.forward_declared = true
						end
					end
				end
			end

		elseif stat.ast_type == 'AssignmentStatement' then
			-- Could be a    foo = function( ... )   where foo has been forward declared earlier without a type

			if #stat.lhs == 1 and #stat.rhs == 1 then
				if stat.lhs[1].ast_type == 'IdExpr' then
					var var_name = stat.lhs[1].name
					var v = scope:get_var( var_name )

					if v then
						-- Assigning to something declared in an outer scope
					else
						-- Leave error reporting out of pre-analyzer
						report_error(stat, "Pre-analyze: Declaring implicit global %q", var_name)
						v = top_scope:create_global( var_name, where_is(stat) )
					end

					if stat.rhs[1].ast_type == 'LambdaFunctionExpr' then
						--do_assignment(stat, scope, stat.lhs[1], fun_t)
					
						if v.type then
							report_error(stat, "Cannot forward declare %q: it already has type %s", v.name, v.type)
						end

						local fun_t = analyze_function_head( stat.rhs[1], scope, is_pre_analyze )
						fun_t.pre_analyzed = true -- Rmember that this is a temporary 'guess'
						fun_t.where = where_is(stat)
						fun_t.name = var_name

						v.type = fun_t

						report_spam(stat, "Forward-declared %q as %s", v.name, fun_t)
					end
				end
			end

		elseif stat.ast_type == 'FunctionDeclStatement' then
			assert(stat.scope.parent == scope)

			assert(stat.name_expr)
			report_spam(stat, "Pre-analyzing function %s...", stat.name_expr)

			local fun_t = analyze_function_head( stat, scope, is_pre_analyze )
			fun_t.pre_analyzed = true -- Rmember that this is a temporary 'guess'
			fun_t.where = where_is(stat)
			fun_t.name = format_expr(stat.name_expr)

			if stat.is_aggregate then
				-- function foo.bar(arg)  -- namespaced - OK
				-- function foo:bar(arg)  -- member - OK
				report_spam(stat, "Pre-analyzed function head for %q as %s", fun_t.name, fun_t)
				do_assignment(stat, scope, stat.name_expr, fun_t, is_pre_analyze)
				report_spam(stat, "Assigned.")
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
			end
		end
	end


	-- Returns the list of types returned in these statements
	-- or nil if no returns statements where found
	-- Returns true if all paths returns.
	analyze_statlist = function(stat_list: P.Statlist, scope: Scope, scope_fun: T.Function) -> [T.Type]?, bool -- TODO: try T.Typelist instead of [T.Type]
		assert(stat_list.scope == scope)

		local return_types = nil

		-- Look for function declarations:
		-- This is so that we don't need to forward-declare functions
		-- like we have to in lesser languages.

		for _, stat in ipairs(stat_list.body) do
			pre_analyze_statement(stat, scope)
		end

		var all_paths_return = false

		for _, stat in ipairs(stat_list.body) do
			if stat.ast_type ~= 'Eof' then
				var stat_rets, stat_all_return = analyze_statement(stat, scope, scope_fun)
				return_types = T.combine_type_lists(return_types, stat_rets)

				all_paths_return = stat_all_return
			end
		end

		return return_types, all_paths_return
	end


	local module_function = {
		tag = 'function',
		args = {}
		-- name = ???
		-- rets = ???
	}
	local ret, all_paths_return = analyze_statlist(ast, top_scope, module_function)

	if ret and not all_paths_return then
		report_error(ast, "Not all paths return a value, but some do")
	end

	if _G.g_ignore_errors or error_count == 0 then
		return true, ret
	else
		return false, string.format("%i errors", error_count)
	end
end

return analyze
