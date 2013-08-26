local T = {}

typedef T.Type = {
}


local S = {}

typedef S.Variable = {
	Scope : any, --TODO: S.Scope,
	Name  : string,
	Type  : T.Type?,
	IsGlobal   : bool,
	CanRename  : bool,
	References : int,
	Namespace  : { string => T.Type } ?,
}

typedef S.Scope = {
	Parent   : S.Scope?,
	Children : [S.Scope],
	Locals   : [S.Variable],
	Globals  : [S.Variable],
	Typedefs : { string => T.Type },
	VarArg   : S.Variable?,  -- if non-nil, points to a variable named '...' with the type of T.VarArgs

	--GetScopedType : function(self, name: string) -> T.Type?
}


local Scope = {}

function Scope:new()
end

function Scope:GetScopedType(name: string)
end

function Scope:GetType(name)
end

function Scope:DeclareType(name: string, type: T.Type)
end

function Scope:AddLocal(v: S.Variable)
end

function Scope:AddGlobal(v: S.Variable)
end

function Scope:CreateLocal(name: string)
end

-- Will only check local scope
function Scope:GetScoped(name: string)
end

-- Will check locals and parents
function Scope:GetLocal(name: string)
end

function Scope:GetOldLocal(name: string)
end

function Scope:mapLocal(name, v)
end

function Scope:GetOldGlobal(name)
end

function Scope:mapGlobal(name, v)
end

function Scope:GetOldVariable(name)
end

function Scope:RenameLocal(oldName, newName)
end

function Scope:RenameGlobal(oldName, newName)
end

function Scope:RenameVariable(oldName, newName)
end

function Scope:GetAllVariables()
end

function Scope:getVars(top)
end

function Scope:GetGlobal(name: string)
end

function Scope:CreateGlobal(name: string)
	self:GetGlobal(name)
end

function Scope:GetVariable(name: string)
end


function Scope:GetVarArgs()
end
