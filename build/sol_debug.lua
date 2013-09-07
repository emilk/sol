--[[ DO NOT MODIFY - COMPILED FROM sol/sol_debug.sol --]] local D = {}

D.active = false


function D.get_lib()
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

function D.assert(bool_expr, fmt, ...)
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

function D.error(msg)
	print("ERROR: " .. msg)
	D.break_()
	error(msg)
end

return D
