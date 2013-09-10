local D = {}

D.active = false

function D.get_lib() -> any
	if D.active then
		return require("debugger")
	else
		return nil
	end
end


function D.activate()
	D.active = true
end

function D.assert(bool_expr, fmt: string?, ...)
	--D.active = true

	if bool_expr then
		return bool_expr
	elseif D.active then
		local dbg = D.get_lib()
		return dbg.assert(bool_expr, fmt, ...)
	else
		return assert(bool_expr, fmt, ...)
	end
end

function D.break_()
	if D.active then
		print("Breaking debugger")
		local dbg = D.get_lib()
		dbg()
	end
end

function D.error(msg: string)
	print("ERROR: " .. msg)
	D.break_()
	error(msg)
end

return D
