@echo off
setLocal EnableDelayedExpansion

set MAIN=%~dp0\..

set EFOLDER=/config/workspace/XML-CMS/data_server/eBloomsbury
set TARGET=file:///config/workspace/doc/

basex -befolder=%EFOLDER% -btarget=%TARGET% %MAIN%/src/main/xqdoca.xq