local M = {}

function M.foo()
	M.bar(42) -- FAIL: Not a string
end

function M.bar(arg: string)

end
