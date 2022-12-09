(: xqdoc generation test :)
import module namespace xqdc = 'quodatum:xqdoca.model.xqdoc' at "../main/lib/ast-to-xqdoc.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
declare variable $xquery:="../test/samples/sample.xqm";

"../main/lib/xqdoc-namespace.xqm"
!fetch:text(resolve-uri(.))
!xqp:parse(.,"basex")
!xqdc:create(.)
(: /Module :)