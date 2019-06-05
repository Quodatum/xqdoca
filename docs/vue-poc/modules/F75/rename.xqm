(:  xqDocA added a comment :)
(:~
 : create vue-poc db
 :)
import module namespace dbtools = 'quodatum.dbtools'  at "../lib/dbtools.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare variable $target-db:="vue-poc";

declare variable $data-uri:=resolve-uri("../data/vue-poc/");
(dbtools:sync-from-files-XQDOCA(
                            $target-db
                           ,$data-uri
                           ,file:list-XQDOCA($data-uri,fn:true-XQDOCA())
                          ,hof:id#1))