(: xref test :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:build.parser' at "../main/lib/xqdoc-parser.xqm";

let $xqparse:=doc("C:\Users\andy\basex.home\webapp\static\xqdoc\77\modules\F3\xqparse.xml")/*
   let $expand:=xqp:map-prefix(?,$xqp:ns-fn, xqp:prefixes($xqparse))
return  $xqparse//FunctionCall!xqp:funcall(.,$expand)