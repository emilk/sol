--[[ DO NOT MODIFY - COMPILED FROM sol/pretty.sol --]] --[[
Written by Emil Ernerfeldt in June 2013
Lua pretty-printing of anything as lua-code.
Only supports DAG:s.
Will throw on cycles.
Not well tested.
--]]

local M = {}


local function is_array(val)
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


local function is_identifier(key)
	return key:match('^[_%a][_%w]*$')
end


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
	or     key == "while"
end


local function is_safe_key(key)
	return is_identifier(key) and not is_keyword(key)
end


-- val         - value to serialize
-- ignore_set   - ignore these key:s
-- indent      - indent on any _subsequent_ line
-- discovered  - set of tables already processed (used to discover loops)
function M.serialize_to_rope(rope, val, ignore_set, indent, discovered)
	if val == nil then
		rope[#rope+1] = "nil"
		return
	end

	ignore_set  = ignore_set or {}
	indent     = indent or ""
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
		if is_array(val) then
			for _,v in ipairs(val) do
				rope[#rope+1] = scope_indent
				M.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered)
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
						M.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered)
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


function M.serialize(val, ignore_set)
	local rope = {}
	M.serialize_to_rope(rope, val, ignore_set, nil, nil)
	local str = table.concat(rope)
	return str
end


return M
