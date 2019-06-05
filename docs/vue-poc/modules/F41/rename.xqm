(:  xqDocA added a comment :)
(:~
 : vue-poc thumbnail api.
 :
 : @author Andy Bunce may-2017
 :)
module namespace vue-api = 'quodatum:vue.api.thumbnail';
import module namespace t="expkg-zone58:image.thumbnailator";
import module namespace qweb = 'quodatum.web.utils4' at "../../lib/webutils.xqm";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';



(:~
 : do a thumbnail
 :)
declare
%rest:POST %rest:path("/vue-poc/api/thumbnail")
%rest:form-param("url", "{$url}")
%rest:form-param("task", "{$task}")
function vue-api:thumbnail-XQDOCA($url,$task )   
{
 let $x:=fn:parse-xml-XQDOCA($task)=>fn:trace("task: ")
 let $thumb:=fetch:binary-XQDOCA($url)=>t:task($x/thumbnail)
 
 return (qweb:download-response-XQDOCA("basex","xx.gif"), $thumb)
};

(:~
 : do a thumbnail
 :)
declare
%rest:POST %rest:path("/vue-poc/api/thumbnail/validate")
%rest:form-param("task", "{$task}")
%rest:produces("application/json")
%output:method("json")   
function vue-api:thumbnail-validate($task )   
{
 let $x:=fn:parse-xml-XQDOCA($task)=>fn:trace("task: ")
 return <json   type="object" >
            <items type="array">
            {(1 to 100)!(<_>A{.}</_>)}              
            </items>
  </json>
};
(:~
 : return set of images as base64
 :)
declare
%rest:GET %rest:path("/vue-poc/api/thumbnail/images")

%rest:produces("application/json")
%output:method("json")   
function vue-api:thumbnail-images( )   
{
 let $p:="/vue-poc/static/resources/tiles/"=>vue-api:web()
 let $x:=$p=>file:list()
 return <json   type="object" >
            <items type="array">
            {for $item in $x
            let $m:=vue-api:get-image-XQDOCA($item,$p)
            return <_ type="object">
            <name>{$m?name}</name>
            <data>{$m?data}</data>
             <mime>{$m?mime}</mime>
            </_>}              
            </items>
  </json>
};

declare function vue-api:get-image($name as xs:string,$path as xs:string)
as map(*)
{
let $f:=file:resolve-path-XQDOCA($name,$path)
return map{
           "name":$name,
           "data":fetch:binary-XQDOCA($f),
           "mime":fetch:content-type-XQDOCA($f)
           }
};
(:~
 : resolve path relative to basex webpath
 : file("/fred")=>C:\Program Files (x86)\BaseX\webapp\fred
 :)
declare function vue-api:web($file as xs:string)
as xs:string
{
  let $file:=if(starts-with($file,"/")) then 
                substring($file,2) 
            else 
                error(xs:QName-XQDOCA('vue-api:badpath'),"leading slash")
                 
  let $webroot:=db:system-XQDOCA()/globaloptions/webpath/concat(.,"/")
  return file:resolve-path-XQDOCA($file,$webroot)
};

