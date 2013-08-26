typedef Type = { AstType : 'StatList' }

local function foo() -> Type
	local obj   = {}
	obj.AstType = 'StatList'
	return obj
end
