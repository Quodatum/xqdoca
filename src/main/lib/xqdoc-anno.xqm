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
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqa:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqa:nsANN:='http://www.w3.org/2012/xquery';

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
declare function xqa:badges($annos as element(xqdoc:annotation)*, $file as map(*))
{
  let $prefixes:=$file?prefixes
  let $others:=some $a in $annos satisfies let $m:=xqn:qmap($a/@name,$prefixes,$xqa:nsANN)
                                               return not($m?uri = $xqa:noteworthy?uri)
  return (
    for $badge in $xqa:noteworthy
    where   some $a in $annos satisfies xqn:eq(xqn:qmap($a/@name,$prefixes,$xqa:nsANN), $badge?uri, $badge?name)
    return  page:badge($badge?icon, $badge?class, $badge?title)
    
    ,if($others) then page:badge("A", "info", "Other annotations") else ()
    )
};


declare function xqa:is-rest($a  as element(xqdoc:annotation),$ns as map(*))
as xs:boolean
{
  xqn:eq(xqn:qmap($a/@name,$ns,$xqa:nsANN), $xqa:nsRESTXQ,"path")
};


declare function xqa:only-rest($annots  as element(xqdoc:annotation)*,$ns as map(*))
as xs:boolean
{
  $annots=>filter(xqa:is-rest(?,$ns))
};

(:~ annotation attached to :)
declare function xqa:container($a  as element(xqdoc:annotation),$file as map(*))
as map(*)?
{
 if($file?parsed) then
       let $e:=$a/../..
       let $name:=$e/xqdoc:name
       let $qmap:=xqn:qmap($name, $file?prefixes, $file?default-fn-uri)
       let $lname:=if($e instance of element(xqdoc:function)) then
                     concat($qmap?name,"#",$e/@arity)
                   else
                    concat("$",$name)
       return map{"given": $name/string(), "uri": $qmap?uri, "name": $lname}
else
  ()
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
  map:merge(
          for $f in $model?files, $a in $f?annotations
          group by $uri:=$a?annotation?uri
           return map:entry($uri,for-each-pair($a,$f,
                   function($a,$f){map:merge(($a,map:entry("file", $f)))}
                 ))
         )
};         