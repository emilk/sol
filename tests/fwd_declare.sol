typedef A;

typedef B = {
	a : A
}

typedef A = {
	b : B
}

local function a2b(a: A) -> B
	return { a = a }
end

local function b2a(b: B) -> A
	return { b = b }
end
