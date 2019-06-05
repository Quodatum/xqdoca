(:  xqDocA added a comment :)
(:~
 : Update `generated/models.xqm` from files in `data/models`
 : using file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models
 : $efolder:="file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models"
 : $target:="file:///C:/Users/andy/workspace/app-doc/src/doc/generated/models.xqm"
 :)
module namespace vue-api = 'quodatum:vue.api';

import module namespace bf = 'quodatum.tools.buildfields' at "./../../../lib/entity-gen.xqm";
import module namespace query-a = 'vue-poc/query-a' at "../../../lib/query-a.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare variable $vue-api:query:="tx-model.xq";
(:~
 : Returns a file content.
 :)
declare
%rest:POST %rest:path("/vue-poc/api/tasks/model")
%rest:produces("application/json")
%output:method("json")
%updating   
function vue-api:model-XQDOCA( )   
{
    let $u:=resolve-uri($vue-api:query)
    return query-a:update-XQDOCA($u,query-a:params-XQDOCA($u))
};
          
(:~
 : model settings.
 :)
declare
%rest:GET %rest:path("/vue-poc/api/tasks/model")
%rest:produces("application/json")
%output:method("json")
function vue-api:settings()   
{
    let $xq:=resolve-uri($vue-api:query)
   return query-a:inspect-XQDOCA($xq)
};