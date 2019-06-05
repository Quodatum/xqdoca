(:  xqDocA added a comment :)
import module namespace store = 'quodatum.store' at "store.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
let $d:=<doc>test</doc>
let $r:=map{"uri":"foo/test.xml","serialization":map{},"document":$d}
let $base:="xmldb:/vuepoc-test/123/"
(: let $base:=file:path-to-uri("c:\tmp\") :)
return store:store-XQDOCA($r,$base)
  
