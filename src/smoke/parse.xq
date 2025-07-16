(: Parse XQuery file :)
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
declare variable $xquery:="C:\Users\mrwhe\git\quodatum\xqdoca\src\test\samples\Pdfbox3.xqm";

$xquery
!unparsed-text(resolve-uri(.))
!xqp:parse(.,"fat")