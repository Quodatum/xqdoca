xquery version "3.1";
(:~
 <p>namespace and qname utils</p>
 @copyright (c) 2019-2022 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
:)
module namespace xqn = 'quodatum:xqdoca.namespaces';

(:~  parse qname into parts
@param $e is from QName or TOKEN in some cases e.g "count"
@param $prefixes map of namespaces
@param $defaultns namespace for no prefix
@error xqn:qmap NO TOK
@return <pre>
 map{
    "uri": ..,
    "name": ..} 
 }
 :</pre>
 :)
declare 
function xqn:qmap($token as xs:string?, $prefixes as map(*), $defaultns as xs:string)
as map(*)
{
 let $_:=util:if(empty($token),error(xs:QName("xqn:qmap"),"NO TOK"))
 return if(starts-with($token,"Q{"))
        then map{
           "uri": $token=>substring-after("{")=>substring-before("}"),
           "name": $token=>substring-after("}") 
        }
        else
          let $n:=tokenize($token,":")
          let $prefix:=if(count($n)=2)then $n[1] else ()
          let $name:=if(count($n)=2)then  $n[2] else $n[1]
          let $uri:=if(empty($prefix)) 
                    then  $defaultns
                    else if( map:contains($prefixes,$prefix)) 
                        then $prefixes?($prefix)
                        else 
                          let $_:= trace(map:size($prefixes),"missing prefix:" || $prefix || ": ")
                          return error(xs:QName("xqn:qmap"),"Failed process token: " || $token)
                      
          return map{
                    "uri": $uri,
                    "name": $name} 
};

(:~ true if $uri and $name match $qmap :)
declare function xqn:eq($qmap as map(*),$uri as xs:string, $name as xs:string) 
as xs:boolean
{
  $qmap?name=$name and $qmap?uri=$uri
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

