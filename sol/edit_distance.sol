-- From  http://nayruden.com/?p=115  -  https://gist.github.com/Nayruden/427389
-- Translated to Sol by Emil Ernerfeldt in 2013
--[[
	Function: EditDistance
 
	Finds the edit distance between two strings or tables. Edit distance is the minimum number of
	edits needed to transform one string or table into the other.
	
	Parameters:
	
		s - A *string* or *table*.
		t - Another *string* or *table* to compare against s.
		lim - An *optional number* to limit the function to a maximum edit distance. If specified
			and the function detects that the edit distance is going to be larger than limit, limit
			is returned immediately.
			
	Returns:
	
		A *number* specifying the minimum edits it takes to transform s into t or vice versa. Will
			not return a higher number than lim, if specified.
			
	Example:
 
		:EditDistance( "Tuesday", "Teusday" ) -- One transposition.
		:EditDistance( "kitten", "sitting" ) -- Two substitutions and a deletion.
 
		returns...
 
		:1
		:3
			
	Notes:
	
		* Complexity is O( (#t+1) * (#s+1) ) when lim isn't specified.
		* This function can be used to compare array-like tables as easily as strings.
		* The algorithm used is Damerau–Levenshtein distance, which calculates edit distance based
			off number of subsitutions, additions, deletions, and transpositions.
		* Source code for this function is based off the Wikipedia article for the algorithm
			<http://en.wikipedia.org/w/index.php?title=Damerau%E2%80%93Levenshtein_distance&oldid=351641537>.
		* This function is case sensitive when comparing strings.
		* If this function is being used several times a second, you should be taking advantage of
			the lim parameter.
		* Using this function to compare against a dictionary of 250,000 words took about 0.6
			seconds on my machine for the word "Teusday", around 10 seconds for very poorly 
			spelled words. Both tests used lim.
			
	Revisions:
 
		v1.00 - Initial.
]]
local function edit_distance( s: string or [int], t: string or [int], lim: int? ) -> int
	var s_len, t_len = #s, #t -- Calculate the sizes of the strings or arrays
	if lim and math.abs( s_len - t_len ) >= lim then -- If sizes differ by lim, we can stop here
		return lim
	end
	
	-- Convert string arguments to arrays of ints (ASCII values)
	if type( s ) == "string" then
		s = { string.byte( s, 1, s_len ) }
	end
	
	if type( t ) == "string" then
		t = { string.byte( t, 1, t_len ) }
	end
	
	var min = math.min : function(...:int)->int -- Localize for performance
	var num_columns = t_len + 1 -- We use this a lot
	
	var d = {} : [int] -- (s_len+1) * (t_len+1) is going to be the size of this array
	-- This is technically a 2D array, but we're treating it as 1D. Remember that 2D access in the
	-- form my_2d_array[ i, j ] can be converted to my_1d_array[ i * num_columns + j ], where
	-- num_columns is the number of columns you had in the 2D array assuming row-major order and
	-- that row and column indices start at 0 (we're starting at 0).
	
	for i=0, s_len do
		d[ i * num_columns ] = i -- Initialize cost of deletion
	end
	for j=0, t_len do
		d[ j ] = j -- Initialize cost of insertion
	end
	
	for i=1, s_len do
		var i_pos = i * num_columns
		var best = lim -- Check to make sure something in this row will be below the limit
		for j=1, t_len do
			var add_cost = (s[ i ] ~= t[ j ] and 1 or 0)
			var val = min(
				d[ i_pos - num_columns + j     ] + 1,        -- Cost of deletion
				d[ i_pos +               j - 1 ] + 1,        -- Cost of insertion
				d[ i_pos - num_columns + j - 1 ] + add_cost  -- Cost of substitution, it might not cost anything if it's the same
			)
			d[ i_pos + j ] = val
			
			-- is this eligible for tranposition?
				if i > 1 and j > 1 and s[ i ] == t[ j - 1 ] and s[ i - 1 ] == t[ j ] then
				d[ i_pos + j ] = min(
					val,                                                        -- Current cost
					d[ i_pos - num_columns - num_columns + j - 2 ] + add_cost   -- Cost of transposition
				)
			end
			
			if lim and val < best then
				best = val
			end
		end
		
		if lim and best >= lim then
			return lim
		end
	end
	
	return d[ #d ]
end

return edit_distance
