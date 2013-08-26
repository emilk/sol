local map = { ['one'] = 1, ['two'] = 2, ['three'] = 3 }
for k,v in ipairs(map) do  -- FAIL: Should be 'pairs'
end