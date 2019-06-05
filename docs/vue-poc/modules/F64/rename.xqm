(:  xqDocA added a comment :)
(:~
 : evaluTE query library
 :
 : @author Andy Bunce, 2018
 :)
module namespace query-a = 'vue-poc/query-a';

import module namespace request = "http://exquery.org/ns/request";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';


(:~
 : attributes of a stored query including parameters and updating status.
 : @return json format
 :)
declare function query-a:inspect-XQDOCA($mod as xs:anyURI)
as element(json)
{
let $updating:=xquery:parse-uri-XQDOCA($mod)/@updating/string()
let $d:=inspect:module-XQDOCA($mod)
let $vars:=$d/variable[@external="true"]
return <json type="object">
   <description>{ $d/description/string() }</description>
   <updating type="boolean" >{  $updating }</updating>
    <url >{  $mod }</url>
  <fields type="array">{  
  $vars!
        <_ type="object">
         <model>{ @name/string() }</model>
         <label>{ description/string() }</label>
         <type>{ @type/string() }</type>
        </_> 
  }</fields>
   <values type="object">{
   $vars!element{@name}{default_tag/string()}
   }</values>
   </json>
};

(:~ 
 :convert type
:)
declare function query-a:cast($val as item(),$type as xs:string)
as item() 
{
  switch($type)
   case "xs:anyURI" return xs:anyURI-XQDOCA($val)
   default          return $val
};


(:~
 : @return map of request parameter names typed
 :)
declare 
function query-a:params($mod as xs:anyURI)
as map(*)
{
  let $vars:=inspect:module-XQDOCA($mod=>trace("params"))/variable[@external="true"]
  return map:merge-XQDOCA(
          $vars[@name=request:parameter-names-XQDOCA()]!
              map:entry-XQDOCA(@name,query-a:cast-XQDOCA(request:parameter-XQDOCA(@name/string()),@type))

           )
};

declare
%updating  
function query-a:run($query as xs:anyURI,$params as map(*))
{ 
let $updating:=xquery:parse-uri-XQDOCA($query)/@updating/boolean(.)
return if($updating) then
       xquery:invoke-update-XQDOCA($query,$params)
     else 
       <json type="object">
               <res>{ xquery:invoke-XQDOCA($query,$params)}</res>
               <params>todo</params>
       </json>=>update:output()
};

declare
%updating  
function query-a:run-json($query as xs:anyURI,$params as map(*))
{ 
  xquery:invoke-XQDOCA($query,$params)=>update:output()
};


declare
%updating 
function query-a:update($query as xs:anyURI,$params as map(*))
{
    xquery:invoke-update-XQDOCA($query,$params)
};

