global function sol_class(klass_name, super_name)
	assert(klass_name, "You must specify a class name")

	if super_name ~= nil then
		assert(rawget(_G, super_name), "Undefined super class " .. super_name)
	end

	local klass = rawget(_G, klass_name)
	if not klass then
		klass = {}

		local instance_meta = { __index = klass }

		local construct = function(instance, ...)
			if instance then
				-- Clear-out:
				for k,_ in pairs(instance) do
					instance[k] = nil
				end
			else
				instance = {}
			end

			setmetatable(instance, instance_meta)

			if instance.init then instance:init(...) end
			return instance
		end

		local klass_meta = {
			-- Constructor style call, i.e.  ClassName(...)
			__call = function(self, ...)
				return construct(nil, ...)
			end
		}

		if super_name ~= nil then
			local super = rawget(_G, super_name)
			klass_meta.__index = super
			klass.base_class = super
		end

		setmetatable(klass, klass_meta)

		-- Placement new:
		klass._construct = function(instance, ...)
			return construct(instance, ...)
		end

		klass.class_name = klass_name

		-- if some_obj:isa(Widget) then ...
		function klass:isa( some_class )
			local c = klass
			repeat
				if c == some_class then return true end
				c = c.base_class -- Walk up inheritence chain
			until not c
			return false
		end

		local info = debug.getinfo(2)
		klass.declaring_source_file = info.short_src or "No file found"
	end

	return klass
end
