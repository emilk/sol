cd /Users/emilk/Sol

echo "----------------------------------------"    && \
echo "BUILD 1/3: old solc compiling new solc"      && \
echo "----------------------------------------"    && \
luajit install/solc.lua -o build sol/*.sol         && \

echo "----------------------------------------"    && \
echo "BUILD 2/3: new solc compiling new solc"      && \
echo "----------------------------------------"    && \
luajit build/solc.lua -d -o build sol/*.sol           && \

echo "----------------------------------------"    && \
echo "BUILD 3/3: last santiy check"                && \
echo "----------------------------------------"    && \
luajit build/solc.lua -d -o build sol/*.sol           && \

cp build/* install/                                && \
echo "----------------------------------------"    && \
echo "Build successed, copied to install/"
