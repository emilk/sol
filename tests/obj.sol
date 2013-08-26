typedef Token = {
	tag : 'string' or 'num',
	value : string
}

local function foo(t: Token)
	print(t.tag .. t.value)
end

foo( {
	tag = 'num',
	value = '42'
} )
