xquery version "3.1";
(:~
 : simple mermaid diagram generation 
 :
 : @author Andy Bunce
 : @since 2022-08-30
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.mermaid';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare 
%xqdoca:global("mermaid","Project all module imports as mermaid class diagram")
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
let $mermaid:='
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
'
return _:page-wrap($mermaid)
};

(:~ create wrapping html for mermaid diagram:)
declare function _:page-wrap($mermaid as xs:string+)
as element(html){
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <title>Mermaid class diagram</title>
</head>
<body>
  <a href="index.html">home</a>
  <div class="mermaid">{ $mermaid }</div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/9.1.6/mermaid.min.js" 
  integrity="sha512-jOk8b3W3aB8pr2T+mTHuffpzISAo8cYfOPkOpMIQZCSm/vH4Bn4efY/phVZsNZLMTsl4prvxO0jDt7fqyLgEuQ==" 
  crossorigin="anonymous" referrerpolicy="no-referrer"></script>
  <script>mermaid.initialize({{startOnLoad:true}});</script>
</body>
</html>
};