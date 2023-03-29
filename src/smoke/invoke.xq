(: xref test :)
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";

let $xqparse:=doc("C:\Users\andy\basex.home\webapp\static\xqdoc\main\modules\F1\xqparse.xml")/*
let $def-fn:= xqp:default-fn-uri($xqparse)
let $prefixes:= xqp:namespaces($xqparse,"basex")
return  $xqparse//FunctionCall!xqp:invoke-fn(.,$prefixes,$def-fn)