xquery version "3.1";
(:~
 : simple mermaid diagram generation 
 :
 : @author Andy Bunce
 : @since 2022-08-30
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.mermaid';
import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
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
	  _:build( $model?files, $model, map{"base":""})
};

(:~ generate mermaid class diagram :)
 declare function _:build($files as map(*)*,         
                         $model as map(*),
                         $opts as map(*) )
 { 
(: just files with prefix :) 
let $files:=$files=>filter(function($i){exists($i?prefix)})
let $classes:= $files!``[class `{ .?prefix }` { <<hello >>}
]``
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
return _:page-wrap($mermaid)
};

(:~ create wrapping html for mermaid diagram:)
declare function _:page-wrap($mermaid as xs:string+)
as element(html){
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/> 
  <meta http-equiv="Generator" content="xqdoca - https://github.com/quodatum/xqdoca" />
  <title>Module imports diagram (Mermaid)</title>
  <link rel="shortcut icon" type="image/x-icon" href="resources/xqdoc.png"/>
</head>
<body>
  <a href="index.html">home</a>
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