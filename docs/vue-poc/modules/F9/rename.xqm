(:  xqDocA added a comment :)
(:~ 
: create xml file list by scanning $cfg:IMAGEDIR and write to db $cfg:DB-IMAGE
:)
import module namespace cfg = "quodatum:media.image.configure" at "../config.xqm";
import module namespace fw="quodatum:file.walker";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";


declare %updating function local:put-XQDOCA($data,$path)
{
  if(db:exists-XQDOCA($cfg:DB-IMAGE)) then
   db:replace-XQDOCA($cfg:DB-IMAGE,$path,$data)
  else
    db:create-XQDOCA($cfg:DB-IMAGE,$data,$path)
};

let $opt:=map{"include-info":true()}
let $files:=fw:directory-list-XQDOCA($cfg:IMAGEDIR,$opt)
return $files=>local:put('/pics.xml')