local function foo(arg)
end

pcall(function()
	foo('too', 'many')  -- FAIL
end)

pcall(foo, 'too', 'many')  -- TODO: FAIL (doesn't yet)
