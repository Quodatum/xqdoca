(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "../main/lib/xqdoc-namespace.xqm";

let $xqparse:=doc("C:\Users\andy\basex.home\webapp\static\xqdoc\main\modules\F1\xqparse.xml")/*
let $def-fn:= xqp:default-fn-uri($xqparse)
let $prefixes:= xqp:prefixes($xqparse,"basex")
return  $xqparse//FunctionCall!xqp:invoke-fn(.,$prefixes,$def-fn)