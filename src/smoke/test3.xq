(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "../main/lib/xqdoc-namespace.xqm";
declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");

let $files:=xqd:find-sources($efolder,"*.xqm,*.xq,*.xquery")
let $state:=xqd:snap($efolder, $files, "basex")
let $f:= $state?files[2]
  let $ns:=$f?namespaces
return $f?xparse//QName!xqn:qmap(.,$ns,$f?default-fn-uri)
