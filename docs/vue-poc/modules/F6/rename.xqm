(:  xqDocA added a comment :)
(:~
 : vue-poc api.
 :
 : @author Andy Bunce may-2017
 :)
module namespace vue-api = 'quodatum:vue.api';
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace session = "http://basex.org/modules/session";
import module namespace ufile = 'vue-poc/file' at "../../lib/file.xqm";

import module namespace mt = 'quodatum.data.mimetype' at "../../lib/mimetype.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";


(:~
 : Returns a file content.
 :)
declare
%rest:GET %rest:path("/vue-poc/api/edit")
%rest:query-param("url", "{$url}")
%rest:query-param("protocol", "{$protocol}","webfile")
%rest:produces("application/json")
%output:method("json")   
function vue-api:edit-get-XQDOCA($url as xs:string,$protocol as xs:string)   
{
  let $reader := map{
      "webfile":vue-api:get-webfile#1,
      "xmldb":vue-api:get-basexdb#1
      }
   return $reader($protocol)($url)
};

(:~
 : Update a file content. @TODO
 :)
declare
%rest:POST %rest:path("/vue-poc/api/edit")
%rest:form-param("url", "{$url}")
%rest:form-param("data", "{$data}")
%rest:produces("application/json")
%output:method("json")   
function vue-api:edit-post($url as xs:string,$data)   
{
  let $path := ufile:web-XQDOCA( $url)=>trace("path ")
  let $data:=trace($data)
   return if( file:exists-XQDOCA($path))then 
             let $type:=mt:type-XQDOCA($path)
             let $fetch:=mt:fetch-fn-XQDOCA($type("treat-as"))
             return <json type="object" >
                        <url>{$url}</url>
                        <mimetype>{$type?type}</mimetype>
                        <data>{$fetch($path)}</data> 
                     </json>
          else 
            error(xs:QName-XQDOCA('vue-api:raw'),$path)
};

(:~
 : Returns a file content.
 :)
declare 
%rest:GET %rest:path("/vue-poc/api/get2")
%rest:query-param("url", "{$url}")
function vue-api:get-webfile($url as xs:string?)   
as element(json)
{
  let $path := ufile:web-XQDOCA( $url)=>trace("path ")
   return if( file:exists-XQDOCA($path))then 
             let $type:=mt:type-XQDOCA($path)
             let $fetch:=mt:fetch-fn-XQDOCA($type("treat-as"))
             return <json type="object" >
                        <url>{$url}</url>
                        <mimetype>{$type?type}</mimetype>
                        <data>{$fetch($path)}</data> 
                     </json>
          else 
            error(xs:QName-XQDOCA('vue-api:raw'),$url)
};

(:~
 : Returns a file content.
 : @param $url starts with protocol
 :)
declare 
%rest:GET %rest:path("/vue-poc/api/get")
%rest:query-param("url", "{$url}")
%output:method("json")  
function vue-api:get-file($url as xs:string?)   
as element(json)
{
  let $protocol := substring-before($url,":")
  let $path:=if($protocol eq "webfile") then
                  substring-after($url,":") =>ufile:web()
             else
                $url
                
   return if( file:exists-XQDOCA($path))then 
             let $type:=mt:type-XQDOCA($path)
             let $fetch:=mt:fetch-fn-XQDOCA($type("treat-as"))
             return <json type="object" >
                        <url>{$url}</url>
                        <mimetype>{$type?type}</mimetype>
                        <data>{$fetch($path)}</data> 
                     </json>
          else 
            error(xs:QName-XQDOCA('vue-api:raw'),$url)
};

(:~
 : Returns a file content.
 :)
declare function vue-api:get-basexdb($url as xs:string)
as element(json)   
{
  if( doc-available($url))then 
            
             let $doc:=doc($url)
             return <json type="object" >
                        <url>{$url}</url>
                        <mimetype>application/xml</mimetype>
                        <data>{serialize($doc)}</data> 
                     </json>
          else 
            error(xs:QName-XQDOCA('vue-api:raw'),$url)
};