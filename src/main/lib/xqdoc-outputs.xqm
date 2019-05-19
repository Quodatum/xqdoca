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
 : <h1>xqdoc-outputs.xqm</h1>
 : <p>define availiable outputs</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace xqo = 'quodatum:xqdoca.outputs';



(:~ xqdoca annotation namespace :)
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

(:~ annotation for module derived output :)
declare variable $xqo:module:=QName("https://github.com/Quodatum/xqdoca","module");
declare variable $xqo:global:=QName("https://github.com/Quodatum/xqdoca","global");
(:~ annotation for serialization options :)
declare variable $xqo:ann-output:=QName("https://github.com/Quodatum/xqdoca","output");

(:~ defined serialization options :)
declare variable $xqo:outputs:=map{
                                     "html5": map{"method": "html", "version":"5.0", "indent": "no"},
                                     "xml": map{"indent": "no"},
                                     "json": map{"method": "json"}
                                   };




(:~ save runtime support files to output
 : @param $target destination folder
 :)
declare %updating
function xqo:export-resources($target as xs:string)                       
as empty-sequence(){  
archive:extract-to($target, file:read-binary(resolve-uri('resources.zip')))
};

(:~ 
 : list xqdoca render functions found in the static context
:)
declare function xqo:renderers($funs as function(*)*, $qname as xs:QName)
as function(*)*
{
  for $f in  $funs
  let $ann:=inspect:function-annotations($f) 
  where map:contains($ann,$qname) and map:contains($ann,$xqo:ann-output)
  return $f
};

(:~
 :  info about a render function
:)
declare function xqo:render-map( $function as function(*)?)
as map(*){
  let $ann:= inspect:function-annotations($function)
  let $key:=if(map:contains($ann,$xqo:module)) then
                $xqo:module
            else if(map:contains($ann,$xqo:global)) then
                $xqo:global
            else
               error(xs:QName("xqo:anno-map"))
   return map{
    "name": $ann?($key)[1],
     "description": $ann?($key)[2],
     "function": $function,
     "type": $key,
     "uri": $ann?($xqo:ann-output)[1],
     "output": $ann?($xqo:ann-output)[2]
} 
};

(:~
 :  render $outputs against state with options
:)
declare function xqo:render( $state as map(*),$opts as map(*))
as map(*)*
{
  let $funs:=xqo:load-generators()
  return (
      for $render in xqo:renderers($funs,$xqo:global)!xqo:render-map(.)
      where $render?name =$opts?outputs?global
      let $doc:= apply($render?function,[$state,$opts])
      return map{"document": $doc, 
                 "uri": $render?uri,
                 "output":$xqo:outputs?($render?output)
               },
               
      for $render in xqo:renderers($funs,$xqo:module)!xqo:render-map(.) 
      where  $render?name =$opts?outputs?module
      for $file at $pos in $state?files
      let $params:=map:merge((
            map{
              "filename": $file?path,
              "show-private": true(),
              "root": "../../",
              "resources": "../../resources/"
            },
              $opts))
      let $doc:= apply($render?function,[$file,$params,$state])       
      return map{"document": $doc, 
                 "uri": concat($file?href,"/",$render?uri),
                 "output": $xqo:outputs?($render?output)
                }
              )                                      
};

(:~
 : dynamically load functions from *.xqm modules in generators directory into static context
 :)
declare function xqo:load-generators()
as function(*)*
{
  let $base:=resolve-uri("generators/",static-base-uri())
  for $f in file:list($base,true(),"*.xqm")
  return inspect:functions(resolve-uri($f,$base))
};