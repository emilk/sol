Sol
===
Typesafe Lua. Work in progress.

 
## What?
Sol is an almost-super-set of Lua that provides a novel(?) form of static, non-constricting optional type safety. Sol compiles line-for-line to Lua, and is thus compatible with existing Lua code (both ways) and tools (luajit, profilers, debuggers etc).

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
	var<Option> x = "B"
	
	
	-- Stuff the compiler catches:
	x = "D" -- ERROR: "D" is not an Option
	X = "A" -- ERROR: 'X' is undeclared
	sqrt()  -- ERROR: Missing non-nilable argument 'x'
	use{foo: "fortytwo", bar: 42}  -- ERROR


## Why?
> We need to defend ourselves from Murphy’s Million Monkeys

> *- Chandler Carruth, Clang*

Scripting languages like Lua has many things going for them, but they all fail to catch errors early. Lua is especially bad due to things like implicit globals and nil-defaulting. We need something better. We need to turn away from the darkness of the moon towards the light of the sun. We need Sol.

That being said, dynamically typed languages provides a flexibility that a statically typed language like C++ or Java does not. Sol aims to provide the best of both worlds by the concept of *plausible typing*.

Type annotations also help makes the code more readible as it provides **self-documentation**.


## State
Sol is work in progress and is still evolving rapidly. Version 1.0 expected some tme 2013.


## Similar attempts
There has been other atempts to bring static typing to Lua. Hoever, they all suffer from attempting to be compatible without compilation, which means putting the type into comments or via MetaLua-syntax which makes the code ugly to the point of unintelligibleness. My experience tells me that if it aint pretty, it aint gonna be used.

### [Tidal Lock](https://github.com/fab13n/metalua/tree/tilo/src/tilo)

Based on MetaLua. Cumbersome syntax:

	local n #var number = 42

Compard to Sol:

	var<number> n = 42

### [Lua analyzer](https://bitbucket.org/kevinclancy/love-studio/wiki/OptionalTypeSystem)

Extremely ugly syntax with type-annotations in comments. A non-starter.


## Credit
Parser based on [LuaMinify](https://github.com/stravant/LuaMinify).