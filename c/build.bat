set WINBUILDS_HOME=C:\WinBuilds
set GLOBALS_HOME=C:\InterSystems\Ensemble
set PATH=%WINBUILDS_HOME%\bin;%PATH%

gcc -O2 -shared -I%GLOBALS_HOME%\dev\cpp\include zlibisc.c -lz -o zlibisc.dll
cp zlibisc.dll %GLOBALS_HOME%\bin
cp %WINBUILDS_HOME%\bin\libz-1.dll %GLOBALS_HOME%\bin

"C:\WINDOWS\system32\cmd.exe"