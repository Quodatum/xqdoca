REM all teacup docs
set DEST=file:///tmp/teacup/
call xqdoca C:\Users\andy\git\bloomsbury\XML-CMS\data_server\ %DEST%data_server/
call xqdoca C:\Users\andy\git\bloomsbury\XML-CMS\data_server\eBloomsbury\test\ %DEST%tests/

call xqdoca C:\Users\andy\git\bloomsbury\XML-CMS\process_server\ %DEST%process_server/