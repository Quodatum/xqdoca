import module namespace store = 'quodatum:xqdoca:store' at "../../main/lib/store.xqm";
let $d:=<doc>test</doc>
let $r:=map{"uri":"foo/test.xml","serialization":map{},"document":$d}
let $base:="xmldb:/vuepoc-test/123/"
(: let $base:=file:path-to-uri("c:\tmp\") :)
return store:store($r,$base)
  
