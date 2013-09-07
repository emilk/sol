--[[ DO NOT MODIFY - COMPILED FROM sol/util.sol --]] --[[
Util.lua

Provides some common utilities shared throughout the project.
--]]

local pretty = require 'pretty' --[[SOL OUTPUT--]] 
local D      = require 'sol_debug' --[[SOL OUTPUT--]] 

------------------------------------------------

local U = {} --[[SOL OUTPUT--]] 

local PLATFORM = os.getenv("windir") and "win" or "unix" --[[SOL OUTPUT--]] 

------------------------------------------------------

function U.trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1") --[[SOL OUTPUT--]] 	
end --[[SOL OUTPUT--]] 


function U.pretty(arg)
	return pretty.serialize(arg) --[[SOL OUTPUT--]] 
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
	return next(t) == nil --[[SOL OUTPUT--]] 
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

-- Write-protects existing table against all modification
function U.write_protect_table(table)
	-- TODO: only in debug/development

	local clone = U.shallow_clone(table) --[[SOL OUTPUT--]] 

	assert(getmetatable(table) == nil) --[[SOL OUTPUT--]] 
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