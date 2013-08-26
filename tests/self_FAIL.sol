local Singleton = {}

function Singleton:member() -> void
end

function Singleton.static() -> void
end

function Singleton:bar() -> void
	self.member()       -- FAIL
	Singleton.member()  -- FAIL
	self:member()       -- OK
	Singleton:member()  -- OK

	self.static()       -- OK
	Singleton.static()  -- OK
	self:static()       -- FAIL
	Singleton:static()  -- FAIL

	self.member(self)            -- OK (but ugly)
	Singleton.member(Singleton)  -- OK (but ugly)
	self:member(self)            -- FAIL
	Singleton:member(Singleton)  -- FAIL

	self.static(self)            -- FAIL
	Singleton.static(Singleton)  -- FAIL
	self:static(self)            -- FAIL
	Singleton:static(Singleton)  -- FAIL

	local other = {
		wrong_type = true
	}

	Singleton.member(other)  -- FAIL
	Singleton.member(other)  -- FAIL
	Singleton.static(other)  -- FAIL
	Singleton.static(other)  -- FAIL
end