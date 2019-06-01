(: xref :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
declare variable $a:=fetch:text("C:\Users\andy\git\vue-poc\src\vue-poc\lib\entity-gen.xqm");
let $xq:='"a;b"=>tokenize(";")'
let $xq:='db:system( (:hh:) )'
let $xq:='count(5+5)'
return xqp:parse($a,"basex")//FunctionDecl/*[2]