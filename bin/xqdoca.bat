@echo off
setLocal EnableDelayedExpansion
set MAIN=%~dp0\..
REM @see https://stackoverflow.com/questions/41265266/how-to-solve-inaccessibleobjectexception-unable-to-make-member-accessible-m#41265267
set BASEX_JVM=--add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/jdk.internal.loader=ALL-UNNAMED

REM basex version to use, if BASEX_HOME define use that, else PATH search
IF DEFINED BASEX10 (
    set BASEX=%BASEX10%\bin\basex.bat
) ELSE (
    set BASEX=basex.bat
)
echo using %BASEX%
%BASEX% -bargs="%*"  %MAIN%/src/main/xqdoca-cmd.xq