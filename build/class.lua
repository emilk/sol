--[[ DO NOT MODIFY - COMPILED FROM sol/class.sol on 2013 Oct 01  22:25:07 --]]  function sol_class(klass_name, super_name)
	assert(klass_name, "You must specify a class name") --[[SOL OUTPUT--]] 

	if super_name ~= nil then
		assert(rawget(_G, super_name), "Undefined super class " .. super_name) --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	local klass = rawget(_G, klass_name) --[[SOL OUTPUT--]] 
	if not klass then
		klass = {} --[[SOL OUTPUT--]] 

		local instance_meta = { __index = klass } --[[SOL OUTPUT--]] 

		local construct = function(instance, ...)
			if instance then
				-- Clear-out:
				for k,_ in pairs(instance) do
					instance[k] = nil --[[SOL OUTPUT--]] 
				end --[[SOL OUTPUT--]] 
			else
				instance = {} --[[SOL OUTPUT--]] 
			end --[[SOL OUTPUT--]] 

			setmetatable(instance, instance_meta) --[[SOL OUTPUT--]] 

			if instance.init then instance:init(...) --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
			return instance --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local klass_meta = {
			-- Constructor style call, i.e.  ClassName(...)
			__call = function(self, ...)
				return construct(nil, ...) --[[SOL OUTPUT--]] 
			end
		} --[[SOL OUTPUT--]] 

		if super_name ~= nil then
			local super = rawget(_G, super_name) --[[SOL OUTPUT--]] 
			klass_meta.__index = super --[[SOL OUTPUT--]] 
			klass.base_class = super --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		setmetatable(klass, klass_meta) --[[SOL OUTPUT--]] 

		-- Placement new:
		klass._construct = function(instance, ...)
			return construct(instance, ...) --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		klass.class_name = klass_name --[[SOL OUTPUT--]] 

		-- if some_obj:isa(Widget) then ...
		function klass:isa( some_class )
			local c = klass --[[SOL OUTPUT--]] 
			repeat
				if c == some_class then return true --[[SOL OUTPUT--]]  end --[[SOL OUTPUT--]] 
				c = c.base_class --[[SOL OUTPUT--]]  -- Walk up inheritence chain
			until not c --[[SOL OUTPUT--]] 
			return false --[[SOL OUTPUT--]] 
		end --[[SOL OUTPUT--]] 

		local info = debug.getinfo(2) --[[SOL OUTPUT--]] 
		klass.declaring_source_file = info.short_src or "No file found" --[[SOL OUTPUT--]] 
	end --[[SOL OUTPUT--]] 

	return klass --[[SOL OUTPUT--]] 
end --[[SOL OUTPUT--]] 
 --[[SOL OUTPUT--]] 