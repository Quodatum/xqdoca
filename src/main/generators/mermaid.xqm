xquery version "3.1";
(:~
Diagrams showing project module imports. Generated with `mermaid.js`.

@see https://mermaid-js.github.io/mermaid/#/
@copyright Copyright (c) 2019-2022 Quodatum Ltd
@author Andy Bunce, Quodatum, License: Apache-2.0
:)
 
module namespace _ = 'quodatum:xqdoca.generator.mermaid';
import module namespace xqd = 'quodatum:xqdoca.model' at "../lib/model.xqm";
(:~ html page utils :)
import module namespace page = 'quodatum:xqdoca.page'  at "../lib/xqdoc-page.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../lib/annotations.xqm";

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare namespace xqdoc="http://www.xqdoc.org/1.0";


(:~ generate html page containing import imports diagram using mermaid.js :)
declare 
%xqdoca:global("imports-diag","Project wide module imports as html mermaid class diagram")
%xqdoca:output("mermaid.html","html5") 
function _:html(        
                 $model as map(*),
                 $opts as map(*)
                 )                         
{
	  let $mermaid:=_:mmd( $model, $opts)
    let $related:= page:related-buttons("global","mermaid", $opts) 
    return _:page-wrap($mermaid,$related,$opts)
};

(:~ generate text for mermaid class diagram in mmd format:)
 declare 
 %xqdoca:global("mermaid.mmd","Project wide module imports as a mermaid class diagram")
%xqdoca:output("mermaid.mmd","text") 
 function _:mmd($model as map(*),         
                $opts as map(*) )
 as xs:string{ 
let $files:=$model?files
(: just files with prefix ie xqm :) 
let $friendly:= $files!_:class-name(.,position(),$files)

let $classes:=  $friendly!_:class(.)             
let $links:= $friendly!``[link `{ .?mermaid }` "`{ .?href }`index.html" "This is a tooltip for `{ .?namespace }`" 
]``
let $imports:=for $f in $friendly,
                $i in xqd:where-imported($friendly, $f?namespace)
                return ``[`{ $i?mermaid}` ..>`{ $f?mermaid}` 
]``
       
return``[%%{init: {'securityLevel': 'loose', 'theme':'base'}}%%    
classDiagram
direction TB
`{ $classes }`
`{ $imports }`
`{ $links }`
]``

};

(:~ generate mermaid class definition :)
declare %private
function _:class($file as map(*))
as xs:string{
let $name:=$file?mermaid
let $ns:= $file?namespaces
let $restfns:=$file?xqdoc
              //xqdoc:function[
                              xqdoc:annotations/xqdoc:annotation
                              =>filter(xqa:is-rest(?,"path",$ns))
                              ]
let $fns:=$restfns/xqdoc:name=>_:class-fns-list()

let $is-main:= $file?xqdoc/xqdoc:module/@type eq "main"
let $vars:=$file?xqdoc
              //xqdoc:variable/xqdoc:name=>_:class-vars-list()

return if($restfns)
       then ``[class `{ $name }`:::cssRest { << Rest `{$file?path }`>> 
`{ $fns }`}
]``
       else if($is-main)
            then ``[class `{ $name }`:::cssMain{ << `{ $file?path }` >>
`{ $vars }`}
]``
            else ``[class `{ $name }` { << `{ tokenize($file?path,"/")[last()] }` >>}
]``
};

(:~ add "mermaid" key to $file map value unique label
:)
declare %private 
function _:class-name($file as map(*), $pos as xs:integer, $files as map(*)*)
as map(*){
  let $fn:=function($file){if($file?prefix)then $file?prefix else "local"}
  let $name:=$fn($file)
  let $count:=subsequence($files,1,$pos -1)!$fn(.)[. eq $name]=>count()
  return (map:entry("mermaid", translate($name,"-","_") || util:if($count gt 0, "Δ" ||1+ $count)),
          $file)=>map:merge()
};

(:~ generate mermaid function list :)
declare %private
function _:class-fns-list($names as xs:string*)
as xs:string{
let $r:=$names!substring-after(.,":")
        !concat(.,"()")
        =>sort()
        =>string-join(file:line-separator())
return concat(file:line-separator(),$r,file:line-separator())
};

(:~ generate mermaid vars list :)
declare %private
function _:class-vars-list($names as xs:string*)
as xs:string{
let $r:=$names
        =>sort()
        =>string-join(file:line-separator())
return concat(file:line-separator(),$r,file:line-separator())
};

(:~ html wrapping for mermaid diagram
 :)
declare %private
function _:page-wrap($mermaid as xs:string+,$related,$opts as map(*))
as element(html){
<html lang="en">
{_:head("Module imports diagram (Mermaid)","resources/")}

<body>
<style>
    .cssRest > rect, line{{
        fill:palegreen !important;
        stroke:black !important;
    }}
    .cssMain > rect, line{{
        fill:powderblue !important;
        stroke:black !important;
    }}
</style>
  <nav id="toc" style="position:absolute;top:0"><span><span class="badge badge-info">{$opts?project}</span> - Module dependancy diagram (mermaid)</span>
  {$related}
  </nav>
  <div class="mermaid">{ $mermaid }</div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/9.3.0/mermaid.min.js" 
  integrity="sha512-ku2nmBrzAXY5YwohzTqLYH1/lvyMrpTVxgQKrvTabd/b/uesqltLORdmpVapYv6QhZVCLUX6wkvFaKOAY4xpUA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>  
  <script>mermaid.initialize({{
  startOnLoad:true,
  logLevel: "error", 
  securityLevel: "loose", 
  theme: (window.matchMedia &amp;&amp; window.matchMedia("(prefers-color-scheme: dark)").matches) ? "dark" :  "default" 
    }});</script>
</body>
</html>
};

(:~ common html head
@param resources relative path to resources
 :)
declare %private
function _:head($title as xs:string,$resources as xs:string)
as element(head){
     <head>
       <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
       <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/> 
       <meta http-equiv="Generator" content="xqdoca - https://github.com/quodatum/xqdoca" />
        <title>{ $title } - xqDocA</title>
        
        <link rel="shortcut icon" type="image/x-icon" href="{ $resources }xqdoc.png" />
        <link rel="stylesheet" type="text/css" href="{ $resources || $page:prism }prism.css"/>
        <link rel="stylesheet" type="text/css" href="{ $resources }page.css" />
        <!--
        <link rel="stylesheet" type="text/css" href="{ $resources }query.css" />
        <link rel="stylesheet" type="text/css" href="{ $resources }base.css" /> 
        -->  
      </head>
};