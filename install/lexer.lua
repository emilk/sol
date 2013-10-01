--[[ DO NOT MODIFY - COMPILED FROM sol/lexer.sol on 2013 Oct 01  21:32:06 --]] local U = require 'util' --[[SOL OUTPUT--]] 
local D = require 'sol_debug' --[[SOL OUTPUT--]] 
local set = U.set --[[SOL OUTPUT--]] 

local WhiteChars   = set{' ', '\n', '\t', '\r'} --[[SOL OUTPUT--]] 
local EscapeLookup = {['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'"} --[[SOL OUTPUT--]] 
local LowerChars   = set{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
                       'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                       's', 't', 'u', 'v', 'w', 'x', 'y', 'z'} --[[SOL OUTPUT--]] 
local UpperChars   = set{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
                       'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
                       'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'} --[[SOL OUTPUT--]] 
local Digits       = set{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'} --[[SOL OUTPUT--]] 
local HexDigits    = set{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                       'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'} --[[SOL OUTPUT--]] 

local L = {} --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]]  --[[SOL OUTPUT--]] 














local function extract_chars(str)
	local chars = {} --[[SOL OUTPUT--]] 
	if true then
		-- Fastest
		for i = 1, #str do
			chars[#chars + 1] = str:sub(i,i) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	elseif true then
		str:gsub(".", function(c)
			chars[#chars + 1] = c --[[SOL OUTPUT--]] 
		end) --[[SOL OUTPUT--]] 
	else
		for chr in str:gmatch(".") do
			chars[#chars + 1] = chr --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	assert(#chars == #str) --[[SOL OUTPUT--]] 

	-- Signal eof:
	chars[#chars + 1] = '' --[[SOL OUTPUT--]] 
	chars[#chars + 1] = '' --[[SOL OUTPUT--]] 
	chars[#chars + 1] = '' --[[SOL OUTPUT--]] 

	return chars --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]]  


-- The settings are found in Parser.sol
function L.lex_sol(src, filename, settings)
	assert(type(src) == 'string') --[[SOL OUTPUT--]] 

	local chars = extract_chars(src) --[[SOL OUTPUT--]] 

	local symbols  = settings.symbols --[[SOL OUTPUT--]] 
	local keywords = settings.keywords --[[SOL OUTPUT--]] 

	--token dump
	local tokens = {} --[[SOL OUTPUT--]] 

	local function local_lexer()
		--line / char / pointer tracking
		local line, char, p = 1,1,1 --[[SOL OUTPUT--]] 

		--get / peek functions
		local function get()
			--local c = src:sub(p,p)
			local c = chars[p] --[[SOL OUTPUT--]] 
			if c == '\n' then
				char = 1 --[[SOL OUTPUT--]] 
				line = line + 1 --[[SOL OUTPUT--]] 
			else
				char = char + 1 --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			p = p + 1 --[[SOL OUTPUT--]] 
			return c --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local function peek(n)
			return chars[p+n] --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local function consume(any_of_these)
			local c = chars[p] --[[SOL OUTPUT--]] 
			for i = 1, #any_of_these do
				if c == any_of_these:sub(i,i) then
					return get() --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		--shared stuff
		local function report_lexer_error(err, level)
			D.break_() --[[SOL OUTPUT--]] 
			level = level or 0 --[[SOL OUTPUT--]] 
			--return error(">> :"..line..":"..char..": "..err, level)
			return error(filename..':'..line..': '..err, level) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		-- returns content, long
		local function try_get_long_string()
			local start = p --[[SOL OUTPUT--]] 
			if chars[p] == '[' then
				local equals_count = 0 --[[SOL OUTPUT--]] 
				local depth = 1 --[[SOL OUTPUT--]] 
				while peek(equals_count+1) == '=' do
					equals_count = equals_count + 1 --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				if peek(equals_count+1) == '[' then
					--start parsing the string. Strip the starting bit
					for _ = 0, equals_count+1 do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

					--get the contents
					local content_start = p --[[SOL OUTPUT--]] 
					while true do
						--check for eof
						if chars[p] == '' then
							return report_lexer_error("Expected `]"..string.rep('=', equals_count).."]` near <eof>.", 3) --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 

						--check for the end
						local found_end = true --[[SOL OUTPUT--]] 
						if chars[p] == ']' then
							for i = 1, equals_count do
								if peek(i) ~= '=' then found_end = false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
							if peek(equals_count+1) ~= ']' then
								found_end = false --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						else
							if chars[p] == '[' then
								-- is there an embedded long string?
								local embedded = true --[[SOL OUTPUT--]] 
								for i = 1, equals_count do
									if peek(i) ~= '=' then
										embedded = false --[[SOL OUTPUT--]] 
										break --[[SOL OUTPUT--]] 
									end --[[SOL OUTPUT--]] 
								end --[[SOL OUTPUT--]] 
								if peek(equals_count + 1) == '[' and embedded then
									-- oh look, there was
									depth = depth + 1 --[[SOL OUTPUT--]] 
									for i = 1, (equals_count + 2) do
										get() --[[SOL OUTPUT--]] 
									end --[[SOL OUTPUT--]] 
								end --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
							found_end = false --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
						--
						if found_end then
							depth = depth - 1 --[[SOL OUTPUT--]] 
							if depth == 0 then
								break --[[SOL OUTPUT--]] 
							else
								for i = 1, equals_count + 2 do
									get() --[[SOL OUTPUT--]] 
								end --[[SOL OUTPUT--]] 
							end --[[SOL OUTPUT--]] 
						else
							get() --[[SOL OUTPUT--]] 
						end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					--get the interior string
					local content_string = src:sub(content_start, p-1) --[[SOL OUTPUT--]] 

					--found the end. get rid of the trailing bit
					for i = 0, equals_count+1 do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 

					--get the exterior string
					local long_string = src:sub(start, p-1) --[[SOL OUTPUT--]] 

					--return the stuff
					return content_string, long_string --[[SOL OUTPUT--]] 
				else
					return nil, nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				return nil, nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 


		local function get_leading_white()
			local start = p --[[SOL OUTPUT--]] 

			while true do
				local c = chars[p] --[[SOL OUTPUT--]] 

				if c == ' ' or c == '\t' or c == '\n' or c == '\r' then
					get() --[[SOL OUTPUT--]] 

				elseif c == '-' and peek(1) == '-' then
					--comment
					get() --[[SOL OUTPUT--]] 
					get() --[[SOL OUTPUT--]] 
					local comment = '--' --[[SOL OUTPUT--]] 
					local _, whole_text = try_get_long_string() --[[SOL OUTPUT--]] 

					if not whole_text then
						repeat
							local n = get() --[[SOL OUTPUT--]] 
						until n == '\n' or n == '' --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

				elseif line == 1 and c == '#' and peek(1) == '!' then
					-- #! shebang
					get() --[[SOL OUTPUT--]] 
					get() --[[SOL OUTPUT--]] 
					repeat
						local n = get() --[[SOL OUTPUT--]] 
					until n == '\n' or n == '' --[[SOL OUTPUT--]] 

				else
					break --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			return src:sub(start, p-1) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 


		--main token emitting loop
		while true do
			--get leading whitespace. The leading whitespace will include any comments
			--preceding the token. This prevents the parser needing to deal with comments
			--separately.
			--local all_leading_white, leading_tokens = get_leading_white_old()
			local all_leading_white = get_leading_white() --[[SOL OUTPUT--]] 
			local leading_tokens = nil --[[SOL OUTPUT--]] 

			--get the initial char
			local this_line = line --[[SOL OUTPUT--]] 
			local this_char = char --[[SOL OUTPUT--]] 
			local error_at = ":"..line..":"..char..":> " --[[SOL OUTPUT--]] 
			local c = chars[p] --[[SOL OUTPUT--]] 

			--symbol to emit
			local to_emit = nil --[[SOL OUTPUT--]] 

			--branch on type
			if c == '' then
				--eof
				to_emit = { type = 'Eof' } --[[SOL OUTPUT--]] 

			elseif UpperChars[c] or LowerChars[c] or c == '_' then
				--ident or keyword
				local start = p --[[SOL OUTPUT--]] 
				repeat
					get() --[[SOL OUTPUT--]] 
					c = chars[p] --[[SOL OUTPUT--]] 
				until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_') --[[SOL OUTPUT--]] 
				local dat = src:sub(start, p-1) --[[SOL OUTPUT--]] 
				if keywords[dat] then
					to_emit = {type = 'Keyword', data = dat} --[[SOL OUTPUT--]] 
				else
					to_emit = {type = 'ident', data = dat} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif Digits[c] or (chars[p] == '.' and Digits[peek(1)]) then
				--number const
				local start = p --[[SOL OUTPUT--]] 
				if c == '0' and peek(1) == 'x' then
					get() --[[SOL OUTPUT--]]   -- 0
					get() --[[SOL OUTPUT--]]   -- x
					while HexDigits[chars[p]] do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					if consume('Pp') then
						consume('+-') --[[SOL OUTPUT--]] 
						while Digits[chars[p]] do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					while Digits[chars[p]] do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					if consume('.') then
						while Digits[chars[p]] do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
					if consume('Ee') then
						consume('+-') --[[SOL OUTPUT--]] 
						while Digits[chars[p]] do get() --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				to_emit = {type = 'Number', data = src:sub(start, p-1)} --[[SOL OUTPUT--]] 

			elseif c == '\'' or c == '\"' then
				local start = p --[[SOL OUTPUT--]] 
				--string const
				local delim = get() --[[SOL OUTPUT--]] 
				local content_start = p --[[SOL OUTPUT--]] 
				while true do
					local c = get() --[[SOL OUTPUT--]] 
					if c == '\\' then
						get() --[[SOL OUTPUT--]]  --get the escape char
					elseif c == delim then
						break --[[SOL OUTPUT--]] 
					elseif c == '' then
						return report_lexer_error("Unfinished string near <eof>") --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
				local content = src:sub(content_start, p-2) --[[SOL OUTPUT--]] 
				local constant = src:sub(start, p-1) --[[SOL OUTPUT--]] 
				to_emit = {type = 'String', data = constant, Constant = content} --[[SOL OUTPUT--]] 

			elseif c == '[' then
				local content, wholetext = try_get_long_string() --[[SOL OUTPUT--]] 
				if wholetext then
					to_emit = {type = 'String', data = wholetext, Constant = content} --[[SOL OUTPUT--]] 
				else
					get() --[[SOL OUTPUT--]] 
					to_emit = {type = 'Symbol', data = '['} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif consume('=') then
				if consume('=') then
					to_emit = {type = 'Symbol', data = '=='} --[[SOL OUTPUT--]] 
				elseif settings.is_sol and consume('>') then
					to_emit = {type = 'Symbol', data = '=>'} --[[SOL OUTPUT--]] 
				else
					to_emit = {type = 'Symbol', data = '='} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif consume('><') then
				if consume('=') then
					to_emit = {type = 'Symbol', data = c..'='} --[[SOL OUTPUT--]]   -- '>=' or '<='
				else
					to_emit = {type = 'Symbol', data = c} --[[SOL OUTPUT--]]        -- '>' or '<'
				end --[[SOL OUTPUT--]] 

			elseif consume('~') then
				if consume('=') then
					to_emit = {type = 'Symbol', data = '~='} --[[SOL OUTPUT--]] 
				else
					return report_lexer_error("Unexpected symbol `~` in source.", 2) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif consume('.') then
				if consume('.') then
					if consume('.') then
						to_emit = {type = 'Symbol', data = '...'} --[[SOL OUTPUT--]] 
					else
						to_emit = {type = 'Symbol', data = '..'} --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 
				else
					to_emit = {type = 'Symbol', data = '.'} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif consume(':') then
				if consume(':') then
					to_emit = {type = 'Symbol', data = '::'} --[[SOL OUTPUT--]] 
				elseif consume(':<') then
					to_emit = {type = 'Symbol', data = ':<'} --[[SOL OUTPUT--]]  -- start of template function call, i.e. max:<int>()
				else
					to_emit = {type = 'Symbol', data = ':'} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif settings.function_types and consume('-') then
				if consume('>') then
					to_emit = {type = 'Symbol', data = '->'} --[[SOL OUTPUT--]] 
				else
					to_emit = {type = 'Symbol', data = '-'} --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 

			elseif symbols[c] then
				get() --[[SOL OUTPUT--]] 
				to_emit = {type = 'Symbol', data = c} --[[SOL OUTPUT--]] 

			else
				local contents, all = try_get_long_string() --[[SOL OUTPUT--]] 
				if contents then
					to_emit = {type = 'String', data = all, Constant = contents} --[[SOL OUTPUT--]] 
				else
					return report_lexer_error("Unexpected Symbol `"..c.."` when paring in source.", 2) --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			--add the emitted symbol, after adding some common data
			to_emit.leading_white     = leading_tokens --[[SOL OUTPUT--]]  -- table of leading whitespace/comments
			to_emit.all_leading_white = all_leading_white --[[SOL OUTPUT--]] 
			--for k, tok in pairs(leading_tokens) do
			--  tokens[#tokens + 1] = tok
			--end

			to_emit.line = this_line --[[SOL OUTPUT--]] 
			to_emit.char = this_char --[[SOL OUTPUT--]] 
			tokens[#tokens+1] = to_emit --[[SOL OUTPUT--]] 

			--halt after eof has been emitted
			if to_emit.type == 'Eof' then break --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local st, err = pcall( local_lexer ) --[[SOL OUTPUT--]] 

	if not st then
		U.printf_err( "%s", err ) --[[SOL OUTPUT--]] 
		return false, err --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	--public interface:
	local tok = {} --[[SOL OUTPUT--]] 
	local p = 1 --[[SOL OUTPUT--]] 
	
	function tok:getp()
		return p --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	
	function tok:setp(n)
		p = n --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	
	function tok:get_token_list()
		return tokens --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	
	--getters
	function tok:peek(n)
		if n then
			local ix = math.min(#tokens, p+n) --[[SOL OUTPUT--]] 
			return tokens[ix] --[[SOL OUTPUT--]] 
		else
			--return tokens[math.min(#tokens, p)]
			return tokens[p] --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:get(token_list)
		local t = tokens[p] --[[SOL OUTPUT--]] 
		p = math.min(p + 1, #tokens) --[[SOL OUTPUT--]] 
		if token_list then
			table.insert(token_list, t) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		return t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:get_ident(token_list)
		if tok:is('ident') then
			return tok:get(token_list).data --[[SOL OUTPUT--]] 
		else
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:is(t)
		return tokens[p].type == t --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	-- either cosumes and returns the given symbil if there is one, or nil
	function tok:consume_symbol(symb, token_list)
		local t = self:peek() --[[SOL OUTPUT--]] 
		if t.type == 'Symbol' then
			if t.data == symb then
				return self:get(token_list) --[[SOL OUTPUT--]] 
			else
				return nil --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:consume_keyword(kw, token_list)
		local t = self:peek() --[[SOL OUTPUT--]] 
		if t.type == 'Keyword' and t.data == kw then
			return self:get(token_list) --[[SOL OUTPUT--]] 
		else
			return nil --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:is_keyword(kw)
		local t = tok:peek() --[[SOL OUTPUT--]] 
		return t.type == 'Keyword' and t.data == kw --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:is_symbol(s)
		local t = tok:peek() --[[SOL OUTPUT--]] 
		return t.type == 'Symbol' and t.data == s --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	function tok:is_eof()
		return tok:peek().type == 'Eof' --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return true, tok --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return L --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 