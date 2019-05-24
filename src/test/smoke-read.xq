(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");
declare variable $efolder2 as xs:anyURI  external := xs:anyURI("C:\Users\andy\git\vue-poc\src\vue-poc\features\form");
declare variable $chat as xs:anyURI  external := xs:anyURI("C:\Users\andy\basex.home\webapp\chat");

let $files:=xqd:find-sources($efolder,"*.xqm,*.xq,*.xquery")
let $model:= xqd:snap($efolder,$files,"basex") 
return $model?files?xqdoc/xqdoc:imports/xqdoc:import
