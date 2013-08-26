local D = {}

D.active = false


function D.get_lib() -> any
	if D.active then
		local DEBUG_LIB = "debugger"
		return require(DEBUG_LIB)
	else
		return nil
	end
end


function D.activate()
	D.active = true
end

function D.assert(...)
	if D.active then
		local dbg = D.get_lib()
		dbg.assert(...)
	else
		assert(...)
	end
end

function D.break_()
	if D.active then
		print("Breaking debugger")
		local dbg = D.get_lib()
		dbg()
	end
end

function D.error(...)
	D.break_()
	error(...)
end

return D
