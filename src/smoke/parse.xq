(: Parse XQuery file :)
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
declare variable $xquery:="../test/samples/sample.xqm";

$xquery
!fetch:text(resolve-uri(.))
!xqp:parse(.,"fat")