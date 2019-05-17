(: xref :)
import module namespace xqd = 'quodatum:xqdoca.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/xqdoc-parser.xqm";
declare variable $a:=fetch:text("C:\Users\andy\basex.home\webapp\chat\chat-ws.xqm");
let $xq:='"a;b"=>tokenize(";")'
let $xq:='db:system( (:hh:) )'
let $xq:='count(6)'
return xqp:parse($a)