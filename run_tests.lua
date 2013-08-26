#!
local lfs  = require 'lfs'
local path = require 'pl.path'

local rel_path  = path.dirname(arg[0])
local sol_dir = lfs.currentdir() .. '/'
if rel_path ~= "" then
	sol_dir = sol_dir .. rel_path .. '/'
end

-------------------------------------------



local DIVISION = '\n--------------------------\n'

local failed_to_pass = 0
local failed_to_fail = 0
local numTested      = 0

--print('arg[0] == ' .. arg[0])    -- ../run_tests.lua
--print('arg[-1] == ' .. arg[-1])  -- lua  or  luajit
local interpreter = (arg[-1]  or  'luajit') .. ' ' .. sol_dir .. 'install/solc.lua '

local spam = (arg[1] == '-s')


local function test_dir(dir)
	for file in lfs.dir(dir) do
		if path.extension(file) == '.sol' then
			numTested = numTested + 1

			--print('Testing: ' .. file .. '...')
			local shouldPass = true
			if file:find('FAIL') then
				shouldPass = false
			end

			--lfs.chdir(sol_dir .. 'install/')
			local file_path = dir .. '/' .. file
			local result = os.execute( interpreter .. ' -o tests_built ' .. file_path .. ' &> /dev/null' )

			if shouldPass and result ~= 0 then
				failed_to_pass = failed_to_pass + 1
				print("Test should have passed but didn't: " .. file)
				print(DIVISION)
				os.execute( interpreter .. ' -d -o tests_built ' .. file_path ) -- Standard
				print(DIVISION)
				if spam then
					os.execute( interpreter .. ' -d -o tests_built -s ' .. dir .. '/' .. file ) -- Extra spam
					print(DIVISION)
				end
			end

			if not shouldPass and result == 0 then
				failed_to_fail = failed_to_fail + 1
				print("Test should have failed but passed: " .. file)
				print(DIVISION)
				if spam then
					os.execute( interpreter .. ' -p -s ' .. dir .. '/' .. file ) -- Extra spam
					print(DIVISION)
				end
			end

			--print(DIVISION)
		end
	end
end

--print(DIVISION)
test_dir(sol_dir .. 'tests')

local numBad = failed_to_pass + failed_to_fail

if numBad == 0 then
	print('All ' .. numTested .. ' tests passed')
	os.exit(0)
else
	print('ERROR: ' .. numBad .. ' / ' .. numTested .. ' tests failed')
	os.exit(-1)
end
