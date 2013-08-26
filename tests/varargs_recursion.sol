local function print_all(head : int?, ... : int)
	if head then
		print(head)
		print_all(...)  -- Recurse on tail
	end
end
