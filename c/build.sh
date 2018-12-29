export GLOBALS_HOME=/InterSystems/IRIS2018
gcc -O2 -shared -fPIC -I${GLOBALS_HOME}/dev/cpp/include zlibisc.c -lz -o zlibisc.so
cp zlibisc.so ${GLOBALS_HOME}/bin