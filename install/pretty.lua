--[[ DO NOT MODIFY - COMPILED FROM sol/pretty.sol --]] --[[
Written by Emil Ernerfeldt in June 2013
Lua pretty-printing of anything as lua-code.
Only supports DAG:s.
Will throw on cycles.
Not well tested.
--]]

local M = {} --[[SOL OUTPUT--]] 


local function is_array(val)
	if type(val) ~= "table" then
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
function M.serialize_to_rope(rope, val, ignore_set, indent, discovered)
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
		if is_array(val) then
			for _,v in ipairs(val) do
				rope[#rope+1] = scope_indent --[[SOL OUTPUT--]] 
				M.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered) --[[SOL OUTPUT--]] 
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
						M.serialize_to_rope(rope, v, ignore_set, scope_indent, discovered) --[[SOL OUTPUT--]] 
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


function M.serialize(val, ignore_set)
	local rope = {} --[[SOL OUTPUT--]] 
	M.serialize_to_rope(rope, val, ignore_set, nil, nil) --[[SOL OUTPUT--]] 
	local str = table.concat(rope) --[[SOL OUTPUT--]] 
	return str --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


return M --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 