xquery version "3.1";
(:~
annotation utils
 @Copyright (c) 2019-2026 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
:)
 

module namespace xqa = 'quodatum:xqdoca.model.annotations';


import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqa:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqa:nsUNIT:= 'http://basex.org/modules/unit';
declare variable $xqa:nsXQDOC:='https://github.com/Quodatum/xqdoca';
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
    "uri":'http://exquery.org/ns/restxq',
    "name":'path',
    "title":'RESTXQ',
    "icon": 'R',
    "class": 'success',
    "callable": true()
  },
   map{
    "uri":'http://basex.org/modules/unit',
    "name":'test',
    "title":'UNIT',
    "icon": 'T',
    "class": 'primary',
    "callable": true()
  },
   map{
    "uri":'https://github.com/Quodatum/xqdoca',
    "name":'output',
    "title":'XQdocA',
    "icon": 'D',
    "class": 'success',
    "callable": true()
  },
   map{
    "uri":'http://www.w3.org/2012/xquery',
    "name":'private',
    "title":'Private',
    'icon': 'P',
    "class": 'dark'
  }
);

declare variable $xqa:private:=
   map{
    "uri":'http://www.w3.org/2012/xquery',
    "name":'private',
    "title":'Private',
    'icon': 'P',
    "class": 'dark'
  };
  
(:~
 : html badges for annotations with known namespaces
 @param  $button-render $badge?icon, $badge?class, $badge?title
 :)
declare function xqa:badges($annos as element(xqdoc:annotation)*,
                            $file as map(*),
                            $button-render as function(*))
{
  let $prefixes:=$file?namespaces
  let $others:= some $a in $annos 
                satisfies let $m:=xqn:qmap($a/@name,$prefixes,$xqa:nsANN)
                          return not($m?uri = $xqa:noteworthy?uri)
  return (
    for $badge in $xqa:noteworthy
    where some $a in $annos 
          satisfies xqn:eq(xqn:qmap($a/@name,$prefixes,$xqa:nsANN), $badge?uri, $badge?name)
    return  $button-render($badge?icon, $badge?class, $badge?title)
    
    ,if($others) then $button-render("A", "info", "Other annotations") else ()
    )
};

(:~  true if rest:name :)
declare function xqa:is-rest($a  as element(xqdoc:annotation),$name as xs:string,$ns as map(*))
as xs:boolean
{
  xqn:eq(xqn:qmap($a/@name,$ns,$xqa:nsANN), $xqa:nsRESTXQ,$name)
};

(:~  true if test:name :)
declare function xqa:is-unit($a  as element(xqdoc:annotation),$name as xs:string,$ns as map(*))
as xs:boolean
{
  xqn:eq(xqn:qmap($a/@name,$ns,$xqa:nsANN), $xqa:nsUNIT,$name)
};

declare function xqa:is-out($a as element(xqdoc:annotation),$name as xs:string,$ns as map(*))
as xs:boolean
{
  xqn:eq(xqn:qmap($a/@name,$ns,$xqa:nsANN), $xqa:nsOUT,$name)
};


(:~ :)
declare function xqa:methods($annots  as element(xqdoc:annotation)*,$ns as map(*))
as xs:string*
{
 filter($xqa:methods,function($m){
   some $a in $annots 
   satisfies  xqn:eq(xqn:qmap($a/@name,$ns,$xqa:nsANN), $xqa:nsRESTXQ,$m)
 })
};    

(:~  info about function or variable :)
declare function xqa:name-detail($e as element(*),$file as map(*))
as map(*)
{
  let $name:=$e/xqdoc:name
       let $qmap:=xqn:qmap($name, $file?namespaces, $file?default-fn-uri)
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
 :           "annotation":{"name": ,"uri":}, "xqdoc": <xqdoc:annotation/>, "file":}
 :           }*
 : </pre>
 :)
declare function xqa:annotations($files as map(*)*)
as map(*)
{ 
  map:merge(
          for $f in $files, $a in $f?annotations
          group by $uri:=$a?annotation?uri
           return map:entry($uri,for-each-pair($a,$f,
                   function($a,$f){map:merge(($a,map:entry("file", $f)))}
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
  tokenize($url,"/\{")
  !replace(.,"\s*(\$\w*).*","$1")
  !(if (starts-with(.,"$")) then .)
};    