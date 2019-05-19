(: xref :)
import module namespace xqd = 'quodatum:xqdoca.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/xqdoc-parser.xqm";
declare variable $a:=fetch:text("C:\Users\andy\basex.home\webapp\vue-poc\features\form\forms.xqm");
let $xq:='"a;b"=>tokenize(";")'
let $xq:='db:system( (:hh:) )'
let $xq:='count(5+5)'
return xqp:parse($xq)