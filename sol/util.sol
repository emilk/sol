--[[
Util.lua

Provides some common utilities shared throughout the project.
--]]

local pretty = require 'pretty'
local D      = require 'sol_debug'
local U = {}

function U.bimap(tb: table) -> table
	for k, v in pairs(tb) do
		assert(k, "bimap with 'false' is dangerous")
		tb[v] = k
	end
	return tb
end


function U.pretty(arg)
	return pretty.serialize(arg)
end


function U.printf(fmt: string, ...)
	print(string.format(fmt, ...))
end


function U.printf_err(fmt: string, ...)
	local msg = string.format(fmt, ...)

	local MAX_LEN = 256
	if #msg > MAX_LEN then
		msg = msg:sub(1, MAX_LEN/2) .. ' ... ' .. msg:sub(-MAX_LEN/2)
	end

	io.stderr:write( msg .. '\n' )
	D.break_()

	if _G.g_spam then
		os.exit(1)	
	end
end


function U.file_exists(path: string) -> bool
	local f = io.open(path, "rb")
	if f then
		f:close()
		return true
	else
		return false
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


function U.is_array(val) -> bool
	if type(val) ~= "table" then
		return false;
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


function U.table_join(out, in_table)
	assert(out ~= in_table, "table_join: in and out array must be different")
	for key, val in pairs(in_table) do
		out[key] = val
	end
	return out
end


function U.shallow_clone(t: any) -> any  -- TODO
	if not t then return t end
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end


function U.trim(str: string) -> string
	return str:gsub("^%s*(.-)%s*$", "%1")	
end


return U
