--[[ DO NOT MODIFY - COMPILED FROM sol/ast.sol --]] -- aux-functions for ast:s

local P = require 'parser' --[[SOL OUTPUT--]]  -- TODO: make it the other way around
local D = require 'sol_debug' --[[SOL OUTPUT--]] 

local AST = {} --[[SOL OUTPUT--]] 

-- Are two AST:s equal? Good for detecting stupid stuff like  a = a
-- Assummes same scope etc
function AST.eq(a, b)
	if a == b then return true --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]]  -- Not sure when this could happen

	if a.ast_type ~= b.ast_type then
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local ast_type = a.ast_type --[[SOL OUTPUT--]] 

	if ast_type == 'IdExpr' then
		return a.name == b.name --[[SOL OUTPUT--]] 

	elseif ast_type == 'MemberExpr' then
		D.break_() --[[SOL OUTPUT--]] 
		return a.ident.data == b.ident.data and a.indexer == b.indexer and AST.eq(a.base, b.base) --[[SOL OUTPUT--]] 

	-- TODO: more ast nodes than two =)

	else
		return false --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 

return AST --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 