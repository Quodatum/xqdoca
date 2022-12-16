(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqdoca as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");
declare variable $efolder2 as xs:anyURI  external := xs:anyURI("C:\Users\andy\git\vue-poc\src\vue-poc\features\form");
declare variable $chat as xs:anyURI  external := xs:anyURI("C:\Users\andy\basex.home\webapp\chat");
declare variable $dba as xs:anyURI  external := xs:anyURI("C:\Users\andy\basex.home\webapp\dba");
declare variable $efolder as xs:anyURI := $dba;

let $files:=xqd:find-sources($efolder,"*.xqm,*.xq,*.xquery")
let $model:= xqd:snap($efolder,$files,"basex") 
for $file in $model?files
return map{"path": $file?path,
           "prefixes": $file?prefixes,
           "href": $file?href }
