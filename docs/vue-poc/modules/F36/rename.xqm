(:  xqDocA added a comment :)
(:~
 : Generate html for for XQuery sources
 :)
module namespace vue-api = 'quodatum:vue.api';

import module namespace query-a = 'vue-poc/query-a' at "../../../lib/query-a.xqm";
import module namespace hlog = 'quodatum.data.history' at '../../../lib/history.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare variable $vue-api:query as xs:anyURI :=resolve-uri("tx-xqdoc.xq");


(:~
 : run xqdoc task.
 :)
declare
%rest:POST %rest:path("/vue-poc/api/tasks/xqdoc")
%rest:produces("application/json")
%output:method("json")
%updating 
function vue-api:model-XQDOCA()   
{
 let $params:=query-a:params-XQDOCA($vue-api:query)
 let $log:=<task task="xqdoc" url="url?">
              todo
            </task> 
 return (query-a:update-XQDOCA($vue-api:query,$params),
         hlog:save-XQDOCA($log)
         )
};
  
(:~
 : get xqdoc settings.
 :)
declare
%rest:GET %rest:path("/vue-poc/api/tasks/xqdoc")
%rest:produces("application/json")
%output:method("json")
function vue-api:settings()   
{
    let $xq:=resolve-uri($vue-api:query)
   return query-a:inspect-XQDOCA($xq)
};