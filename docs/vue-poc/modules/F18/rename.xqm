(:  xqDocA added a comment :)
 (:~
 : vue-poc thumbnail api.
 :
 : @author Andy Bunce may-2017
 :)
module namespace vue-api = 'quodatum:vue.api.images';
import module namespace cfg = "quodatum:media.image.configure" at "config.xqm";
import module namespace fw="quodatum:file.walker";
import module namespace entity = 'quodatum.models.generated' at "../../models.gen.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";

declare variable $vue-api:entity:=$entity:list("thumbnail");
(:~
 : do a thumbnail
 :)
declare
%rest:GET %rest:path("/vue-poc/api/images/list/{$id}")
%rest:produces("application/json")
%output:method("json")   
function vue-api:id-XQDOCA( $id as xs:integer)   
{
 let $image:=db:open-id-XQDOCA($cfg:DB-IMAGE,$id)
 return <json type="object" >
    <doc>{ serialize($image) }</doc>
     { vue-api:get-image-XQDOCA($image) }
  </json>
};

(:~
 : generate html report
 :)
declare
%rest:GET %rest:path("/vue-poc/api/images/report")
%rest:produces("application/json")
%output:method("json")
function vue-api:report()   
{
<json type="object" >
  <imagedir>{ $cfg:IMAGEDIR }</imagedir>
  <thumbdir>{ $cfg:THUMBDIR }</thumbdir>
  <imagedb>{ $cfg:DB-IMAGE }</imagedb>
</json>
};

(:~
 : get set of thumbnails matching search
 :)
declare
%rest:single
%rest:GET %rest:path("/vue-poc/api/images/list")
%rest:produces("application/json")
%rest:query-param("page", "{$page}",0)
%rest:query-param("from", "{$from}")
%rest:query-param("until", "{$until}")
%rest:query-param("keyword", "{$keyword}")
%output:method("json")   
function vue-api:list( $page as xs:integer,
$from,$until,
$keyword
)   
{
 let $rowsPerPage:=24
 let $images:=$vue-api:entity("data")()
 let $images:=$images[not(@original)]
 let $images:=if($from)then  $images[datetaken ge $from] else $images
 let $images:=if($until)then  $images[datetaken le $until] else $images
 let $images:=if($keyword)then  $images[keywords/keyword = $keyword] else $images
 let $total:=count($images)
 let $images:=subsequence($images,1+$rowsPerPage*$page,$rowsPerPage)
 
 return <json   type="object" >
            <total type="number">{ $total }</total>
            <items type="array">{
            for $f in $images
            return <_ type="object">
            {vue-api:get-image-XQDOCA($f)} 
            </_>
            }</items>
  </json>
};



(:~
 : keywords
 :)
declare
%rest:GET %rest:path("/vue-poc/api/images/keywords2")
%rest:produces("application/json")
%output:method("json")   
function vue-api:keywords2()   
{
let $keys:=db:open-XQDOCA($cfg:DB-IMAGE,"keywords.xml")/keywords/keyword

return <json   type="object" >
            <items type="array">{
            $keys!<_ type="object">
               <text>{@name/string()}</text>
               <count>{@count/string()}</count>
               </_>
            }</items>
  </json>
};

(:~
 : keywords
 :)
declare
%rest:GET %rest:path("/vue-poc/api/images/datetaken")
%rest:produces("application/json")
%output:method("json")   
function vue-api:datetaken()   
{
let $years:=db:open-XQDOCA($cfg:DB-IMAGE,"datetaken.xml")/dates/year

return <json   type="object" >
            <items type="array">{
            for $year in $years
            return <_ type="object">
               <year>{$year/@value/string()}</year>
               <count type="number">{$year/@count/string()}</count>
               <months type="array">{
               for $m in 1 to 12
               let $c:= $year/month[@value=format-integer($m,"00")]/@count
               return <_ type="number">{if($c)then string($c) else 0}</_>
               }</months>
               </_>
            }</items>
  </json>
};

(:~ full size image :)
declare 
%rest:GET %rest:path("/vue-poc/api/images/list/{ $id }/image")
function vue-api:rawimage($id as xs:integer)
{
  let $image as element(image):=db:open-id-XQDOCA($cfg:DB-IMAGE,$id)
  let $path:=$cfg:IMAGEDIR || '../' || $vue-api:entity?access?path($image)
  return (
    web:response-header-XQDOCA(map { 'media-type': web:content-type-XQDOCA($path) }),
    file:read-binary-XQDOCA($path)
  )
};

(:~ thumb size image :)
declare 
%rest:GET %rest:path("/vue-poc/api/images/list/{ $id }/thumb")
function vue-api:rawthumb($id as xs:integer)
{
  let $image as element(image):=db:open-id-XQDOCA($cfg:DB-IMAGE,$id)
 let $thumb:= $cfg:THUMBDIR || $vue-api:entity?access?path($image)
 let $thumb:=if(file:exists-XQDOCA($thumb)) then $thumb else resolve-uri("missing.jpg")
  return (
    web:response-header-XQDOCA(map { 'media-type': web:content-type-XQDOCA($thumb) }),
    fetch:binary-XQDOCA($thumb)
  )
};

(:~ image metadata :)
declare 
%rest:GET %rest:path("/vue-poc/api/images/list/{ $id }/meta")
function vue-api:meta($id as xs:integer)
{
  let $image as element(image):=db:open-id-XQDOCA($cfg:DB-IMAGE,$id)
  let $path:=$cfg:DB-IMAGE || "/meta/"  || $vue-api:entity?access?path($image) || "/meta.xml"
  return doc($path)
};

(:~ fields for thumbnail for json :)
declare function vue-api:get-image($image as element(image))
as element(*)*
{
let $id:=$vue-api:entity?access?id($image)
let $path:=$vue-api:entity?access?path($image)
let $name:=$vue-api:entity?access?name($image)
let $geo:=$vue-api:entity?json?geo($image)
let $keywords:=$vue-api:entity?json?keywords($image)
let $thumb:= $cfg:THUMBDIR ||  $path
let $thumb:=if(file:exists-XQDOCA($thumb)) then $thumb else resolve-uri("missing.jpg")
return   (
          <id>{$id}</id>
         ,<name>{$name}</name>
         ,<path>{$path}</path>
         ,$geo,$keywords
         ,<data>{fetch:binary-XQDOCA($thumb)}</data>
         ,<mime>{fetch:content-type-XQDOCA($thumb)}</mime>
         ,<selected type="boolean">false</selected>
         )
};



