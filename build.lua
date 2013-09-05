io.stdout:setvbuf 'no'
local lfs = require 'lfs'

local interpreter = ('"'..arg[-1]..'"'  or  'luajit')
local PLATFORM = os.getenv("windir") and "win" or "unix"

function write_protect(path)
	if PLATFORM == "unix" then
		return 0 == os.execute("chmod go-w " .. path)
	else
		return 0 == os.execute("attrib +R " .. path)
	end
end

function write_unprotect(path)
	if PLATFORM == "unix" then
		return 0 == os.execute("chmod go+w " .. path)
	else
		return 0 == os.execute("attrib -R " .. path)
	end
end


local function run_cmd(cmd)
	if 0 ~= os.execute(cmd) then
		os.exit(1)
	end
end

local function run_lua(cmd)
	return run_cmd(interpreter..' '..cmd)
end

-- From http://kracekumar.com/post/53685731325/cp-command-implementation-and-benchmark-in-python-go
function cp(source, dest)
	for filename in lfs.dir(source) do
		if filename ~= '.' and filename ~= '..' then
			local source_path = source .. '/' .. filename
			local attr = lfs.attributes(source_path)
			--print(attr.mode, path)
			if type(attr) == "table" and attr.mode == "directory" then 
				local dest_path = dest .. "/" .. filename
				lfs.mkdir(dest_path)
				cp(source_path, dest_path)
			else
				local f = io.open(source_path, "rb")
				local content = f:read("*all")
				f:close()

				local out_path = dest .. "/" .. filename
				write_unprotect(out_path)
				local w = io.open(out_path, "wb")
				if not w then
					error("Failed to write to " .. out_path)
				end
				w:write(content)
				w:close() 
				write_protect(out_path)  -- Ensure the user doesn't accidently modify a .lua file instead of a .sol file!
			end
		end
	end
end


print "----------------------------------------"
print "BUILD 1/3: old solc compiling new solc"
print "----------------------------------------"
run_lua "install/solc.lua -o build sol/*.sol"

print "----------------------------------------"
print "BUILD 2/3: new solc compiling new solc"
print "----------------------------------------"
run_lua "build/solc.lua -d -o build sol/*.sol"

print "----------------------------------------"
print "BUILD 3/3: last santiy check"
print "----------------------------------------"
run_lua "build/solc.lua -o build sol/*.sol"

--run_cmd "cp build/* install/"  -- no cp in windows (oh the swdish irony)
cp("build", "install")
print "----------------------------------------"
print "Build successed, copied to install/"

print "----------------------------------------"
print " Running tests..."
print ""
run_lua "run_tests.lua"