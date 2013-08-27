--[[ DO NOT MODIFY - COMPILED FROM sol/format_identity.sol --]] require 'parser'
local D = require 'sol_debug'
local U = require 'util'
local printf_err = U.printf_err

local function debug_printf(...)
	--[[
	U.printf(...)
	--]]
end

--
-- FormatIdentity.lua
--
-- Returns the exact source code that was used to create an AST, preserving all
-- comments and whitespace.
-- This can be used to get back a Lua source after renaming some variables in
-- an AST.
--

-- Returns the number of lines, and the number of characters on the last line
local function count_line_breaks(str)
	D.assert(type(str) == 'string')
	local n = 0
	local c = 0
	for i = 1,#str do
		if str:sub(i,i) == '\n' then
			n = n + 1
			c = #str - i
		end
	end
	return n,c
end


local function FormatIdentity(ast, filename, insert_new_lines)
	if insert_new_lines == nil then
		insert_new_lines = true
	end

	local out = {
		rope = {},  -- List of strings
		line = 1,
		char = 1,

		append_str = function(self, str)
			local nl, c = count_line_breaks(str)

			if nl == 0 then
				self.char = self.char + #str
			else
				self.line = self.line + nl
				self.char = c
			end

			table.insert(self.rope, str)
		end,

		append_token = function(self, token)
			self:append_white(token)

			local str  = token.Data

			if insert_new_lines then
				local nl, c = count_line_breaks(str)

				while self.line + nl < token.Line do
					--print("Inserting extra line")
					table.insert(self.rope, '\n')
					self.line = self.line + 1
					self.char = 1
				end
			end

			self:append_str(str)
		end,

		append_tokens = function(self, tokens)
			for _,token in ipairs(tokens) do
				self:append_token( token )
			end
		end,

		append_white = function(self, token)
			if token.AllLeadingWhite then
				self:append_str( token.AllLeadingWhite )
			end
		end
	}

	local function report_error(fmt, ...)
		printf_err( "%s", table.concat(out.rope) )

		local msg = string.format(fmt, ...)
		local full = string.format('%s:%d: %s', filename, out.line, msg)
		D.error(full)
	end


	local format_statlist, format_expr

	-- returns a structure for iterating over tokens
	local function tokens(expr)
		local it = 1

		local t = {
		}

		function t:append_next_token(str)
			local tok = expr.Tokens[it];
			if str and tok.Data ~= str then
				report_error("Expected token '" .. str .. "'. Tokens: " .. U.Pretty(expr.Tokens))
			end
			out:append_token( tok )
			it = it + 1	
		end
		function t:append_token(token)
			out:append_token( token )
			it = it + 1
		end
		function t:append_white()
			local tok = expr.Tokens[it];
			--if not tok then report_error("Missing token: %s", U.Pretty(expr)) end
			if not tok then report_error("Missing token") end
			out:append_white( tok )
			it = it + 1
		end
		function t:skip_next_token()
			self:append_white()
		end
		function t:append_str(str)
			self:append_white()
			out:append_str(str)
		end
		function t:peek()
			if it <= #expr.Tokens then
				return expr.Tokens[it].Data
			end
		end
		function t:append_comma(mandatory, seperators)
			if true then
				seperators = seperators or { "," }
				seperators = U.bimap( seperators )
				if not mandatory and not seperators[self:peek()] then
					return
				end
				if not seperators[self:peek()] then
					report_error("Missing comma or semicolon; next token is: %s, token iterator: %i, tokens: %s",
						U.Pretty( self:peek() ), it, U.Pretty( expr.Tokens ))
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
			assert(it == #expr.Tokens + 1)
		end

		return t
	end


	format_expr = function(expr)
		D.assert(expr)
		D.assert(expr.AstType)

		local t = tokens(expr)
		--debug_printf("format_expr(%s) at line %i", expr.AstType, expr.Tokens[1] and expr.Tokens[1].Line or -1)

		if expr.AstType == 'VarExpr' then
			if expr.Variable then
				t:append_str( expr.Variable.name )
			else
				t:append_str( expr.name )
			end

		elseif expr.AstType == 'IdExpr' then
			t:append_str( expr.name )

		elseif expr.AstType == 'NumberExpr' then
			t:append_token( expr.Value )

		elseif expr.AstType == 'StringExpr' then
			t:append_token( expr.Value )

		elseif expr.AstType == 'BooleanExpr' then
			t:append_next_token( expr.Value and "true" or "false" )

		elseif expr.AstType == 'NilExpr' then
			t:append_next_token( "nil" )

		elseif expr.AstType == 'BinopExpr' then
			format_expr(expr.Lhs)
			t:append_str( expr.Op )
			format_expr(expr.Rhs)

		elseif expr.AstType == 'UnopExpr' then
			t:append_str( expr.Op )
			format_expr(expr.Rhs)

		elseif expr.AstType == 'DotsExpr' then
			t:append_next_token( "..." )

		elseif expr.AstType == 'CallExpr' then
			format_expr(expr.Base)
			t:append_next_token( "(" )
			for i,arg in ipairs( expr.Arguments ) do
				format_expr(arg)
				t:append_comma( i ~= #expr.Arguments )
			end
			t:append_next_token( ")" )

		elseif expr.AstType == 'TableCallExpr' then
			format_expr( expr.Base )
			format_expr( expr.Arguments[1] )

		elseif expr.AstType == 'StringCallExpr' then
			format_expr(expr.Base)
			--t:append_token( expr.Arguments[1] )
			format_expr( expr.Arguments[1] )

		elseif expr.AstType == 'IndexExpr' then
			format_expr(expr.Base)
			t:append_next_token( "[" )
			format_expr(expr.Index)
			t:append_next_token( "]" )

		elseif expr.AstType == 'MemberExpr' then
			format_expr(expr.Base)
			t:append_next_token()  -- . or :
			t:append_token(expr.Ident)

		elseif expr.AstType == 'LambdaFunction' then
			-- anonymous function
			t:append_next_token( "function" )
			t:append_next_token( "(" )
			if #expr.Arguments > 0 then
				for i = 1, #expr.Arguments do
					t:append_str( expr.Arguments[i].name )
					if i ~= #expr.Arguments then
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
			format_statlist(expr.Body)
			t:append_next_token("end")

		elseif expr.AstType == 'ConstructorExpr' then
			t:append_next_token( "{" )
			for i = 1, #expr.EntryList do
				local entry = expr.EntryList[i]
				if entry.type == 'Key' then
					t:append_next_token( "[" )
					format_expr(entry.Key)
					t:append_next_token( "]" )
					t:append_next_token( "=" )
					format_expr(entry.Value)
				elseif entry.type == 'Value' then
					format_expr(entry.Value)
				elseif entry.type == 'KeyString' then
					t:append_str(entry.Key)
					t:append_next_token( "=" )
					format_expr(entry.Value)
				end
				t:append_comma( i ~= #expr.EntryList, { ",", ";" } )
			end
			t:append_next_token( "}" )

		elseif expr.AstType == 'Parentheses' then
			t:append_next_token( "(" )
			format_expr(expr.Inner)
			t:append_next_token( ")" )

		else
			printf_err("Unknown expr AST type: '%s'", expr.AstType)
		end

		t:on_end()
		debug_printf("/format_expr")
	end


	local format_statement = function(stat)
		local t = tokens(stat)

		--debug_printf("")
		--debug_printf(string.format("format_statement(%s) at line %i", stat.AstType, stat.Tokens and stat.Tokens[1] and stat.Tokens[1].Line or -1))

		if stat.AstType == 'AssignmentStatement' then
			for i,v in ipairs(stat.Lhs) do
				format_expr(v)
				t:append_comma( i ~= #stat.Lhs )
			end
			if #stat.Rhs > 0 then
				t:append_next_token( "=" )
				for i,v in ipairs(stat.Rhs) do
					format_expr(v)
					t:append_comma( i ~= #stat.Rhs )
				end
			end

		elseif stat.AstType == 'CallStatement' then
			format_expr(stat.Expression)

		elseif stat.AstType == 'VarDeclareStatement' then
			if t:peek() == "local" then
				t:append_next_token( "local" )
			elseif t:peek() == "global" then
				t:skip_next_token()
			elseif t:peek() == "var" then
				--t:skip_next_token()
				t:append_str('local')
			end

			for i = 1, #stat.NameList do
				t:append_str( stat.NameList[i] )
				t:append_comma( i ~= #stat.NameList )
			end
			if #stat.InitList > 0 then
				t:append_next_token( "=" )
				for i = 1, #stat.InitList do
					format_expr(stat.InitList[i])
					t:append_comma( i ~= #stat.InitList )
				end
			end

		elseif stat.AstType == 'IfStatement' then
			t:append_next_token( "if" )
			format_expr( stat.Clauses[1].Condition )
			t:append_next_token( "then" )
			format_statlist( stat.Clauses[1].Body )
			for i = 2, #stat.Clauses do
				local st = stat.Clauses[i]
				if st.Condition then
					t:append_next_token( "elseif" )
					format_expr(st.Condition)
					t:append_next_token( "then" )
				else
					t:append_next_token( "else" )
				end
				format_statlist(st.Body)
			end
			t:append_next_token( "end" )

		elseif stat.AstType == 'WhileStatement' then
			t:append_next_token( "while" )
			format_expr(stat.Condition)
			t:append_next_token( "do" )
			format_statlist(stat.Body)
			t:append_next_token( "end" )

		elseif stat.AstType == 'DoStatement' then
			t:append_next_token( "do" )
			format_statlist(stat.Body)
			t:append_next_token( "end" )

		elseif stat.AstType == 'ReturnStatement' then
			t:append_next_token( "return" )
			for i = 1, #stat.Arguments do
				format_expr(stat.Arguments[i])
				t:append_comma( i ~= #stat.Arguments )
			end

		elseif stat.AstType == 'BreakStatement' then
			t:append_next_token( "break" )

		elseif stat.AstType == 'RepeatStatement' then
			t:append_next_token( "repeat" )
			format_statlist(stat.Body)
			t:append_next_token( "until" )
			format_expr(stat.Condition)

		elseif stat.AstType == 'FunctionDecl' then
			--print(U.Pretty(stat))

			if stat.IsLocal then
				t:append_next_token( "local" )
			elseif t:peek() == "global" then
				t:skip_next_token()
			end
			t:append_next_token( "function" )
			if stat.name then
				format_expr( stat.name )
			else
				t:append_str( stat.VarName )
			end

			t:append_next_token( "(" )
			if #stat.Arguments > 0 then
				for i = 1, #stat.Arguments do
					t:append_str( stat.Arguments[i].name )
					t:append_comma( i ~= #stat.Arguments or stat.vararg )
					if i == #stat.Arguments and stat.vararg then
						t:append_next_token( "..." )
					end
				end
			elseif stat.vararg then
				t:append_next_token( "..." )
			end
			t:append_next_token( ")" )

			format_statlist(stat.Body)
			t:append_next_token( "end" )

		elseif stat.AstType == 'GenericForStatement' then
			t:append_next_token( "for" )
			for i,name in ipairs(stat.VarNames) do
				t:append_str( name )
				t:append_comma( i ~= #stat.VarNames )
			end
			t:append_next_token( "in" )
			for i = 1, #stat.Generators do
				format_expr(stat.Generators[i])
				t:append_comma( i ~= #stat.Generators )
			end
			t:append_next_token( "do" )
			format_statlist(stat.Body)
			t:append_next_token( "end" )

		elseif stat.AstType == 'NumericForStatement' then
			t:append_next_token( "for" )
			t:append_str( stat.VarName )
			t:append_next_token( "=" )
			format_expr(stat.Start)
			t:append_next_token( "," )
			format_expr(stat.End)
			if stat.Step then
				t:append_next_token( "," )
				format_expr(stat.Step)
			end
			t:append_next_token( "do" )
			format_statlist(stat.Body)
			t:append_next_token( "end" )

		elseif stat.AstType == 'LabelStatement' then
			t:append_next_token( "::" )
			t:append_str( stat.Label )
			t:append_next_token( "::" )

		elseif stat.AstType == 'GotoStatement' then
			t:append_next_token( "goto" )
			t:append_str( stat.Label )

		elseif stat.AstType == 'Eof' then
			t:append_white()

		elseif stat.AstType == 'Typedef' then

		else
			printf_err("Unknown stat AST type: '%s'", stat.AstType)
		end

		if stat.Semicolon then
			t:append_next_token(";")
		end

		t:on_end()
		debug_printf("/format_statment")
	end


	format_statlist = function(stat_list)
		for _, stat in ipairs(stat_list.Body) do
			format_statement(stat)
		end
	end


	if U.is_array(ast.Body) then
		format_statlist(ast)
	else
		format_expr(ast)
	end


	return table.concat(out.rope)
end

return FormatIdentity
