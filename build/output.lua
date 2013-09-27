--[[ DO NOT MODIFY - COMPILED FROM sol/output.sol on 2013 Sep 27  16:21:37 --]] require 'parser' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 
local U = require 'util' --[[SOL OUTPUT--]] 
local printf_err = U.printf_err --[[SOL OUTPUT--]] 

local function debug_printf(...)
	--[[
	U.printf(...)
	--]]
end --[[SOL OUTPUT--]] 

--
-- output.lua
--
-- Returns the exact source code that was used to create an AST, preserving all
-- comments and whitespace.
-- This can be used to get back a Lua source after renaming some variables in
-- an AST.
--

-- Returns the number of line breaks
local function count_line_breaks(str)
	if not str:find('\n') then
		-- Early out
		return 0 --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local n = 0 --[[SOL OUTPUT--]] 
	for i = 1,#str do
		if str:sub(i,i) == '\n' then
			n = n + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return n --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

assert(count_line_breaks("hello") == 0) --[[SOL OUTPUT--]] 
assert(count_line_breaks("hello\n") == 1) --[[SOL OUTPUT--]] 
assert(count_line_breaks("hello\nyou\ntoo") == 2) --[[SOL OUTPUT--]] 


local function output(ast, filename, strip_white_space)
	if strip_white_space == nil then
		strip_white_space = false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local out = {
		rope = {},  -- List of strings
		line = 1,

		append_str = function(self, str)
			local nl = count_line_breaks(str) --[[SOL OUTPUT--]] 
			self.line = self.line + nl --[[SOL OUTPUT--]] 
			table.insert(self.rope, str) --[[SOL OUTPUT--]] 
		end,

		append_token = function(self, token)
			self:append_white(token) --[[SOL OUTPUT--]] 

			local str  = token.data --[[SOL OUTPUT--]] 

			if not strip_white_space then
				local nl = count_line_breaks(str) --[[SOL OUTPUT--]] 

				while self.line + nl < token.line do
					--print("Inserting extra line")
					table.insert(self.rope, '\n') --[[SOL OUTPUT--]] 
					self.line = self.line + 1 --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			self:append_str(str) --[[SOL OUTPUT--]] 
		end,

		append_tokens = function(self, tokens)
			for _,token in ipairs(tokens) do
				self:append_token( token ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end,

		append_white = function(self, token)
			if token.all_leading_white then
				if not strip_white_space or #self.rope>0 then
					self:append_str( token.all_leading_white ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end
	} --[[SOL OUTPUT--]] 

	local function report_error(fmt, ...)
		local msg = string.format(fmt, ...) --[[SOL OUTPUT--]] 
		local error_msg = string.format('%s:%d: %s', filename, out.line, msg) --[[SOL OUTPUT--]] 
		printf_err( "%s\n%s", table.concat(out.rope), error_msg ) --[[SOL OUTPUT--]] 
		D.error(error_msg) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local format_statlist, format_expr --[[SOL OUTPUT--]] 

	local COMMA_SEMICOLON = U.set{",", ";"} --[[SOL OUTPUT--]] 
	local COMMA           = U.set{","} --[[SOL OUTPUT--]] 

	-- returns a structure for iterating over tokens
	local function tokens(expr)
		local it = 1 --[[SOL OUTPUT--]] 

		local t = {
		} --[[SOL OUTPUT--]] 

		function t:append_next_token(str)
			local tok = expr.tokens[it] --[[SOL OUTPUT--]] 
			if not tok then report_error("Missing token") --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			if str and tok.data ~= str then
				report_error("Expected token '" .. str .. "'. tokens: " .. U.pretty(expr.tokens)) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			out:append_token( tok ) --[[SOL OUTPUT--]] 
			it = it + 1 --[[SOL OUTPUT--]] 	
		end --[[SOL OUTPUT--]] 
		function t:append_token(token)
			out:append_token( token ) --[[SOL OUTPUT--]] 
			it = it + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		function t:append_white()
			local tok = expr.tokens[it] --[[SOL OUTPUT--]] 
			--if not tok then report_error("Missing token: %s", U.pretty(expr)) end
			if not tok then report_error("Missing token") --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			out:append_white( tok ) --[[SOL OUTPUT--]] 
			it = it + 1 --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		function t:skip_next_token()
			self:append_white() --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		function t:append_str(str)
			self:append_white() --[[SOL OUTPUT--]] 
			out:append_str(str) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		function t:inject_str(str)
			out:append_str(str) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		function t:peek()
			if it <= #expr.tokens then
				return expr.tokens[it].data --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		function t:append_comma(mandatory, seperators)
			if true then
				seperators = seperators or COMMA --[[SOL OUTPUT--]] 
				local peeked = self:peek() --[[SOL OUTPUT--]] 
				if not mandatory and not seperators[peeked] then
					return --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if not seperators[peeked] then
					report_error("Missing comma or semicolon; next token is: %s, token iterator: %i, tokens: %s",
						U.pretty( peeked ), it, U.pretty( expr.tokens )) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				self:append_next_token() --[[SOL OUTPUT--]] 
			else
				local p = self:peek() --[[SOL OUTPUT--]] 
				if p == "," or p == ";" then
					self:append_next_token() --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		function t:on_end()
			assert(it == #expr.tokens + 1) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	format_expr = function(expr)
		D.assert(expr) --[[SOL OUTPUT--]] 
		D.assert(expr.ast_type) --[[SOL OUTPUT--]] 

		local t = tokens(expr) --[[SOL OUTPUT--]] 
		--debug_printf("format_expr(%s) at line %i", expr.ast_type, expr.tokens[1] and expr.tokens[1].line or -1)

		if expr.ast_type == 'IdExpr' then
			t:append_str( expr.name ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'NumberExpr' then
			t:append_token( expr.value ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'StringExpr' then
			t:append_token( expr.value ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'BooleanExpr' then
			t:append_next_token( expr.value and "true" or "false" ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'NilExpr' then
			t:append_next_token( "nil" ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'BinopExpr' then
			format_expr(expr.lhs) --[[SOL OUTPUT--]] 
			t:append_str( expr.op ) --[[SOL OUTPUT--]] 
			format_expr(expr.rhs) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'UnopExpr' then
			t:append_str( expr.op ) --[[SOL OUTPUT--]] 
			format_expr(expr.rhs) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'DotsExpr' then
			t:append_next_token( "..." ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'CallExpr' then
			format_expr(expr.base) --[[SOL OUTPUT--]] 
			t:append_next_token( "(" ) --[[SOL OUTPUT--]] 
			for i,arg in ipairs( expr.arguments ) do
				format_expr(arg) --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #expr.arguments ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( ")" ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'TableCallExpr' then
			format_expr( expr.base ) --[[SOL OUTPUT--]] 
			format_expr( expr.arguments[1] ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'StringCallExpr' then
			format_expr(expr.base) --[[SOL OUTPUT--]] 
			--t:append_token( expr.arguments[1] )
			format_expr( expr.arguments[1] ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'IndexExpr' then
			format_expr(expr.base) --[[SOL OUTPUT--]] 
			t:append_next_token( "[" ) --[[SOL OUTPUT--]] 
			format_expr(expr.index) --[[SOL OUTPUT--]] 
			t:append_next_token( "]" ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'MemberExpr' then
			format_expr(expr.base) --[[SOL OUTPUT--]] 
			t:append_next_token() --[[SOL OUTPUT--]]   -- . or :
			t:append_token(expr.ident) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'LambdaFunctionExpr' then
			-- anonymous function
			t:append_next_token( "function" ) --[[SOL OUTPUT--]] 
			t:append_next_token( "(" ) --[[SOL OUTPUT--]] 
			if #expr.arguments > 0 then
				for i = 1, #expr.arguments do
					t:append_str( expr.arguments[i].name ) --[[SOL OUTPUT--]] 
					if i ~= #expr.arguments then
						t:append_next_token(",") --[[SOL OUTPUT--]] 
					elseif expr.vararg then
						t:append_next_token(",") --[[SOL OUTPUT--]] 
						t:append_next_token("...") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			elseif expr.vararg then
				t:append_next_token("...") --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token(")") --[[SOL OUTPUT--]] 
			format_statlist(expr.body) --[[SOL OUTPUT--]] 
			t:append_next_token("end") --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'ConstructorExpr' then
			t:append_next_token( "{" ) --[[SOL OUTPUT--]] 
			for i = 1, #expr.entry_list do
				local entry = expr.entry_list[i] --[[SOL OUTPUT--]] 
				if entry.type == 'key' then
					t:append_next_token( "[" ) --[[SOL OUTPUT--]] 
					format_expr(entry.key) --[[SOL OUTPUT--]] 
					t:append_next_token( "]" ) --[[SOL OUTPUT--]] 
					t:append_next_token( "=" ) --[[SOL OUTPUT--]] 
					format_expr(entry.value) --[[SOL OUTPUT--]] 
				elseif entry.type == 'value' then
					format_expr(entry.value) --[[SOL OUTPUT--]] 
				elseif entry.type == 'ident_key' then
					t:append_str(entry.key) --[[SOL OUTPUT--]] 
					t:append_next_token( "=" ) --[[SOL OUTPUT--]] 
					format_expr(entry.value) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #expr.entry_list, COMMA_SEMICOLON ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( "}" ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'ParenthesesExpr' then
			t:append_next_token( "(" ) --[[SOL OUTPUT--]] 
			format_expr(expr.inner) --[[SOL OUTPUT--]] 
			t:append_next_token( ")" ) --[[SOL OUTPUT--]] 

		elseif expr.ast_type == 'CastExpr' then
			format_expr(expr.expr) --[[SOL OUTPUT--]] 

		else
			printf_err("Unknown expr AST type: '%s'", expr.ast_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		t:on_end() --[[SOL OUTPUT--]] 
		debug_printf("/format_expr") --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	local format_statement = function(stat)
		local t = tokens(stat) --[[SOL OUTPUT--]] 

		--debug_printf("")
		--debug_printf(string.format("format_statement(%s) at line %i", stat.ast_type, stat.tokens and stat.tokens[1] and stat.tokens[1].line or -1))

		if stat.ast_type == 'AssignmentStatement' then
			for i,v in ipairs(stat.lhs) do
				format_expr(v) --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #stat.lhs ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			if #stat.rhs > 0 then
				t:append_next_token( "=" ) --[[SOL OUTPUT--]] 
				for i,v in ipairs(stat.rhs) do
					format_expr(v) --[[SOL OUTPUT--]] 
					t:append_comma( i ~= #stat.rhs ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'CallStatement' then
			format_expr(stat.expression) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'VarDeclareStatement' then
			if t:peek() == "local" then
				t:append_next_token( "local" ) --[[SOL OUTPUT--]] 
			elseif t:peek() == "global" then
				t:skip_next_token() --[[SOL OUTPUT--]] 
			elseif t:peek() == "var" then
				--t:skip_next_token()
				t:append_str('local') --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			for i = 1, #stat.name_list do
				t:append_str( stat.name_list[i] ) --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #stat.name_list ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			if #stat.init_list > 0 then
				t:append_next_token( "=" ) --[[SOL OUTPUT--]] 
				for i = 1, #stat.init_list do
					format_expr(stat.init_list[i]) --[[SOL OUTPUT--]] 
					t:append_comma( i ~= #stat.init_list ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'ClassDeclStatement' then
			if stat.is_local then
				t:append_str( "local" ) --[[SOL OUTPUT--]]  -- replaces 'class'
			else
				t:skip_next_token() --[[SOL OUTPUT--]]  -- skip 'global'
				t:skip_next_token() --[[SOL OUTPUT--]]  -- skip 'class'
			end --[[SOL OUTPUT--]] 
			t:append_str( stat.name ) --[[SOL OUTPUT--]] 
			t:append_next_token( "=" ) --[[SOL OUTPUT--]] 
			format_expr(stat.rhs) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'IfStatement' then
			t:append_next_token( "if" ) --[[SOL OUTPUT--]] 
			format_expr( stat.clauses[1].condition ) --[[SOL OUTPUT--]] 
			t:append_next_token( "then" ) --[[SOL OUTPUT--]] 
			format_statlist( stat.clauses[1].body ) --[[SOL OUTPUT--]] 
			for i = 2, #stat.clauses do
				local st = stat.clauses[i] --[[SOL OUTPUT--]] 
				if st.condition then
					t:append_next_token( "elseif" ) --[[SOL OUTPUT--]] 
					format_expr(st.condition) --[[SOL OUTPUT--]] 
					t:append_next_token( "then" ) --[[SOL OUTPUT--]] 
				else
					t:append_next_token( "else" ) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				format_statlist(st.body) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( "end" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'WhileStatement' then
			t:append_next_token( "while" ) --[[SOL OUTPUT--]] 
			format_expr(stat.condition) --[[SOL OUTPUT--]] 
			t:append_next_token( "do" ) --[[SOL OUTPUT--]] 
			format_statlist(stat.body) --[[SOL OUTPUT--]] 
			t:append_next_token( "end" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'DoStatement' then
			t:append_next_token( "do" ) --[[SOL OUTPUT--]] 
			format_statlist(stat.body) --[[SOL OUTPUT--]] 
			t:append_next_token( "end" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'GenericForStatement' then
			t:append_next_token( "for" ) --[[SOL OUTPUT--]] 
			for i,name in ipairs(stat.var_names) do
				t:append_str( name ) --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #stat.var_names ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( "in" ) --[[SOL OUTPUT--]] 
			for i = 1, #stat.generators do
				format_expr(stat.generators[i]) --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #stat.generators ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( "do" ) --[[SOL OUTPUT--]] 
			format_statlist(stat.body) --[[SOL OUTPUT--]] 
			t:append_next_token( "end" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'NumericForStatement' then
			t:append_next_token( "for" ) --[[SOL OUTPUT--]] 
			t:append_str( stat.var_name ) --[[SOL OUTPUT--]] 
			t:append_next_token( "=" ) --[[SOL OUTPUT--]] 
			format_expr(stat.start) --[[SOL OUTPUT--]] 
			t:append_next_token( "," ) --[[SOL OUTPUT--]] 
			format_expr(stat.end_) --[[SOL OUTPUT--]] 
			if stat.step then
				t:append_next_token( "," ) --[[SOL OUTPUT--]] 
				format_expr(stat.step) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( "do" ) --[[SOL OUTPUT--]] 
			format_statlist(stat.body) --[[SOL OUTPUT--]] 
			t:append_next_token( "end" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'RepeatStatement' then
			t:append_next_token( "repeat" ) --[[SOL OUTPUT--]] 
			format_statlist(stat.body) --[[SOL OUTPUT--]] 
			t:append_next_token( "until" ) --[[SOL OUTPUT--]] 
			format_expr(stat.condition) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'LabelStatement' then
			t:append_next_token( "::" ) --[[SOL OUTPUT--]] 
			t:append_str( stat.label ) --[[SOL OUTPUT--]] 
			t:append_next_token( "::" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'GotoStatement' then
			t:append_next_token( "goto" ) --[[SOL OUTPUT--]] 
			t:append_str( stat.label ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'ReturnStatement' then
			t:append_next_token( "return" ) --[[SOL OUTPUT--]] 
			for i = 1, #stat.arguments do
				format_expr(stat.arguments[i]) --[[SOL OUTPUT--]] 
				t:append_comma( i ~= #stat.arguments ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'BreakStatement' then
			t:append_next_token( "break" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'FunctionDeclStatement' then
			if stat.scoping == 'local' then
				t:append_next_token( "local" ) --[[SOL OUTPUT--]] 
			elseif stat.scoping == 'global' then
				t:skip_next_token() --[[SOL OUTPUT--]] 
			elseif not stat.is_aggregate then
				t:inject_str(' local ') --[[SOL OUTPUT--]]  -- turn global function into local
			end --[[SOL OUTPUT--]] 
			t:append_next_token( "function" ) --[[SOL OUTPUT--]] 
			format_expr( stat.name_expr ) --[[SOL OUTPUT--]] 

			t:append_next_token( "(" ) --[[SOL OUTPUT--]] 
			if #stat.arguments > 0 then
				for i = 1, #stat.arguments do
					t:append_str( stat.arguments[i].name ) --[[SOL OUTPUT--]] 
					t:append_comma( i ~= #stat.arguments or stat.vararg ) --[[SOL OUTPUT--]] 
					if i == #stat.arguments and stat.vararg then
						t:append_next_token( "..." ) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			elseif stat.vararg then
				t:append_next_token( "..." ) --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			t:append_next_token( ")" ) --[[SOL OUTPUT--]] 

			format_statlist(stat.body) --[[SOL OUTPUT--]] 
			t:append_next_token( "end" ) --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'Eof' then
			t:append_white() --[[SOL OUTPUT--]] 

		elseif stat.ast_type == 'Typedef' then

		else
			printf_err("Unknown stat AST type: '%s'", stat.ast_type) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		if stat.semicolon then
			t:append_next_token(";") --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		t:on_end() --[[SOL OUTPUT--]] 

		-- Ensure the lua code is easily spotted as something you shouldn't modify:
		out:append_str(" --[[SOL OUTPUT--]] ") --[[SOL OUTPUT--]] 

		debug_printf("/format_statment") --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	format_statlist = function(stat_list)
		for _, stat in ipairs(stat_list.body) do
			format_statement(stat) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	if U.is_array(ast.body) then
		format_statlist(ast) --[[SOL OUTPUT--]] 
	else
		format_expr(ast) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 


	return table.concat(out.rope) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return output --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 