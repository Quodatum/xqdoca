(: xref test :)
import module namespace xqd = 'quodatum:xqdoca.model' at "../main/lib/model.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare  namespace dotml = 'http://www.martin-loetzsch.de/DOTML';

declare variable $xqdoca as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");
declare variable $efolder2 as xs:anyURI  external := xs:anyURI("C:\Users\andy\git\vue-poc\src\vue-poc\features\form");
declare variable $chat as xs:anyURI  external := xs:anyURI("C:\Users\andy\basex.home\webapp\chat");
declare variable $dba as xs:anyURI  external := xs:anyURI("C:\Users\andy\basex.home\webapp\dba");
declare variable $efolder as xs:anyURI := $dba;

declare function local:node($f as map(*)){
  <dotml:node id="{ $f?index}" label="{ $f?namespace } | { $f?path }"/>
};

declare function local:edge($from as map(*),$to as map(*)){
  <dotml:edge from="{ $from?index}"  to="{ $to?index}"/>
};
  
let $files:=xqd:find-sources($efolder,"*.xqm,*.xq,*.xquery")
let $model:= xqd:snap($efolder,$files,"basex") 
(: return sequence of maps    imported-ns:(files that import...)   :)
let $imports:= xqd:imports($model)
let $defs:=xqd:defs($model)
for $f in  $model?files[map:contains($imports,?namespace) or ?xqdoc//xqdoc:import[@type="library"]] 
let $ins:=$f?xqdoc//xqdoc:import[@type="library"]/xqdoc:uri/string()[map:contains($defs,.)]
let $n:= local:node($f)
let $e:=$ins! $defs(.)!local:edge(.,$f)
return ($n,$e)