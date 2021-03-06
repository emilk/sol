require 'globals' -- g_write_timings
local U = require 'util'
local D = require 'sol_debug'
local set = U.set

var LOWER_CHARS  = set{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
                       'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
                       's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
var UPPER_CHARS  = set{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
                       'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
                       'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
var DIGITS       = set{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
var HEX_DIGITS   = set{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                       'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'}

var IDENT_START_CHARS = U.set_join(LOWER_CHARS, UPPER_CHARS, set{'_'})
var IDENT_CHARS       = U.set_join(IDENT_START_CHARS, DIGITS)


-- Stats:
var g_type_to_count    = {} : {string => uint}
var g_symbol_to_count  = {} : {string => uint}
var g_keyword_to_count = {} : {string => uint}


local L = {}

typedef TokID = 'Keyword' or 'Ident' or 'Number' or 'String' or 'Symbol' or 'Eof'

typedef Token = {
	type          : TokID,
	data          : string?,
	line          : int?,
	char          : int?,
	leading_white : string? -- TODO: no '?'
}

typedef L.Token = Token
typedef L.TokenList = [L.Token]


local function extract_chars(str: string) -> [string]
	var chars = {} : [string]
	if true then
		-- Fastest
		for i = 1, #str do
			chars #= str:sub(i,i)
		end
	elseif true then
		str:gsub(".", function(c)
			chars #= c
		end)
	else
		for chr in str:gmatch(".") do
			chars #= chr
		end
	end
	assert(#chars == #str)

	-- Signal eof:
	chars #= ''
	chars #= ''
	chars #= ''

	return chars
end


-- The settings are found in Parser.sol
function L.lex_sol(src: string, filename: string, settings) -> bool, any
	local tic = os.clock()
	assert(type(src) == 'string')

	local chars = extract_chars(src)

	local symbols  = settings.symbols
	local keywords = settings.keywords

	--token dump
	var tokens = {} : [L.Token]

	local function local_lexer() -> void
		--line / char / pointer tracking
		local line, char, p = 1,1,1

		--get / peek functions
		local function get() -> string
			--local c = src:sub(p,p)
			local c = chars[p]
			if c == '\n' then
				char = 1
				line +=  1
			else
				char +=  1
			end
			p +=  1
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
			return nil
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
					equals_count +=  1
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
									depth +=  1
									for i = 1, (equals_count + 2) do
										get()
									end
								end
							end
							found_end = false
						end
						--
						if found_end then
							depth -= 1
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
			--local leading_white, leading_tokens = get_leading_white_old()
			local leading_white = get_leading_white()

			--get the initial char
			local this_line = line
			local this_char = char
			local c = chars[p]

			--symbol to emit
			var to_emit = nil : Token?

			--branch on type
			if c == '' then
				--eof
				to_emit = { type = 'Eof' }

			elseif IDENT_START_CHARS[c] then
				--ident or keyword
				local start = p
				repeat
					get()
					c = chars[p]
				until not IDENT_CHARS[c]
				local dat = src:sub(start, p-1)
				if keywords[dat] then
					to_emit = {type = 'Keyword', data = dat}
				else
					to_emit = {type = 'Ident', data = dat}
				end

			elseif DIGITS[c] or (chars[p] == '.' and DIGITS[peek(1)]) then
				--number const
				local start = p
				if c == '0' and peek(1) == 'x' then
					get()  -- 0
					get()  -- x
					while HEX_DIGITS[chars[p]] do get() end
					if consume('Pp') then
						consume('+-')
						while DIGITS[chars[p]] do get() end
					end
				else
					while DIGITS[chars[p]] do get() end
					if consume('.') then
						while DIGITS[chars[p]] do get() end
					end
					if consume('Ee') then
						consume('+-')
						while DIGITS[chars[p]] do get() end
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

			elseif consume('.') then
				if consume('.') then
					if consume('.') then
						to_emit = {type = 'Symbol', data = '...'}
					elseif consume('=') then
						to_emit = {type = 'Symbol', data = '..='}
					else
						to_emit = {type = 'Symbol', data = '..'}
					end
				else
					to_emit = {type = 'Symbol', data = '.'}
				end

			elseif symbols[c .. peek(1)] then
				-- two-character symbol
				var symbol = get()
				symbol ..= get()
				to_emit = {type = 'Symbol', data = symbol}

			elseif symbols[c] then
				get()
				to_emit = {type = 'Symbol', data = c}

			else
				return report_lexer_error("Unexpected Symbol `"..c.."`.", 2)
			end

			--add the emitted symbol, after adding some common data
			--to_emit.lading_white_token_list = leading_tokens -- table of leading whitespace/comments
			to_emit.leading_white = leading_white
			--for k, tok in pairs(leading_tokens) do
			--  tokens #= tok
			--end

			to_emit.line = this_line
			to_emit.char = this_char
			tokens #= to_emit

			--halt after eof has been emitted
			if to_emit.type == 'Eof' then break end
		end
	end

	local st, err = pcall( local_lexer )

	if not st then
		U.printf_err( "%s", err )
		return false, err
	end

	----------------------------------------

	if g_print_stats then
		for _, tok in ipairs(tokens) do
			g_type_to_count[tok.type] = (g_type_to_count[tok.type] or 0) + 1
			if tok.type == 'Symbol' then
				g_symbol_to_count[tok.data] = (g_symbol_to_count[tok.data] or 0) + 1
			end
			if tok.type == 'Keyword' then
				g_keyword_to_count[tok.data] = (g_keyword_to_count[tok.data] or 0) + 1
			end
		end
	end

	----------------------------------------

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
			--return tokens[math.min(#tokens, p)]
			return tokens[p]
		end
	end

	function tok:get(token_list: L.TokenList?) -> L.Token?
		local t = tokens[p]
		p = math.min(p + 1, #tokens)
		if token_list then
			token_list #= t
		end
		return t
	end

	function tok:get_ident(token_list: L.TokenList?) -> string?
		if tok:is('Ident') then
			return tok:get(token_list).data
		else
			return nil
		end
	end

	function tok:is(t: TokID) -> bool
		return tokens[p].type == t
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

	local toc = os.clock()
	if g_write_timings then
		U.printf("Lexing %s: %d tokens in %.1f ms", filename, #tokens, 1000*(toc-tic))
	end

	return true, tok
end


function L.print_stats()
	U.printf("Token popularity:")
	U.print_sorted_stats(g_type_to_count)

	U.printf("Symbol popularity:")
	U.print_sorted_stats(g_symbol_to_count)

	U.printf("Keyword popularity:")
	U.print_sorted_stats(g_keyword_to_count)
end


return L
