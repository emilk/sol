local function foo() -> bool, int, string, [int]
	return true, 42, "hello", {42}
end

_,_,_,_ = foo()
