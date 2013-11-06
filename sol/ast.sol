-- aux-functions for ast:s

local P = require 'parser' -- TODO: make it the other way around
local D = require 'sol_debug'

local AST = {}

-- Are two AST:s equal? Good for detecting stupid stuff like  a = a
-- Assummes same scope etc
function AST.eq(a: P.Node, b: P.Node) -> bool
	if a == b then return true end -- Not sure when this could happen

	if a.ast_type ~= b.ast_type then
		return false
	end

	var ast_type = a.ast_type

	if ast_type == 'IdExpr' then
		return a.name == b.name

	elseif ast_type == 'MemberExpr' then
		D.break_()
		return a.ident.data == b.ident.data and a.indexer == b.indexer and AST.eq(a.base, b.base)

	-- TODO: more ast nodes than two =)

	else
		return false
	end
end

return AST
