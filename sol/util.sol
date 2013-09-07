--[[
Util.lua

Provides some common utilities shared throughout the project.
--]]

local pretty = require 'pretty'
local D      = require 'sol_debug'

------------------------------------------------

local U = {}

local PLATFORM = os.getenv("windir") and "win" or "unix"

------------------------------------------------------

function U.trim(str: string) -> string
	return str:gsub("^%s*(.-)%s*$", "%1")	
end


function U.pretty(arg)
	return pretty.serialize(arg)
end


function U.printf(fmt: string, ...)
	print(string.format(fmt, ...))
end


function U.ellipsis(msg: string, max_len: int?)
	max_len = max_len or 1024

	if #msg <= max_len then
		return msg
	else
		return msg:sub(1, max_len/2) .. ' [...] ' .. msg:sub(-max_len/2)
	end
end


function U.printf_err(fmt: string, ...)
	local msg = string.format(fmt, ...)

	msg = U.ellipsis(msg)

	io.stderr:write( msg .. '\n' )
	D.break_()

	if _G.g_spam then
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


function U.bimap(tb: table) -> table
	for k, v in pairs(tb) do
		D.assert(k, "bimap with 'false' is dangerous")
		--D.assert(not tb[v], "bimap clashes") since we iterate over outselves, this is a bad idea
		tb[v] = k
	end
	return tb
end


function U.table_join(out: table, in_table: table) -> table
	assert(out ~= in_table, "table_join: in and out array must be different")
	for key, val in pairs(in_table) do
		out[key] = val
	end
	return out
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
	return next(t) == nil
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

-- Write-protects existing table against all modification
function U.write_protect_table(table: {}) -> void
	-- TODO: only in debug/development

	local clone = U.shallow_clone(table)

	assert(getmetatable(table) == nil)
	U.table_clear(table)

	setmetatable(table, {
		__index    = clone,
		__newindex = function(table, key, value)
			D.error("Attempt to modify read-only table")
		end,
		__metatable = 'This is a read-only table' -- disallow further meta-tabling
	})
end

------------------------------------------------------

return U
