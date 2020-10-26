xquery version "3.1";
(:
 : Copyright (c) 2019-2020 Quodatum Ltd
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)
 
 (:~
 : <h1>xqdoc-namespaces.xqm</h1>
 : <p>namespace and qname utils</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 

module namespace xqn = 'quodatum:xqdoca.namespaces';

(:~  parse qname into parts
 : @param $e is from QName or TOKEN in some cases e.g "count"
 : @param $prefixes map of namespaces
 : @param $default namespace for no prefix
 : @return <pre>
 map{
    "uri": ..,
     "name": ..} 
 }
 :</pre>
 :)
declare 
function xqn:qmap($e as xs:string, $prefixes as map(*), $default as xs:string)
as map(*)
{
 let $n:=tokenize($e,":")
let $prefix:=if(count($n)=1)then () else $n[1]
let $name:=if(count($n)=1)then  $n[1] else $n[2]
let $uri:=if(empty($prefix)) then
              $default
          else if( map:contains($prefixes,$prefix)) then
              $prefixes?($prefix)
          else 
               let $_:= trace($e,"e: ")
                 let $_:= trace($default,"default: ")
                   let $_:= trace($prefixes,"ERROR qmap: ")
               return error()
return map{
           "uri": $uri,
           "name": $name} 
};

declare function xqn:eq($a as map(*),$uri as xs:string, $name as xs:string) 
as xs:boolean
{
  $a?name=$name and $a?uri=$uri
};


(:~ 
 : return clark-notation '{uri}name'
  :)
declare function xqn:clark-name($uri as xs:string, 
                                $name as xs:string)
as xs:string
{
  ``[{`{ $uri }`}`{ $name }`]``
};

(:~ 
 : @return prefix:name if available or clark-notation
  :)
declare function xqn:prefixed-name($uri as xs:string, 
                                $name as xs:string,
                                $prefixes as map(*))
as xs:string
{
  let $prefix:= map:for-each($prefixes,function($k,$v){ if($v=$uri)then $k else () })=>head() 
  return if($prefix) then
           concat(head($prefix),":",$name)
         else
           xqn:clark-name( $uri, $name )
};

(:~ namespace for prefix
 : @param $prefix prefix to lookup
 : @param $default namespace to use if prefix empty
 : @param $map keys are prefixes items are namespaces
 : @return namespace for prefix
  :)
declare function xqn:map-prefix($prefix as xs:string?, $default as xs:string, $map as map(*))
as xs:string{
  if(empty($prefix)) then
    $default
  else if(map:contains($map, $prefix))then 
   $map?($prefix)
   else
   let $_:=trace($map,"prefixes")
   return "*** " || trace($prefix,"**prefix not found:" ),
   error()
};

(:~  parse URIQualifiedName into parts
 : @param $e is URIQualifiedName
 : @todo use regx
 :)
declare function xqn:uriqname($e as element(URIQualifiedName))
as map(*)
{
let $n:=tokenize($e,"}")
return map{"uri": substring($n[1],3),
           "name": $n[2]} 
};

(:~  map of static namespaces :)
declare function xqn:static-prefix-map($platform as xs:string)
as map(*)
{
 fetch:text(resolve-uri(``[../etc/models/`{ $platform }`.json]``,static-base-uri()))
 =>parse-json() 
};

