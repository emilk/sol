--[[ DO NOT MODIFY - COMPILED FROM sol/sol_debug.sol on 2013 Sep 29  22:57:05 --]] local D = {} --[[SOL OUTPUT--]] 

D.active = false --[[SOL OUTPUT--]] 

function D.get_lib()
	if D.active then
		return require("debugger") --[[SOL OUTPUT--]] 
	else
		return nil --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 


function D.activate()
	D.active = true --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function D.assert(bool_expr, fmt, ...)
	--D.active = true

	if bool_expr then
		return bool_expr --[[SOL OUTPUT--]] 
	elseif D.active then
		local dbg = D.get_lib() --[[SOL OUTPUT--]] 
		return dbg.assert(bool_expr, fmt, ...) --[[SOL OUTPUT--]] 
	else
		return assert(bool_expr, fmt, ...) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function D.break_()
	if D.active then
		print("Breaking debugger") --[[SOL OUTPUT--]] 
		local dbg = D.get_lib() --[[SOL OUTPUT--]] 
		dbg() --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

function D.error(msg)
	print("ERROR: " .. msg) --[[SOL OUTPUT--]] 
	D.break_() --[[SOL OUTPUT--]] 
	error(msg) --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return D --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 