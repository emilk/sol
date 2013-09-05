local function _set_asserting_metatable(t)
	local error_func =
		function(t, key)
			assert(false, "Attempting to access %q on destroyed class object! (class declared in %s)", t.class_name, t.declaring_source_file)
		end

	return setmetatable(t, {
		__index = error_func,
		__newindex = error_func,
	})
end

--- Destroys the instance of some class by setting all fields and functions to nil and sets self.destroyed to true afterwards.
-- @usage
--self:destroy_object()
--if self.destroyed then print("Object is destroyed!") end
-- @function self:destroy_object
local function _destroy_object(self)
	for key, _ in pairs(self) do
		if key ~= "class_name" and key ~= "declaring_source_file" then
			self[key] = nil
		end
	end
	self.destroyed = true

	_set_asserting_metatable(self)
end

--- Declares a new class named klass which will have the optionally given super as super class
-- To create objects of this class just call klass(). The constructor must be declared as function SomeClass:init().
-- @usage
--SomeClass = class(SomeClass, SomeSuperClass)
--function SomeClass:init()
-- @usage local some_class_object = SomeClass()
-- @param klass the table to use as template when creating new objects
-- @param super [optional] the super class whose (non-overridden) functions will be available in klass
global function sol_class(klass_name, super_name)
	assert(klass_name, "You must specify a class name")

	if super_name ~= nil then
		assert(rawget(_G, super_name), "Undefined super class " .. super_name)
	end

	local klass = rawget(_G, klass_name)
	if not klass then
		klass = {}

		local instance_meta = { __index = klass }

		local construct = function(instance: table?, ...)
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
		klass.destroy_object = _destroy_object

		-- if some_obj:isa(Widget) then ...
		function klass:isa( some_class )
			var<table?> c = klass
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
