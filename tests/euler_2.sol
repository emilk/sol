-- http://projecteuler.net/problem=2

local a,b = 1,2
local sum = 0

while b <= 4000000 do
	if b % 2 == 0 then
		sum = sum + b
	end
	a,b = b,a+b
end

print(sum)
