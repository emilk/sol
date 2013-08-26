local function foo() -> bool?
	if true then
		return false
	else
		return nil
	end
end

if foo() then

end