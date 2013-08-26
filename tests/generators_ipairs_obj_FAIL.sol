local obj = { one = 1, two = 2, three = 3 }
for k,v in ipairs(obj) do  -- FAIL: Should be 'pairs'
end
