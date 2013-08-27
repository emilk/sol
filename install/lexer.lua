--[[ DO NOT MODIFY - COMPILED FROM sol/lexer.sol --]] local U = require 'util'
local D = require 'sol_debug'
local bimap = U.bimap

local WhiteChars = bimap{' ', '\n', '\t', '\r'}
local EscapeLookup = {['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'"}
local LowerChars = bimap{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
							 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
							 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
local UpperChars = bimap{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
							 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
							 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
local Digits = bimap{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
local HexDigits = bimap{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
							'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'}


local L = {}


-- The settings are found in Parser.sol











function L.LexSol(src, filename, settings)
	assert(type(src) == 'string')

	local Symbols  = settings.Symbols
	local Keywords = settings.Keywords

	--token dump
	local tokens = {}

	local function local_lexer()
		--line / char / pointer tracking
		local line, char, p = 1,1,1

		--get / peek functions
		local function get()
			local c = src:sub(p,p)
			if c == '\n' then
				char = 1
				line = line + 1
			else
				char = char + 1
			end
			p = p + 1
			return c
		end

		local function peek(n)
			n = n or 0
			return src:sub(p+n,p+n)
		end

		local function consume(chars)
			local c = peek()
			for i = 1, #chars do
				if c == chars:sub(i,i) then
					return get()
				end
			end
		end

		--shared stuff
		local function report_lexer_error(err, level)
			D.break_()
			level = level or 0
			--return error(">> :"..line..":"..char..": "..err, level)
			return error(filename..':'..line..': '..err, level)
		end

		-- returns content, long
		local function try_get_long_string()
			local start = p
			if peek() == '[' then
				local equals_count = 0
				local depth = 1
				while peek(equals_count+1) == '=' do
					equals_count = equals_count + 1
				end
				if peek(equals_count+1) == '[' then
					--start parsing the string. Strip the starting bit
					for _ = 0, equals_count+1 do get() end

					--get the contents
					local content_start = p
					while true do
						--check for eof
						if peek() == '' then
							return report_lexer_error("Expected `]"..string.rep('=', equals_count).."]` near <eof>.", 3)
						end

						--check for the end
						local found_end = true
						if peek() == ']' then
							for i = 1, equals_count do
								if peek(i) ~= '=' then found_end = false end
							end
							if peek(equals_count+1) ~= ']' then
								found_end = false
							end
						else
							if peek() == '[' then
								-- is there an embedded long string?
								local embedded = true
								for i = 1, equals_count do
									if peek(i) ~= '=' then
										embedded = false
										break
									end
								end
								if peek(equals_count + 1) == '[' and embedded then
									-- oh look, there was
									depth = depth + 1
									for i = 1, (equals_count + 2) do
										get()
									end
								end
							end
							found_end = false
						end
						--
						if found_end then
							depth = depth - 1
							if depth == 0 then
								break
							else
								for i = 1, equals_count + 2 do
									get()
								end
							end
						else
							get()
						end
					end

					--get the interior string
					local content_string = src:sub(content_start, p-1)

					--found the end. Get rid of the trailing bit
					for i = 0, equals_count+1 do get() end

					--get the exterior string
					local long_string = src:sub(start, p-1)

					--return the stuff
					return content_string, long_string
				else
					return nil, nil
				end
			else
				return nil, nil
			end
		end


		-- Will collect tokens for whites
		local function get_leading_white_old()
			--local leading_tokens = { }  -- Collect things in special white-tokens
			local leading_tokens = nil    -- Don't bother
			local start = p

			while true do
				local c = peek()

				if line == 1 and c == '#' and peek(1) == '!' then
					-- #! shebang for linux scripts
					get()
					get()
					local shebang = "#!"
					while peek() ~= '\n' and peek() ~= '' do
						shebang = shebang .. get()
					end
					if leading_tokens then
						local token = {
							type = 'Comment',
							CommentType = 'Shebang',
							Data = shebang,
							Line = line,
							Char = char
						}
						token.Print = function()
							return "<"..(token.type .. string.rep(' ', 7-#token.type)).."  ".. token.Data .." >"
						end
						table.insert(leading_tokens, token)
					end

				elseif c == ' ' or c == '\t' or c == '\n' or c == '\r' then
					local white = get()
					if leading_tokens then
						table.insert(leading_tokens, { type = 'Whitespace', Line = line, Char = char, Data = white })
					end

				elseif c == '-' and peek(1) == '-' then
					--comment
					get()
					get()
					local comment = '--'
					local _, whole_text = try_get_long_string()
					local long_str = false

					if whole_text then
						-- Multiline comment
						comment = comment .. whole_text
						long_str = true
					else
						-- One-line comment
						while peek() ~= '\n' and peek() ~= '' do
							--comment = comment .. get()
							get()	
						end
					end

					if leading_tokens then
						local token = {
							type = 'Comment',
							CommentType = long_str and 'LongComment' or 'Comment',
							Data = comment,
							Line = line,
							Char = char,
						}
						token.Print = function()
							return "<"..(token.type .. string.rep(' ', 7-#token.type)).."  ".. token.Data .." >"
						end
						table.insert(leading_tokens, token)
					end

				else
					break
				end
			end

			local white_str = src:sub(start, p-1)

			return white_str, leading_tokens
		end


		local function get_leading_white()
			local start = p

			while true do
				local c = peek()

				if c == ' ' or c == '\t' or c == '\n' or c == '\r' then
					get()

				elseif c == '-' and peek(1) == '-' then
					--comment
					get()
					get()
					local comment = '--'
					local _, whole_text = try_get_long_string()

					if not whole_text then
						repeat
							local n = get()
						until n == '\n' or n == ''
					end

				elseif line == 1 and c == '#' and peek(1) == '!' then
					-- #! shebang for linux scripts
					get()
					get()
					repeat
						local n = get()
					until n == '\n' or n == ''

				else
					break
				end
			end

			return src:sub(start, p-1)
		end


		--main token emitting loop
		while true do
			--get leading whitespace. The leading whitespace will include any comments
			--preceding the token. This prevents the parser needing to deal with comments
			--separately.
			--local all_leading_white, leading_tokens = get_leading_white_old()
			local all_leading_white = get_leading_white()
			local leading_tokens = nil

			--get the initial char
			local this_line = line
			local this_char = char
			local error_at = ":"..line..":"..char..":> "
			local c = peek()

			--symbol to emit
			local to_emit = nil

			--branch on type
			if c == '' then
				--eof
				to_emit = { type = 'Eof' }

			elseif UpperChars[c] or LowerChars[c] or c == '_' then
				--ident or keyword
				local start = p
				repeat
					get()
					c = peek()
				until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_')
				local dat = src:sub(start, p-1)
				if Keywords[dat] then
					to_emit = {type = 'Keyword', Data = dat}
				else
					to_emit = {type = 'Ident', Data = dat}
				end

			elseif Digits[c] or (peek() == '.' and Digits[peek(1)]) then
				--number const
				local start = p
				if c == '0' and peek(1) == 'x' then
					get();get()
					while HexDigits[peek()] do get() end
					if consume('Pp') then
						consume('+-')
						while Digits[peek()] do get() end
					end
				else
					while Digits[peek()] do get() end
					if consume('.') then
						while Digits[peek()] do get() end
					end
					if consume('Ee') then
						consume('+-')
						while Digits[peek()] do get() end
					end
				end
				to_emit = {type = 'Number', Data = src:sub(start, p-1)}

			elseif c == '\'' or c == '\"' then
				local start = p
				--string const
				local delim = get()
				local content_start = p
				while true do
					local c = get()
					if c == '\\' then
						get() --get the escape char
					elseif c == delim then
						break
					elseif c == '' then
						return report_lexer_error("Unfinished string near <eof>")
					end
				end
				local content = src:sub(content_start, p-2)
				local constant = src:sub(start, p-1)
				to_emit = {type = 'String', Data = constant, Constant = content}

			elseif c == '[' then
				local content, wholetext = try_get_long_string()
				if wholetext then
					to_emit = {type = 'String', Data = wholetext, Constant = content}
				else
					get()
					to_emit = {type = 'Symbol', Data = '['}
				end

			elseif consume('=') then
				if consume('=') then
					to_emit = {type = 'Symbol', Data = '=='}
				elseif settings.Sol and consume('>') then
					to_emit = {type = 'Symbol', Data = '=>'}
				else
					to_emit = {type = 'Symbol', Data = '='}
				end

			elseif consume('><') then
				if consume('=') then
					to_emit = {type = 'Symbol', Data = c..'='}  -- '>=' or '<='
				else
					to_emit = {type = 'Symbol', Data = c}       -- '>' or '<'
				end

			elseif consume('~') then
				if consume('=') then
					to_emit = {type = 'Symbol', Data = '~='}
				else
					return report_lexer_error("Unexpected symbol `~` in source.", 2)
				end

			elseif consume('.') then
				if consume('.') then
					if consume('.') then
						to_emit = {type = 'Symbol', Data = '...'}
					else
						to_emit = {type = 'Symbol', Data = '..'}
					end
				else
					to_emit = {type = 'Symbol', Data = '.'}
				end

			elseif consume(':') then
				if consume(':') then
					to_emit = {type = 'Symbol', Data = '::'}
				elseif consume(':<') then
					to_emit = {type = 'Symbol', Data = ':<'}  -- Start of template function call, i.e. type_name:<int>()
				else
					to_emit = {type = 'Symbol', Data = ':'}
				end

			elseif settings.FunctionTypes and consume('-') then
				if consume('>') then
					to_emit = {type = 'Symbol', Data = '->'}
				else
					to_emit = {type = 'Symbol', Data = '-'}
				end

			elseif Symbols[c] then
				get()
				to_emit = {type = 'Symbol', Data = c}

			else
				local contents, all = try_get_long_string()
				if contents then
					to_emit = {type = 'String', Data = all, Constant = contents}
				else
					return report_lexer_error("Unexpected Symbol `"..c.."` when paring in source.", 2)
				end
			end

			--add the emitted symbol, after adding some common data
			to_emit.LeadingWhite = leading_tokens -- table of leading whitespace/comments
			to_emit.AllLeadingWhite = all_leading_white
			--for k, tok in pairs(leading_tokens) do
			--  tokens[#tokens + 1] = tok
			--end

			to_emit.Line = this_line
			to_emit.Char = this_char
			to_emit.Print = function()
				return "<" .. to_emit.type .. string.rep(' ', 7-#to_emit.type) .. "  " .. (to_emit.Data or '') .. " >"
			end
			tokens[#tokens+1] = to_emit

			--halt after eof has been emitted
			if to_emit.type == 'Eof' then break end
		end
	end

	local st, err = pcall( local_lexer )

	if not st then
		U.printf_err( "%s", err )
		return false, err
	end

	--public interface:
	local tok = {}
	local p = 1
	
	function tok:getp()
		return p
	end
	
	function tok:setp(n)
		p = n
	end
	
	function tok:get_token_list()
		return tokens
	end
	
	--getters
	function tok:Peek(n)
		n = n or 0
		local ix = math.max(1, math.min(#tokens, p+n))
		return tokens[ix]
	end

	function tok:Get(token_list)
		local t = tokens[p]
		p = math.min(p + 1, #tokens)
		if token_list then
			table.insert(token_list, t)
		end
		return t
	end

	function tok:GetIdent(token_list)
		if tok:Is('Ident') then
			return tok:Get(token_list).Data
		else
			return nil
		end
	end

	function tok:Is(t)
		return tok:Peek().type == t
	end

	-- either cosumes and returns the given symbil if there is one, or nil
	function tok:ConsumeSymbol(symb, token_list)
		local t = self:Peek()
		if t.type == 'Symbol' then
			if t.Data == symb then
				return self:Get(token_list)
			else
				return nil
			end
		else
			return nil
		end
	end

	function tok:ConsumeKeyword(kw, token_list)
		local t = self:Peek()
		if t.type == 'Keyword' and t.Data == kw then
			return self:Get(token_list)
		else
			return nil
		end
	end

	function tok:ConsumeIdent(ident, token_list)
		local t = self:Peek()
		if t.type == 'Ident' and t.Data == ident then
			return self:Get(token_list)
		else
			return nil
		end
	end

	function tok:IsKeyword(kw)
		local t = tok:Peek()
		return t.type == 'Keyword' and t.Data == kw
	end

	function tok:IsSymbol(s)
		local t = tok:Peek()
		return t.type == 'Symbol' and t.Data == s
	end

	function tok:IsEof()
		return tok:Peek().type == 'Eof'
	end

	return true, tok
end

return L
