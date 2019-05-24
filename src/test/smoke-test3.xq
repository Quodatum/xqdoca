(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/parser.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "../main/lib/xqdoc-namespace.xqm";
declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");


let $state:=xqd:snap($efolder,"basex")
let $x:= $state?files[2]?xqparse 
  let $expand:=xqn:map-prefix(?,$xqp:ns-fn, xqp:prefixes($x))
return $x//QName!xqn:qname(.,$expand)
