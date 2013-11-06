--[[ DO NOT MODIFY - COMPILED FROM .\tests\multiple_throwaway.sol --]] local function foo()
	return true, 42, "hello", {42} --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

_,_,_,_ = foo() --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 