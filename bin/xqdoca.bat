@echo off
setLocal EnableDelayedExpansion
set MAIN=%~dp0\..

REM basex version to use, if BASEX_HOME define use that, else PATH search
IF DEFINED BASEX_HOME (
    set BASEX=%BASEX_HOME%\bin\basex.bat
) ELSE (
    set BASEX=basex.bat
)
echo using %BASEX%
%BASEX% -bargs="%*"  %MAIN%/src/main/xqdoca-cmd.xq