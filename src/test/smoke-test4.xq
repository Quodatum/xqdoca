(: xref test :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:build.parser' at "../main/lib/xqdoc-parser.xqm";

let $d:="C:\Users\andy\git\xqdoca\src\main\etc\xquery.lib\static-basex.json"
return parse-json(fetch:text($d))