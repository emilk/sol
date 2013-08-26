local function print_all(head : string?, ... : int)
	if head then
		print(head)
		print_all(...)  -- Recurse on tail - but oh - head is of the wrong type!
	end
end
