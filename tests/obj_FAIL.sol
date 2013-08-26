	typedef Token = {
		tag : 'string' or 'num',
		value : string
	}

	local function foo(t: Token)
		print(t.tag .. t.value)
	end

	-- OK:
	foo( {
		tag = 'string',
		value = '42'
	} )


	-- FAIL:
	foo( {
		tag = 'wrong',
		value = '42'
	} )
