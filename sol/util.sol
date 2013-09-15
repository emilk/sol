--[[
Util.lua

Provides some common utilities shared throughout the project.
--]]

local D = require 'sol_debug'

------------------------------------------------

local U = {}

local PLATFORM = os.getenv("windir") and "win" or "unix"

------------------------------------------------------
--[[
	Lua pretty-printing of anything as lua-code.
	Only supports DAG:s.
--]]


local function is_identifier(key: string) -> bool
	return key:match('^[_%a][_%w]*$')
end


local function is_keyword(key: string) -> bool
	return key == "and"
	or     key == "break"
	or     key == "do"
	or     key == "else"
	or     key == "elseif"
	or     key == "end"
	or     key == "false"
	or     key == "for"
	or     key == "function"
	or     key == "if"
	or     key == "in"
	or     key == "local"
	or     key == "nil"
	or     key == "not"
	or     key == "or"
	or     key == "repeat"
	or     key == "return"
	or     key == "then"
	or     key == "true"
	or     key == "until"
	or     key == "while"

	-- Sol:
	or     key == "class"
	or     key == "global"
	or     key == "typedef"
	or     key == "var"
end


local function is_safe_key(key: string) -> bool
	return is_identifier(key) and not is_keyword(key)
end


-- val         - value to serialize
-- ignore_set   - ignore these key:s
-- indent      - indent on any _subsequent_ line
-- discovered  - set of tables already processed (used to discover loops)
function U.serialize_to_rope(rope, val, ignore_set, indent: string?, discovered: {table}?) -> void
	if val == nil then
		rope[#rope+1] = "nil"
		return
	end

	ignore_set = ignore_set or {}
	indent     = indent     or ""
	discovered = discovered or {}
	
	if type(val) == "table" then
		if discovered[val] then
			--error("serialize: loop discovered")
			rope[#rope+1] = 'LOOP'
			return
		end
		discovered[val] = true

		local scope_indent = indent .. "   "
		rope[#rope+1] = "{\n"
		if U.is_array(val) then
			for _,v in ipairs(val) do
				rope[#rope+1] = scope_indent
				U.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered)
				rope[#rope+1] = ",\n"
			end
		else
			for k,v in pairs(val) do
				--if not ignore_set[k] then
				if true then
					local key = is_safe_key(k) and k or string.format("[%q]", k)

					rope[#rope+1] = scope_indent
					rope[#rope+1] = key
					rope[#rope+1] = " = "

					if ignore_set[k] then
						rope[#rope+1] = 'ignored'
					else
						U.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered)
					end

					rope[#rope+1] = ",\n"
				end
			end
		end
		rope[#rope+1] = indent .. "}"
	elseif type(val) == "string" then
		rope[#rope+1] = string.format("%q", val)
	elseif type(val) == "number" or type(val) == "boolean" then
		rope[#rope+1] = tostring(val)
	else
		--error("serialize: Can't serialize something of type " .. type(val))
		rope[#rope+1] = tostring(val)
	end
end


function U.serialize(val, ignore_set) -> string
	local rope = {}
	U.serialize_to_rope(rope, val, ignore_set, nil, nil)
	local str = table.concat(rope)
	return str
end


function U.pretty(arg)
	return U.serialize(arg)
end

------------------------------------------------------

function U.trim(str: string) -> string
	return str:gsub("^%s*(.-)%s*$", "%1")
end

function U.indent(str: string) -> string
	local indentation = "   "
	return indentation..str:gsub("\n", "\n"..indentation)
end


function U.printf(fmt: string, ...)
	print(string.format(fmt, ...))
end


function U.ellipsis(msg: string, max_len: int?) -> string
	max_len = max_len or 2048

	if #msg <= max_len then
		return msg
	else
		--return msg:sub(1, max_len/2) .. ' [...] ' .. msg:sub(-max_len/2)
		return msg:sub(1, max_len/2) .. '\n[...]\n' .. msg:sub(-max_len/2)
	end
end


function U.printf_err(fmt: string, ...)
	local msg = string.format(fmt, ...)

	--msg = U.ellipsis(msg)

	io.stderr:write( msg .. '\n' )
	D.break_()

	if _G.g_break_on_error then
		os.exit(1)
	end
end


------------------------------------------------------
-- Files:


function U.file_exists(path: string) -> bool
	local f = io.open(path, "rb")
	if f then
		f:close()
		return true
	else
		return false
	end
end

function U.write_protect(path: string) -> bool
	if PLATFORM == "unix" then
		return 0 == os.execute("chmod -w " .. path)
	else
		return 0 == os.execute("attrib +R " .. path)
	end
end


function U.write_unprotect(path: string) -> bool
	if U.file_exists(path) then
		if PLATFORM == "unix" then
			return 0 == os.execute("chmod +w " .. path)
		else
			return 0 == os.execute("attrib -R " .. path)
		end
	end
end


function U.read_entire_file(path: string) -> string?
	local f = io.open(path, "rb")
	if not f then return nil end
	local content = f:read("*all")
	f:close()
	content = content:gsub('\r', '')  -- Fixes sillyness on windows
	return content
end


function U.read_entire_stdin() -> string?
	return io.read("*all")
end


function U.write_file(path: string, contents: string) -> bool
	local f = io.open(path, "w")
	if not f then return false end
	f:write(contents)
	f:close()
	return true
end


------------------------------------------------------
-- Tables and arrays etc:


function U.is_array(val) -> bool
	if type(val) ~= "table" then
		return false
	end

	if getmetatable(val) ~= nil then
		return false
	end

	local max, n = 0, 0

	for ix, _ in pairs(val) do
		if type(ix) ~= "number" or ix <= 0 or math.floor(ix) ~= ix then
			return false
		end

		max = math.max(max, ix)
		n = n + 1
	end

	return n == max
end


function U.set(tb: [string]) -> {string}
	var<{string}> set = {}
	for ix,v in ipairs(tb) do
		set[v] = true
	end
	return set
end


function U.list_join(out: [any], in_table: [any])
	for ix,val in ipairs(in_table) do
		out[#out + 1] = val
	end
end


function U.list_concat(a: [any], b: [any]) -> [any]
	var<[any]> ret = {}
	for _,v in ipairs(a) do
		ret[#ret + 1] = v
	end
	for _,v in ipairs(b) do
		ret[#ret + 1] = v
	end
	return ret
end


function U.table_empty(t: table) -> bool
	return next(t) == nil and getmetatable(t) == nil
end


function U.shallow_clone(t: table?) -> table?
	if not t then return t end
	var<table> t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

function U.table_clear(t: table)
	for k,v in pairs(t) do
		t[k] = nil
	end
end


------------------------------------------------------
-- TODO: only in debug/development
local DEBUG = false

-- Returns a write-protected version of the input table
function U.const(table: table) -> object
	if DEBUG then
		assert(getmetatable(table) == nil)

		return setmetatable({}, {
			__index    = table,
			__newindex = function(table, key, value)
				D.error("Attempt to modify read-only table")
			end,
			__metatable = 'This is a read-only table' -- disallow further meta-tabling
		})
	else
		return table
	end
end

-- Write-protects existing table against all modification
function U.make_const(table: object) -> void
	if DEBUG then
		assert(getmetatable(table) == nil)

		local clone = U.shallow_clone(table)

		U.table_clear(table)

		setmetatable(table, {
			__index    = clone,
			__newindex = function(table, key, value)
				D.error("Attempt to modify read-only table")
			end,
			__metatable = 'This is a read-only table' -- disallow further meta-tabling
		})
	end
end

------------------------------------------------------

return U
