require 'parser'
local L = require 'lexer' -- L.Token
local D = require 'sol_debug'
local U = require 'util'
local printf_err = U.printf_err
local count_line_breaks = U.count_line_breaks

local function debug_printf(...)
	--[[
	U.printf(...)
	--]]
end

--
-- output.lua
--
-- Returns the exact source code that was used to create an AST, preserving all
-- comments and whitespace.
-- This can be used to get back a Lua source after renaming some variables in
-- an AST.
--


assert(count_line_breaks("hello") == 0)
assert(count_line_breaks("hello\n") == 1)
assert(count_line_breaks("hello\nyou\ntoo") == 2)


local function output(ast, filename: string, strip_white_space : bool?) -> string
	if strip_white_space == nil then
		strip_white_space = false
	end

	--[[
	Set of tokens for which we have already written the leadign whitespace.
	We need to keep track of this since otherwise we would stuff like:


	-- Comment
	a += 1

	   ->

	-- Comment
	a =
	-- Comment
	a + 1

	--]]
	var has_written_white = {} : {L.Token}

	local out = {
		rope = {},  -- List of strings
		line = 1,

		append_str = function(self, str: string)
			self.rope #= str
			self.line += count_line_breaks(str)
		end,

		append_token = function(self, token)
			self:append_white(token)

			local str  = token.data

			if strip_white_space then
				self.rope #= str
				self.line += count_line_breaks(str)
			else
				local lines_in_str = count_line_breaks(str)

				if g_align_lines then
					while self.line + lines_in_str < token.line do
						--print("Inserting extra line")
						self.rope #= '\n'
						self.line += 1
					end
				end

				self.rope #= str
				self.line += lines_in_str
			end
		end,

		append_white = function(self, token)
			if not token.leading_white then
				return
			end
			if strip_white_space and #self.rope==0 then
				return
			end

			if has_written_white[token] then
				self:append_str( " " )
			else
				self:append_str( token.leading_white )
				has_written_white[token] = true
			end
		end
	}

	local function report_error(fmt: string, ...)
		local msg = string.format(fmt, ...)
		local error_msg = string.format('%s:%d: %s', filename, out.line, msg)
		printf_err( "%s\n%s", table.concat(out.rope), error_msg )
		D.error(error_msg)
	end


	local format_statlist, format_expr

	var COMMA_SEMICOLON = U.set{",", ";"}
	var COMMA           = U.set{","}

	-- returns a structure for iterating over tokens
	local function tokens(expr)
		local it = 1

		local t = {}

		function t:append_next_token(str: string?)
			--[[
			if not tok then report_error("Missing token") end
			if str and tok.data ~= str then
				report_error("Expected token '" .. str .. "'. tokens: " .. U.pretty(expr.tokens))
			end
			out:append_token( tok )
			it +=  1
			--]]
			if str then
				self:append_str(str)
			else
				local tok = expr.tokens[it]
				if not tok then report_error("Missing token") end
				if str and tok.data ~= str then
					report_error("Expected token '" .. str .. "'. tokens: " .. U.pretty(expr.tokens))
				end
				out:append_token( tok )
				it +=  1
			end
		end
		function t:append_token(token: L.Token)
			out:append_token( token )
			it +=  1
		end
		function t:append_white_for_next_token()
			local tok = expr.tokens[it]
			if tok then
				out:append_white( tok )
			end
		end
		function t:append_white()
			local tok = expr.tokens[it]
			if tok then
				out:append_white( tok )
				it +=  1
			else
				--report_error("Missing token")
				out:append_str(" ")
			end
		end
		function t:skip_next_token()
			self:append_white()
		end
		function t:append_str(str: string)
			self:append_white()
			out:append_str(str)
		end
		function t:inject_str(str: string)
			out:append_str(str)
		end
		function t:peek() -> string
			if it <= #expr.tokens then
				return expr.tokens[it].data
			end
		end
		function t:append_comma(mandatory: bool, seperators: {string}?) -> void
			if true then
				seperators = seperators or COMMA
				local peeked = self:peek()
				if not mandatory and not seperators[peeked] then
					return
				end
				if not seperators[peeked] then
					report_error("Missing comma or semicolon; next token is: %s, token iterator: %i, tokens: %s",
						U.pretty( peeked ), it, U.pretty( expr.tokens ))
				end
				self:append_next_token()
			else
				local p = self:peek()
				if p == "," or p == ";" then
					self:append_next_token()
				end
			end
		end

		function t:on_end()
			assert(it == #expr.tokens + 1)
		end

		return t
	end


	format_expr = function(expr) -> void
		D.assert(expr)
		D.assert(expr.ast_type)

		local t = tokens(expr)
		--debug_printf("format_expr(%s) at line %i", expr.ast_type, expr.tokens[1] and expr.tokens[1].line or -1)

		if expr.ast_type == 'IdExpr' then
			t:append_str( expr.name )

		elseif expr.ast_type == 'NumberExpr' then
			t:append_str( expr.value )

		elseif expr.ast_type == 'StringExpr' then
			t:append_str( expr.str_quoted )

		elseif expr.ast_type == 'BooleanExpr' then
			t:append_next_token( expr.value and "true" or "false" )

		elseif expr.ast_type == 'NilExpr' then
			t:append_next_token( "nil" )

		elseif expr.ast_type == 'BinopExpr' then
			format_expr(expr.lhs)
			t:append_str( expr.op )
			format_expr(expr.rhs)

		elseif expr.ast_type == 'UnopExpr' then
			t:append_str( expr.op )
			format_expr(expr.rhs)

		elseif expr.ast_type == 'DotsExpr' then
			t:append_next_token( "..." )

		elseif expr.ast_type == 'CallExpr' then
			format_expr(expr.base)
			t:append_next_token( "(" )
			for i,arg in ipairs( expr.arguments ) do
				format_expr(arg)
				t:append_comma( i ~= #expr.arguments )
			end
			t:append_next_token( ")" )

		elseif expr.ast_type == 'TableCallExpr' then
			format_expr( expr.base )
			format_expr( expr.arguments[1] )

		elseif expr.ast_type == 'StringCallExpr' then
			format_expr(expr.base)
			--t:append_token( expr.arguments[1] )
			format_expr( expr.arguments[1] )

		elseif expr.ast_type == 'IndexExpr' then
			format_expr(expr.base)
			t:append_next_token( "[" )
			format_expr(expr.index)
			t:append_next_token( "]" )

		elseif expr.ast_type == 'MemberExpr' then
			format_expr(expr.base)
			t:append_next_token()  -- . or :
			t:append_token(expr.ident)

		elseif expr.ast_type == 'LambdaFunctionExpr' then
			-- anonymous function
			t:append_next_token( "function" )
			t:append_next_token( "(" )
			if #expr.arguments > 0 then
				for i = 1, #expr.arguments do
					t:append_str( expr.arguments[i].name )
					if i ~= #expr.arguments then
						t:append_next_token(",")
					elseif expr.vararg then
						t:append_next_token(",")
						t:append_next_token("...")
					end
				end
			elseif expr.vararg then
				t:append_next_token("...")
			end
			t:append_next_token(")")
			format_statlist(expr.body)
			t:append_next_token("end")

		elseif expr.ast_type == 'ConstructorExpr' then
			t:append_next_token( "{" )
			for i = 1, #expr.entry_list do
				local entry = expr.entry_list[i]
				if entry.type == 'key' then
					t:append_next_token( "[" )
					format_expr(entry.key)
					t:append_next_token( "]" )
					t:append_next_token( "=" )
					format_expr(entry.value)
				elseif entry.type == 'value' then
					format_expr(entry.value)
				elseif entry.type == 'ident_key' then
					t:append_str(entry.key)
					t:append_next_token( "=" )
					format_expr(entry.value)
				end
				t:append_comma( i ~= #expr.entry_list, COMMA_SEMICOLON )
			end
			t:append_next_token( "}" )

		elseif expr.ast_type == 'ParenthesesExpr' then
			t:append_next_token( "(" )
			format_expr(expr.inner)
			t:append_next_token( ")" )

		elseif expr.ast_type == 'CastExpr' then
			format_expr(expr.expr)

		else
			printf_err("Unknown expr AST type: '%s'", expr.ast_type)
		end

		t:on_end()
		debug_printf("/format_expr")
	end


	local format_statement = function(stat) -> void
		local t = tokens(stat)

		--debug_printf("")
		--debug_printf(string.format("format_statement(%s) at line %i", stat.ast_type, stat.tokens and stat.tokens[1] and stat.tokens[1].line or -1))


		-- Ordered by popularity
		if stat.ast_type == 'IfStatement' then
			t:append_next_token( "if" )
			format_expr( stat.clauses[1].condition )
			t:append_next_token( "then" )
			format_statlist( stat.clauses[1].body )
			for i = 2, #stat.clauses do
				local st = stat.clauses[i]
				if st.condition then
					t:append_next_token( "elseif" )
					format_expr(st.condition)
					t:append_next_token( "then" )
				else
					t:append_next_token( "else" )
				end
				format_statlist(st.body)
			end
			t:append_next_token( "end" )

		elseif stat.ast_type == 'VarDeclareStatement' then
			if t:peek() == "local" then
				t:append_next_token( "local" )
			elseif t:peek() == "global" then
				t:skip_next_token()
			elseif t:peek() == "var" then
				--t:skip_next_token()
				t:append_str('local')
			end

			for i = 1, #stat.name_list do
				t:append_str( stat.name_list[i] )
				t:append_comma( i ~= #stat.name_list )
			end
			if #stat.init_list > 0 then
				t:append_next_token( "=" )
				for i = 1, #stat.init_list do
					format_expr(stat.init_list[i])
					t:append_comma( i ~= #stat.init_list )
				end
			end

		elseif stat.ast_type == 'CallStatement' then
			format_expr(stat.expression)

		elseif stat.ast_type == 'AssignmentStatement' then
			for i,v in ipairs(stat.lhs) do
				format_expr(v)
				t:append_comma( i ~= #stat.lhs )
			end
			if #stat.rhs > 0 then
				t:append_str( "=" )
				for i,v in ipairs(stat.rhs) do
					format_expr(v)
					t:append_comma( i ~= #stat.rhs )
				end
			end

		elseif stat.ast_type == 'ClassDeclStatement' then
			if stat.is_local then
				t:append_str( "local" ) -- replaces 'class'
			else
				t:skip_next_token() -- skip 'global'
				t:skip_next_token() -- skip 'class'
			end
			t:append_str( stat.name )
			t:append_next_token( "=" )
			format_expr(stat.rhs)

		elseif stat.ast_type == 'WhileStatement' then
			t:append_next_token( "while" )
			format_expr(stat.condition)
			t:append_next_token( "do" )
			format_statlist(stat.body)
			t:append_next_token( "end" )

		elseif stat.ast_type == 'DoStatement' then
			t:append_next_token( "do" )
			format_statlist(stat.body)
			t:append_next_token( "end" )

		elseif stat.ast_type == 'GenericForStatement' then
			t:append_next_token( "for" )
			for i,name in ipairs(stat.var_names) do
				t:append_str( name )
				t:append_comma( i ~= #stat.var_names )
			end
			t:append_next_token( "in" )
			for i = 1, #stat.generators do
				format_expr(stat.generators[i])
				t:append_comma( i ~= #stat.generators )
			end
			t:append_next_token( "do" )
			format_statlist(stat.body)
			t:append_next_token( "end" )

		elseif stat.ast_type == 'NumericForStatement' then
			t:append_next_token( "for" )
			t:append_str( stat.var_name )
			t:append_next_token( "=" )
			format_expr(stat.start)
			t:append_next_token( "," )
			format_expr(stat.end_)
			if stat.step then
				t:append_next_token( "," )
				format_expr(stat.step)
			end
			t:append_next_token( "do" )
			format_statlist(stat.body)
			t:append_next_token( "end" )

		elseif stat.ast_type == 'RepeatStatement' then
			t:append_next_token( "repeat" )
			format_statlist(stat.body)
			t:append_next_token( "until" )
			format_expr(stat.condition)

		elseif stat.ast_type == 'LabelStatement' then
			t:append_next_token( "::" )
			t:append_str( stat.label )
			t:append_next_token( "::" )

		elseif stat.ast_type == 'GotoStatement' then
			t:append_next_token( "goto" )
			t:append_str( stat.label )

		elseif stat.ast_type == 'ReturnStatement' then
			t:append_next_token( "return" )
			for i = 1, #stat.arguments do
				format_expr(stat.arguments[i])
				t:append_comma( i ~= #stat.arguments )
			end

		elseif stat.ast_type == 'BreakStatement' then
			t:append_next_token( "break" )

		elseif stat.ast_type == 'FunctionDeclStatement' then
			if stat.scoping == 'local' then
				t:append_next_token( "local" )
			elseif stat.scoping == 'global' then
				t:skip_next_token()
			elseif not stat.is_aggregate then
				-- Move forward before inserting local/global etc:
				t:append_white_for_next_token()
				t:inject_str('local') -- turn global function into local
			end
			t:append_next_token( "function" )
			format_expr( stat.name_expr )

			t:append_next_token( "(" )
			if #stat.arguments > 0 then
				for i = 1, #stat.arguments do
					t:append_str( stat.arguments[i].name )
					t:append_comma( i ~= #stat.arguments or stat.vararg )
					if i == #stat.arguments and stat.vararg then
						t:append_next_token( "..." )
					end
				end
			elseif stat.vararg then
				t:append_next_token( "..." )
			end
			t:append_next_token( ")" )

			format_statlist(stat.body)
			t:append_next_token( "end" )

		elseif stat.ast_type == 'Eof' then
			t:append_white()

		elseif stat.ast_type == 'Typedef' then

		else
			printf_err("Unknown stat AST type: '%s'", stat.ast_type)
		end

		if stat.semicolon then
			t:append_next_token(";")
		end

		t:on_end()

		if g_warn_output then
			-- Ensure the lua code is easily spotted as something you shouldn't modify:
			out:append_str(" --[[SOL OUTPUT--]] ")
		end

		debug_printf("/format_statment")
	end


	format_statlist = function(stat_list) -> void
		for _, stat in ipairs(stat_list.body) do
			format_statement(stat)
		end
	end


	if U.is_array(ast.body) then
		format_statlist(ast)
	else
		format_expr(ast)
	end


	return table.concat(out.rope)
end

return output
