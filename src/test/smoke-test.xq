(: xref test :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:build.parser' at "../main/lib/xqdoc-parser.xqm";
declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");


let $state:=xqd:read($efolder)
let $x:= $state?files[2]?xqparse 
return $x//FunctionDecl!xqp:invoked(.)
