-- http://projecteuler.net/problem=1

local function sum_3_5(upTo: uint) -> uint
	local sum = 0

	for i = 1, upTo-1 do
		if i % 3 == 0 or i % 5 == 0 then
			--sum += i  -- TODO
			sum = sum + i
		end
	end

	return sum
end

print( sum_3_5(10) )
print( sum_3_5(1000) )
