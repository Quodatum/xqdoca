@echo off
setLocal EnableDelayedExpansion

set MAIN=%~dp0\..
if [%1]==[] goto usage
REM source 
set EFOLDER=%1
REM target must use file:///
set TARGET=%2

basex -befolder=%EFOLDER% -btarget=%TARGET% %MAIN%/src/main/xqdoca.xq
goto :eof

:usage
@echo Usage: %0 efolder target
exit /B 1