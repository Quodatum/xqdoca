@echo off
setLocal EnableDelayedExpansion

set MAIN=%~dp0\..
REM basex version to use, set as required, empty for 1st on path
set BASEX_BIN=C:\Users\andy\basex.home\basex.951\bin\
%BASEX_BIN%basex -bargs="%*"  %MAIN%/src/main/xqdoca-cmd.xq