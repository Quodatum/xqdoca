(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/xqdoc-parser.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "../main/lib/xqdoc-namespace.xqm";
let $xqparse:=doc("C:\Users\andy\basex.home\webapp\static\xqdoc\77\modules\F3\xqparse.xml")/*
   let $expand:=xqn:map-prefix(?,$xqp:ns-fn, xqp:prefixes($xqparse))
return  $xqparse//FunctionCall!xqp:funcall(.,$expand)