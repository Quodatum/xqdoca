(: xref :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:build.parser' at "../main/lib/xqdoc-parser.xqm";

let $xq:='"a;b"=>tokenize(";")'
let $xq:='db:system( (:hh:) )'
return xqp:parse($xq)