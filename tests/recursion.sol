local M = {}
function M.fun() -> string
	return 'hello' .. M.fun()
end
