--[[ DO NOT MODIFY - COMPILED FROM sol/util.sol --]] --[[
Util.lua

Provides some common utilities shared throughout the project.
--]]

local D = require 'sol_debug' --[[SOL OUTPUT--]] 

------------------------------------------------

local U = {} --[[SOL OUTPUT--]] 

local PLATFORM = os.getenv("windir") and "win" or "unix" --[[SOL OUTPUT--]] 

------------------------------------------------------
--[[
	Lua pretty-printing of anything as lua-code.
	Only supports DAG:s.
--]]


local function is_identifier(key)
	return key:match('^[_%a][_%w]*$') --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function is_keyword(key)
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
	or     key == "while" --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


local function is_safe_key(key)
	return is_identifier(key) and not is_keyword(key) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


-- val         - value to serialize
-- ignore_set   - ignore these key:s
-- indent      - indent on any _subsequent_ line
-- discovered  - set of tables already processed (used to discover loops)
function U.serialize_to_rope(rope, val, ignore_set, indent, discovered)
	if val == nil then
		rope[#rope+1] = "nil" --[[SOL OUTPUT--]] 
		return --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	ignore_set = ignore_set or {} --[[SOL OUTPUT--]] 
	indent     = indent     or "" --[[SOL OUTPUT--]] 
	discovered = discovered or {} --[[SOL OUTPUT--]] 
	
	if type(val) == "table" then
		if discovered[val] then
			--error("serialize: loop discovered")
			rope[#rope+1] = 'LOOP' --[[SOL OUTPUT--]] 
			return --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		discovered[val] = true --[[SOL OUTPUT--]] 

		local scope_indent = indent .. "   " --[[SOL OUTPUT--]] 
		rope[#rope+1] = "{\n" --[[SOL OUTPUT--]] 
		if U.is_array(val) then
			for _,v in ipairs(val) do
				rope[#rope+1] = scope_indent --[[SOL OUTPUT--]] 
				U.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered) --[[SOL OUTPUT--]] 
				rope[#rope+1] = ",\n" --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		else
			for k,v in pairs(val) do
				--if not ignore_set[k] then
				if true then
					local key = is_safe_key(k) and k or string.format("[%q]", k) --[[SOL OUTPUT--]] 

					rope[#rope+1] = scope_indent --[[SOL OUTPUT--]] 
					rope[#rope+1] = key --[[SOL OUTPUT--]] 
					rope[#rope+1] = " = " --[[SOL OUTPUT--]] 

					if ignore_set[k] then
						rope[#rope+1] = 'ignored' --[[SOL OUTPUT--]] 
					else
						U.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered) --[[SOL OUTPUT--]] 
					end --[[SOL OUTPUT--]] 

					rope[#rope+1] = ",\n" --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
		rope[#rope+1] = indent .. "}" --[[SOL OUTPUT--]] 
	elseif type(val) == "string" then
		rope[#rope+1] = string.format("%q", val) --[[SOL OUTPUT--]] 
	elseif type(val) == "number" or type(val) == "boolean" then
		rope[#rope+1] = tostring(val) --[[SOL OUTPUT--]] 
	else
		--error("serialize: Can't serialize something of type " .. type(val))
		rope[#rope+1] = tostring(val) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.serialize(val, ignore_set)
	local rope = {} --[[SOL OUTPUT--]] 
	U.serialize_to_rope(rope, val, ignore_set, nil, nil) --[[SOL OUTPUT--]] 
	local str = table.concat(rope) --[[SOL OUTPUT--]] 
	return str --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.pretty(arg)
	return U.serialize(arg) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

------------------------------------------------------

function U.trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1") --[[SOL OUTPUT--]] 	
end --[[SOL OUTPUT--]] 


function U.printf(fmt, ...)
	print(string.format(fmt, ...)) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.ellipsis(msg, max_len)
	max_len = max_len or 1024 --[[SOL OUTPUT--]] 

	if #msg <= max_len then
		return msg --[[SOL OUTPUT--]] 
	else
		return msg:sub(1, max_len/2) .. ' [...] ' .. msg:sub(-max_len/2) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.printf_err(fmt, ...)
	local msg = string.format(fmt, ...) --[[SOL OUTPUT--]] 

	msg = U.ellipsis(msg) --[[SOL OUTPUT--]] 

	io.stderr:write( msg .. '\n' ) --[[SOL OUTPUT--]] 
	D.break_() --[[SOL OUTPUT--]] 

	if _G.g_spam then
		os.exit(1) --[[SOL OUTPUT--]] 	
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


------------------------------------------------------
-- Files:


function U.file_exists(path)
	local f = io.open(path, "rb") --[[SOL OUTPUT--]] 
	if f then
		f:close() --[[SOL OUTPUT--]] 
		return true --[[SOL OUTPUT--]] 
	else
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function U.write_protect(path)
	if PLATFORM == "unix" then
		return 0 == os.execute("chmod -w " .. path) --[[SOL OUTPUT--]] 
	else
		return 0 == os.execute("attrib +R " .. path) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.write_unprotect(path)
	if U.file_exists(path) then
		if PLATFORM == "unix" then
			return 0 == os.execute("chmod +w " .. path) --[[SOL OUTPUT--]] 
		else
			return 0 == os.execute("attrib -R " .. path) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.read_entire_file(path)
	local f = io.open(path, "rb") --[[SOL OUTPUT--]] 
	if not f then return nil --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	local content = f:read("*all") --[[SOL OUTPUT--]] 
	f:close() --[[SOL OUTPUT--]] 
	content = content:gsub('\r', '') --[[SOL OUTPUT--]]   -- Fixes sillyness on windows
	return content --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.read_entire_stdin()
	return io.read("*all") --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.write_file(path, contents)
	local f = io.open(path, "w") --[[SOL OUTPUT--]] 
	if not f then return false --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	f:write(contents) --[[SOL OUTPUT--]] 
	f:close() --[[SOL OUTPUT--]] 
	return true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


------------------------------------------------------
-- Tables and arrays etc:


function U.is_array(val)
	if type(val) ~= "table" then
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	if getmetatable(val) ~= nil then
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local max, n = 0, 0 --[[SOL OUTPUT--]] 

	for ix, _ in pairs(val) do
		if type(ix) ~= "number" or ix <= 0 or math.floor(ix) ~= ix then
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		max = math.max(max, ix) --[[SOL OUTPUT--]] 
		n = n + 1 --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return n == max --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.bimap(tb)
	for k, v in pairs(tb) do
		D.assert(k, "bimap with 'false' is dangerous") --[[SOL OUTPUT--]] 
		--D.assert(not tb[v], "bimap clashes") since we iterate over outselves, this is a bad idea
		tb[v] = k --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return tb --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.table_join(out, in_table)
	assert(out ~= in_table, "table_join: in and out array must be different") --[[SOL OUTPUT--]] 
	for key, val in pairs(in_table) do
		out[key] = val --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return out --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.list_concat(a, b)
	local ret = {} --[[SOL OUTPUT--]] 
	for _,v in ipairs(a) do
		ret[#ret + 1] = v --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	for _,v in ipairs(b) do
		ret[#ret + 1] = v --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return ret --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.table_empty(t)
	return next(t) == nil and getmetatable(t) == nil --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function U.shallow_clone(t)
	if not t then return t --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
	local t2 = {} --[[SOL OUTPUT--]] 
	for k,v in pairs(t) do
		t2[k] = v --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
	return t2 --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function U.table_clear(t)
	for k,v in pairs(t) do
		t[k] = nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


------------------------------------------------------
-- TODO: only in debug/development

-- Returns a write-protected version of the input table
function U.const(table)
	assert(getmetatable(table) == nil) --[[SOL OUTPUT--]] 

	return setmetatable({}, {
		__index    = table,
		__newindex = function(table, key, value)
			D.error("Attempt to modify read-only table") --[[SOL OUTPUT--]] 
		end,
		__metatable = 'This is a read-only table' -- disallow further meta-tabling
	}) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

-- Write-protects existing table against all modification
function U.make_const(table)
	assert(getmetatable(table) == nil) --[[SOL OUTPUT--]] 

	local clone = U.shallow_clone(table) --[[SOL OUTPUT--]] 

	U.table_clear(table) --[[SOL OUTPUT--]] 

	setmetatable(table, {
		__index    = clone,
		__newindex = function(table, key, value)
			D.error("Attempt to modify read-only table") --[[SOL OUTPUT--]] 
		end,
		__metatable = 'This is a read-only table' -- disallow further meta-tabling
	}) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

------------------------------------------------------

return U --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 