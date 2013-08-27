local foo, bar;

foo = function()
	bar(42) -- FAIL: Not a string
end

bar = function(arg: string)

end
