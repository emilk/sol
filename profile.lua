local interpreter = ('"'..arg[-1]..'"'  or  'luajit')
os.execute(interpreter .. " install/solc.lua --profile -o build sol/*.sol")
