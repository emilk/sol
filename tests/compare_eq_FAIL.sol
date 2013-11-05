local x = 42
x = x

if x == x then
	print("always")
end

local y = { a = true }

if y.a or y.a then
	print("always")
end
