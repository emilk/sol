cd /Users/emilk/Sol

echo "----------------------------------------"    && \
echo "BUILD 1/3: old solc compiling new solc"      && \
echo "----------------------------------------"    && \
luajit install/solc.lua -e0 -o build sol/*.sol         && \

echo "----------------------------------------"    && \
echo "BUILD 2/3: new solc compiling new solc"      && \
echo "----------------------------------------"    && \
luajit build/solc.lua -e0 -o build sol/*.sol           && \

echo "----------------------------------------"    && \
echo "BUILD 3/3: last santiy check"                && \
echo "----------------------------------------"    && \
luajit build/solc.lua -e0 -o build sol/*.sol           && \

echo "----------------------------------------"    && \
echo "Build successed, COPY MANUALLY to install with:  cp build/* install/"
