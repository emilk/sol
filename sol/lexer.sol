local U = require 'util'
local D = require 'sol_debug'
local set = U.set

var WhiteChars   = set{' ', '\n', '\t', '\r'}
var EscapeLookup = {['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'"}
var LowerChars   = set{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
                       'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                       's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
var UpperChars   = set{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
                       'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
                       'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
var Digits       = set{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
var HexDigits    = set{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                       'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'}

local L = {}

typedef TokID = 'Keyword' or 'ident' or 'Number' or 'String' or 'Symbol' or 'Eof'

typedef Token = {
	type : TokID,
	data : string?,
	line : int?,
	char : int?,
}

typedef L.Token = Token
typedef L.TokenList = [L.Token]


local function extract_chars(str: string) -> [string]
	var chars = {}
	if true then
		-- Fastest
		for i = 1, #str do
			chars[#chars + 1] = str:sub(i,i)
		end
	elseif true then
		str:gsub(".", function(c)
			chars[#chars + 1] = c
		end)
	else
		for chr in str:gmatch(".") do
			chars[#chars + 1] = chr
		end
	end
	assert(#chars == #str)

	-- Signal eof:
	chars[#chars + 1] = ''
	chars[#chars + 1] = ''
	chars[#chars + 1] = ''

	return chars
end 


-- The settings are found in Parser.sol
function L.lex_sol(src: string, filename: string, settings) -> bool, any
	assert(type(src) == 'string')

	local chars = extract_chars(src)

	local symbols  = settings.symbols
	local keywords = settings.keywords

	--token dump
	var<[L.Token]> tokens = {}

	local function local_lexer()
		--line / char / pointer tracking
		local line, char, p = 1,1,1

		--get / peek functions
		local function get() -> string
			--local c = src:sub(p,p)
			local c = chars[p]
			if c == '\n' then
				char = 1
				line = line + 1
			else
				char = char + 1
			end
			p = p + 1
			return c
		end

		local function peek(n: int) -> string
			return chars[p+n]
		end

		local function consume(any_of_these: string) -> string?
			local c = chars[p]
			for i = 1, #any_of_these do
				if c == any_of_these:sub(i,i) then
					return get()
				end
			end
		end

		--shared stuff
		local function report_lexer_error(err: string, level: int?)
			D.break_()
			level = level or 0
			--return error(">> :"..line..":"..char..": "..err, level)
			return error(filename..':'..line..': '..err, level)
		end

		-- returns content, long
		local function try_get_long_string() -> string?, string?
			local start = p
			if chars[p] == '[' then
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
						if chars[p] == '' then
							return report_lexer_error("Expected `]"..string.rep('=', equals_count).."]` near <eof>.", 3)
						end

						--check for the end
						local found_end = true
						if chars[p] == ']' then
							for i = 1, equals_count do
								if peek(i) ~= '=' then found_end = false end
							end
							if peek(equals_count+1) ~= ']' then
								found_end = false
							end
						else
							if chars[p] == '[' then
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

					--found the end. get rid of the trailing bit
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


		local function get_leading_white() -> string
			local start = p

			while true do
				local c = chars[p]

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
					-- #! shebang
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
			local c = chars[p]

			--symbol to emit
			var<Token?> to_emit = nil

			--branch on type
			if c == '' then
				--eof
				to_emit = { type = 'Eof' }

			elseif UpperChars[c] or LowerChars[c] or c == '_' then
				--ident or keyword
				local start = p
				repeat
					get()
					c = chars[p]
				until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_')
				local dat = src:sub(start, p-1)
				if keywords[dat] then
					to_emit = {type = 'Keyword', data = dat}
				else
					to_emit = {type = 'ident', data = dat}
				end

			elseif Digits[c] or (chars[p] == '.' and Digits[peek(1)]) then
				--number const
				local start = p
				if c == '0' and peek(1) == 'x' then
					get()  -- 0
					get()  -- x
					while HexDigits[chars[p]] do get() end
					if consume('Pp') then
						consume('+-')
						while Digits[chars[p]] do get() end
					end
				else
					while Digits[chars[p]] do get() end
					if consume('.') then
						while Digits[chars[p]] do get() end
					end
					if consume('Ee') then
						consume('+-')
						while Digits[chars[p]] do get() end
					end
				end
				to_emit = {type = 'Number', data = src:sub(start, p-1)}

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
				to_emit = {type = 'String', data = constant, Constant = content}

			elseif c == '[' then
				local content, wholetext = try_get_long_string()
				if wholetext then
					to_emit = {type = 'String', data = wholetext, Constant = content}
				else
					get()
					to_emit = {type = 'Symbol', data = '['}
				end

			elseif consume('=') then
				if consume('=') then
					to_emit = {type = 'Symbol', data = '=='}
				elseif settings.is_sol and consume('>') then
					to_emit = {type = 'Symbol', data = '=>'}
				else
					to_emit = {type = 'Symbol', data = '='}
				end

			elseif consume('><') then
				if consume('=') then
					to_emit = {type = 'Symbol', data = c..'='}  -- '>=' or '<='
				else
					to_emit = {type = 'Symbol', data = c}       -- '>' or '<'
				end

			elseif consume('~') then
				if consume('=') then
					to_emit = {type = 'Symbol', data = '~='}
				else
					return report_lexer_error("Unexpected symbol `~` in source.", 2)
				end

			elseif consume('.') then
				if consume('.') then
					if consume('.') then
						to_emit = {type = 'Symbol', data = '...'}
					else
						to_emit = {type = 'Symbol', data = '..'}
					end
				else
					to_emit = {type = 'Symbol', data = '.'}
				end

			elseif consume(':') then
				if consume(':') then
					to_emit = {type = 'Symbol', data = '::'}
				elseif consume(':<') then
					to_emit = {type = 'Symbol', data = ':<'} -- start of template function call, i.e. max:<int>()
				else
					to_emit = {type = 'Symbol', data = ':'}
				end

			elseif settings.function_types and consume('-') then
				if consume('>') then
					to_emit = {type = 'Symbol', data = '->'}
				else
					to_emit = {type = 'Symbol', data = '-'}
				end

			elseif symbols[c] then
				get()
				to_emit = {type = 'Symbol', data = c}

			else
				local contents, all = try_get_long_string()
				if contents then
					to_emit = {type = 'String', data = all, Constant = contents}
				else
					return report_lexer_error("Unexpected Symbol `"..c.."` when paring in source.", 2)
				end
			end

			--add the emitted symbol, after adding some common data
			to_emit.leading_white     = leading_tokens -- table of leading whitespace/comments
			to_emit.all_leading_white = all_leading_white
			--for k, tok in pairs(leading_tokens) do
			--  tokens[#tokens + 1] = tok
			--end

			to_emit.line = this_line
			to_emit.char = this_char
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
	
	function tok:getp() -> int
		return p
	end
	
	function tok:setp(n: int)
		p = n
	end
	
	function tok:get_token_list() -> L.TokenList
		return tokens
	end
	
	--getters
	function tok:peek(n: int?) -> L.Token?
		if n then
			local ix = math.min(#tokens, p+n)
			return tokens[ix]
		else
			return tokens[math.min(#tokens, p)]
		end
	end

	function tok:get(token_list: L.TokenList?) -> L.Token?
		local t = tokens[p]
		p = math.min(p + 1, #tokens)
		if token_list then
			table.insert(token_list, t)
		end
		return t
	end

	function tok:get_ident(token_list: L.TokenList?) -> string?
		if tok:is('ident') then
			return tok:get(token_list).data
		else
			return nil
		end
	end

	function tok:is(t: TokID) -> bool
		return tok:peek().type == t
	end

	-- either cosumes and returns the given symbil if there is one, or nil
	function tok:consume_symbol(symb: string, token_list: L.TokenList?) -> L.Token?
		local t = self:peek()
		if t.type == 'Symbol' then
			if t.data == symb then
				return self:get(token_list)
			else
				return nil
			end
		else
			return nil
		end
	end

	function tok:consume_keyword(kw: string, token_list: L.TokenList?) -> L.Token?
		local t = self:peek()
		if t.type == 'Keyword' and t.data == kw then
			return self:get(token_list)
		else
			return nil
		end
	end

	function tok:is_keyword(kw: string) -> bool
		local t = tok:peek()
		return t.type == 'Keyword' and t.data == kw
	end

	function tok:is_symbol(s: string) -> bool
		local t = tok:peek()
		return t.type == 'Symbol' and t.data == s
	end

	function tok:is_eof() -> bool
		return tok:peek().type == 'Eof'
	end

	return true, tok
end

return L
