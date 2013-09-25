-- Allow user to pass in things like -s (spam) and -d (debug), -e0  (force build)
local solc_args = ''
for _,a in ipairs(arg) do
	solc_args = solc_args .. ' ' .. a
end

local interpreter = ('"'..arg[-1]..'"'  or  'luajit')

os.execute(interpreter .. " install/solc.lua --profile "..solc_args.." -o build sol/*.sol")
