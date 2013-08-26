local function foo()
	global x = 32  -- Not OK - must be in global scope
end
