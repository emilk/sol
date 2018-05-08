Sol - Typesafe Lua
==================
Static type checker and (optional) gradual typing for Lua.

Sol is to Lua as Typescript is to JS.

## What?
Sol is a dialect (almost super-set) of Lua which adds optional type annotations, to provide type safety through [gradual typing](https://en.wikipedia.org/wiki/Gradual_typing).
Sol compiles line-for-line to Lua, and is thus compatible with existing Lua code (both ways) and tools (luajit, profilers, debuggers etc).

The Sol compiler is written in Sol.


## At a glance

	function sqrt(x: number) -> number?
		return a >= 0 and math.sqrt(x) or nil
	end

	typedef Interface = {
		foo: int,
		bar: string
	}

	function use(x: Interface)
		print(x.bar)
	end

	use{foo: 42, bar: "fortytwo"}

	typedef Option = "A" or "B" or "C"
	var x = "B" : Option

	var CONSTANT = 42

	-- Stuff the compiler catches:
	x = "D" -- ERROR: "D" is not an Option
	X = "A" -- ERROR: 'X' is undeclared
	sqrt()  -- ERROR: Missing non-nilable argument 'x'
	use{foo: "fortytwo", bar: 42}  -- ERROR
	CONSTANT = 1337 -- ERROR: Cannot assign to constant: 'CONSTANT' (upper-case names always assumed constant)


## Why?
> We need to defend ourselves from Murphy’s Million Monkeys

> *- Chandler Carruth, Clang*

Scripting languages like Lua has many things going for them, but they all fail to catch errors early. Lua is especially bad due to things like implicit globals and nil-defaulting. We need something better. We need to turn away from the darkness of the moon towards the light of the sun. We need Sol.

That being said, dynamically typed languages provides a flexibility that a statically typed language like C++ or Java does not. Sol aims to provide the best of both worlds by the concept of *plausible typing*.

Type annotations also help makes the code more readable as it provides **self-documentation**.


## State
Sol is no longer in active development.


## Similar attempts
There has been other attempts to bring static typing to Lua. However, they all suffer from attempting to be compatible without compilation, which means putting the type into comments or via MetaLua-syntax which makes the code ugly to the point of unintelligibleness. My experience tells me that if it ain't pretty, it ain't gonna be used.

### [Tidal Lock](https://github.com/fab13n/metalua/tree/tilo/src/tilo)

Based on MetaLua. Cumbersome syntax:

	local n #var number = 42

Compard to Sol:

	var n = 42 : number

### [Lua analyzer](https://bitbucket.org/kevinclancy/love-studio/wiki/OptionalTypeSystem)

Extremely ugly syntax with type-annotations in comments. A non-starter.


## Credit
Parser based on [LuaMinify](https://github.com/stravant/LuaMinify).
