xquery version "3.1";
(:~
 : simple mermaid diagram generation 
 :
 : @author Andy Bunce
 : @since 2022-08-30
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.mermaid';
import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../xqdoc-anno.xqm";

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ testing :)
declare %private variable $_:sample:='
classDiagram
direction LR
class audit
Class01 ..> AveryLongClass 
Class03 *-- Class04
Class05 o-- Class06
Class07 .. Class08
Class09 --> C2 : Where am i?
Class09 --* C3
Class09 --|> Class07
Class07 : equals()
Class07 : Object[] elementData
Class01 : size()
Class01 : int chimp
Class01 : int gorilla
Class08 &lt;--> C2: Cool label
class Class10 {
  &lt;&lt;service>>
  int id
  size()
}
link Class01 "modules/F000002/index.html" "This is a tooltip for Class01" 
';

declare 
%xqdoca:global("mermaid","Project wide module imports as a mermaid class diagram")
%xqdoca:output("mermaid.html","html5") 
function _:calls(        
                 $model as map(*),
                 $opts as map(*)
                 )                         
{
	  _:build( $model?files, $model, $opts)
};

(:~ generate mermaid class diagram :)
 declare function _:build($files as map(*)*,         
                         $model as map(*),
                         $opts as map(*) )
 { 
(: just files with prefix ie xqm :) 
let $files:=$files=>filter(function($i){exists($i?prefix)})
let $classes:=  $files!_:class(.)
              
let $links:= $files!``[link `{ .?prefix }` "`{ .?href }`index.html" "This is a tooltip for `{ .?namespace }`" 
]``
let $imports:=for $f in $files,
                $i in xqd:where-imported($f?namespace,$model)=>filter(function($i){exists($i?prefix)})
            return ``[`{ $i?prefix}` ..>`{ $f?prefix}` 
            ]``
        
let $mermaid:=``[
%%{init: {'securityLevel': 'loose', 'theme':'base'}}%%    
classDiagram
direction TB
`{ $classes }`
`{ $imports }`
`{ $links }`
]``
let $related:= page:related-buttons("global","mermaid", $opts) 
return _:page-wrap($mermaid,$related,$opts)
};

(:~ class def:)
declare function _:class($file as map(*))
as xs:string{
let $ns:= $file?prefixes
let $rest:=filter($file?xqdoc//xqdoc:annotation,xqa:is-rest("path",?,$ns))  

let $type:= if(exists($rest)) 
            then  '<< Rest >>'
            else ''
let $fns:="create()
job()
job-status()"
return ``[class `{ $file?prefix || util:if($rest,":::cssRest") }` { `{ $type }` 
`{ util:if($rest,$fns) }`}
]``
};

(:~html for mermaid diagram
 :)
declare function _:page-wrap($mermaid as xs:string+,$related,$opts as map(*))
as element(html){
<html lang="en">
{_:head("Module imports diagram (Mermaid)","resources/")}

<body>
<style>
    .cssRest > rect, line{{
        fill:palegreen !important;
        stroke:black !important;

    }}
</style>
  <nav id="toc" style="position:absolute"><span><span class="badge badge-info">{$opts?project}</span> - Module dependancy diagram (mermaid)</span>
  {$related}
  </nav>
  <div class="mermaid">{ $mermaid }</div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/9.1.6/mermaid.min.js" 
  integrity="sha512-jOk8b3W3aB8pr2T+mTHuffpzISAo8cYfOPkOpMIQZCSm/vH4Bn4efY/phVZsNZLMTsl4prvxO0jDt7fqyLgEuQ==" 
  crossorigin="anonymous" referrerpolicy="no-referrer"></script>
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
declare function _:head($title as xs:string,$resources as xs:string)
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