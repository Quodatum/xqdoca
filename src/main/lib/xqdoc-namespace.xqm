xquery version "3.1";
(:
 : Copyright (c) 2019 Quodatum Ltd
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
 : @version 0.1
 :)
 

module namespace xqn = 'quodatum:xqdoca.namespaces';

(:~  parse qname into parts
 : @param $e is from QName or TOKEN in some cases e.g "count"
 : @param $lookup function e.g xqn:map-prefix(?,$xqp:ns-fn, xqp:prefixes($xqparse))
 : @return <pre>
 map{
    "uri": ..,
     "name": ..} 
 }
 :</pre>
 :)
declare function xqn:qname($e as xs:string, $lookup as function(xs:string) as xs:string)
as map(*)
{
 let $n:=tokenize($e,":")
let $prefix:=if(count($n)=1)then () else $n[1]
let $n2:=if(count($n)=1)then  $n[1] else $n[2]
return map{
           "uri": $lookup($prefix),
           "name": $n2} 
};

declare function xqn:eq($a as map(*),$uri as xs:string, $name as xs:string) 
as xs:boolean
{
  $a?name=$name and $a?uri=$uri
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
  else if(map:contains($map,$prefix))then 
   $map?($prefix)
   else
   "**ERROR" || $prefix
};

(:~  parse URIQualifiedName into parts
 : @param $e is URIQualifiedName
 :)
declare function xqn:uriqname($e as element(URIQualifiedName))
as map(*)
{
let $n:=tokenize($e,"}")
return map{"uri": substring($n[1],3),
           "name": $n[2]} 
};

(:~  map of static namespaces :)
declare function xqn:static-prefix-map()
as map(*)
{
 fetch:text(resolve-uri("../etc/static/basex.json",static-base-uri()))
 =>parse-json() 
};

(:~  expand annotation name :)
declare function xqn:qname-anno($e as xs:string,$prefixes as map(*))
as map(*)
{
let $lookup:=xqn:map-prefix(?,"http://www.w3.org/2012/xquery", $prefixes)
return xqn:qname($e , $lookup)
};
(:~  expand function name :)
declare function xqn:qname-fun($e as xs:string,$prefixes as map(*))
as map(*)
{
let $lookup:=xqn:map-prefix(?,"http://www.w3.org/2005/xpath-functions", $prefixes)
return xqn:qname($e , $lookup)
};