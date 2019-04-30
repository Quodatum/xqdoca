(: xref :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:build.parser' at "../main/lib/xqdoc-parser.xqm";
declare variable $a:=fetch:text("C:\Users\andy\git\xqdoca\src\test\lib\tree-tests.xq");
let $xq:='"a;b"=>tokenize(";")'
let $xq:='db:system( (:hh:) )'
let $xq:='Q{http://www.w3.org/2005/xpath-functions}count(6)'
return xqp:parse($a)