(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/xqdoc-parser.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");
declare variable $efolder2 as xs:anyURI  external := xs:anyURI("C:\Users\andy\git\vue-poc\src\vue-poc");

let $state:=xqd:read($efolder2)
let $x:= $state?files?xqdoc
return 
  $x//xqdoc:annotations/xqdoc:annotation 
