(:  xqDocA added a comment :)
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
 : <h1>xqdoc-proj.xqm</h1>
 : <p>annotation utils</p>
 : 
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace xqa = 'quodatum:xqdoca.model.annotations';


import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "xqdoc-page.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqa:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqa:nsANN:='http://www.w3.org/2012/xquery';
declare variable $xqa:nsOUT:='http://www.w3.org/2010/xslt-xquery-serialization';

(:~ 
 : @see https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods 
 :)
declare variable $xqa:methods:=("GET","HEAD","POST","PUT","DELETE","PATCH");

(:~  known annotation details :)
declare variable $xqa:noteworthy:=(
  map{
    "uri":'http://www.w3.org/2012/xquery',
    "name":'updating',
    "title":'Updating',
    'icon': 'U',
    "class": 'danger'
  },
    map{
    "uri":'http://www.w3.org/2012/xquery',
    "name":'private',
    "title":'Private',
    'icon': 'P',
    "class": 'dark'
  },
   map{
    "uri":'http://exquery.org/ns/restxq',
    "name":'path',
    "title":'RESTXQ',
    "icon": 'R',
    "class": 'success'
  }
);

(:~
 : html badges for annotations with known namespaces 
 :)
declare function xqa:badges-XQDOCA($annos as element(xqdoc:annotation)*, $file as map(*))
{
  let $prefixes:=$file?prefixes
  let $others:=some $a in $annos satisfies let $m:=xqn:qmap-XQDOCA($a/@name,$prefixes,$xqa:nsANN)
                                               return not($m?uri = $xqa:noteworthy?uri)
  return (
    for $badge in $xqa:noteworthy
    where   some $a in $annos satisfies xqn:eq-XQDOCA(xqn:qmap-XQDOCA($a/@name,$prefixes,$xqa:nsANN), $badge?uri, $badge?name)
    return  page:badge-XQDOCA($badge?icon, $badge?class, $badge?title)
    
    ,if($others) then page:badge-XQDOCA("A", "info", "Other annotations") else ()
    )
};

(:~  true if rest:name :)
declare function xqa:is-rest($name,$a  as element(xqdoc:annotation),$ns as map(*))
as xs:boolean
{
  xqn:eq-XQDOCA(xqn:qmap-XQDOCA($a/@name,$ns,$xqa:nsANN), $xqa:nsRESTXQ,$name)
};

declare function xqa:is-out($name,$a  as element(xqdoc:annotation),$ns as map(*))
as xs:boolean
{
  xqn:eq-XQDOCA(xqn:qmap-XQDOCA($a/@name,$ns,$xqa:nsANN), $xqa:nsOUT,$name)
};


declare function xqa:only-rest($annots  as element(xqdoc:annotation)*,$ns as map(*))
as xs:boolean
{
  $annots=>filter(xqa:is-rest-XQDOCA("path",?,$ns))
};

declare function xqa:methods($annots  as element(xqdoc:annotation)*,$ns as map(*))
as xs:string*
{
 filter($xqa:methods,function($m){
   some $a in $annots 
   satisfies  xqn:eq-XQDOCA(xqn:qmap-XQDOCA($a/@name,$ns,$xqa:nsANN), $xqa:nsRESTXQ,$m)
 })
};    

(:~  info about function or variable :)
declare function xqa:name-detail($e as element(*),$file as map(*))
as map(*)
{
  let $name:=$e/xqdoc:name
       let $qmap:=xqn:qmap-XQDOCA($name, $file?prefixes, $file?default-fn-uri)
       let $lname:=if($e instance of element(xqdoc:function)) then
                     concat($qmap?name,"#",$e/@arity)
                   else
                    concat("$",$qmap?name)
       return map{"given": $name/string(), 
                  "uri": $qmap?uri, 
                  "name": $lname, 
                  "xqdoc": $e }
};

(:~ annotations grouped by uri with added file reference 
 : <pre>map{uri:map{
 :           "annotation":{"name:,"uri":}, "xqdoc": <xqdoc:annotation/>, "file":}
 :           }*
 : </pre>
 :)
declare function xqa:annotations($model as map(*))
as map(*)
{ 
  map:merge-XQDOCA(
          for $f in $model?files, $a in $f?annotations
          group by $uri:=$a?annotation?uri
           return map:entry-XQDOCA($uri,for-each-pair($a,$f,
                   function($a,$f){map:merge-XQDOCA(($a,map:entry-XQDOCA("file", $f)))}
                 ))
         )
};    

(:~  annotation literals display :)
declare function xqa:literals($lits as element(xqdoc:literal)*)
as xs:string?
{ 
let $t:=$lits!(if(@type="xs:string") then  
               concat("'",string(),"'")
              else
                string()
)
return concat("(",string-join($t,","),")")          
 };

(:~  extract names from url may include = regex :) 
declare function xqa:extract-restxq($url as xs:string)
as xs:string*
{
  fn:analyze-string-XQDOCA($url,"\{\w*\$(\S*)\w*\}")/fn:match/fn:group/string()
};    