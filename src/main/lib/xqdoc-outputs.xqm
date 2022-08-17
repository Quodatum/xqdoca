xquery version "3.1";
(:
 : Copyright (c) 2019-2022 Quodatum Ltd
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
 : <p>Load and run a set of generators</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 

module namespace xqo = 'quodatum:xqdoca.outputs';



(:~ xqdoca annotation namespace :)
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

(:~ annotation for module derived output :)
declare variable $xqo:module:=QName("https://github.com/Quodatum/xqdoca","module");

(:~ annotation for global derived output :)
declare variable $xqo:global:=QName("https://github.com/Quodatum/xqdoca","global");

(:~ annotation used to indicate serialization options :)
declare variable $xqo:ann-output:=QName("https://github.com/Quodatum/xqdoca","output");

(:~ defined serialization options :)
declare variable $xqo:outputs:=map{
                                     "html5": map{"method": "html", "version":"5.0", "indent": "no"},
                                     "xml": map{"indent": "no"},
                                     "json": map{"method": "json"},
                                     "text": map{"method": "text"}
                                   };




(:~ save runtime support files to output
 : @param $target destination folder
 :)
declare %updating
function xqo:export-resources($target as xs:string)                       
as empty-sequence(){
  let $res:=$target || "resources"
  let $_:=trace($target,"target:")
  let $_:=trace(resolve-uri('resources'),"src:")   
return  (
  if(file:exists($res)) then file:delete($res,true()) else (),
  file:copy(resolve-uri('resources'),$target)
      )
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
 :  render $outputs defined in $opts against state
 : @return seq of outputs generated suitable for"storing"
:)
declare function xqo:render( $model as map(*),$opts as map(*))
as map(*)*
{ 
  let $funs:=xqo:load-generators("generators/")
  
  let $globals:=xqo:tokens($opts?outputs?global)
  let $global:=(xqo:renderers($funs,$xqo:global)!xqo:render-map(.))[?name =$globals]
  
  let $modules:=xqo:tokens($opts?outputs?module)
  let $module:=(xqo:renderers($funs,$xqo:module)!xqo:render-map(.))[?name =$modules]
  
  (: add found renderers info to opts :)
  let $opts:=map:merge((map:entry(".renderers",map{"global":$global,"module":$module}),$opts))
  return (
      for $render in $global
      let $doc:= apply($render?function,[$model,$opts])
      return map{"document": $doc, 
                 "uri": $render?uri, 
                 "output":$xqo:outputs?($render?output)
               },
               
      for $render in $module, $file at $pos in $model?files
      (: override opts for destination path :)
      let $opts:=map:merge((
            map{
              "root": "../../",
              "resources": "../../resources/"
            }, $opts))
      let $doc:= apply($render?function,[$file,$model,$opts])       
      return map{"document": $doc, 
                 "uri": concat($file?href,"/",$render?uri),  
                 "output": $xqo:outputs?($render?output)
                }
              )                                      
};

(:~
 : dynamically load functions from *.xqm modules from generators directory into static context
 :)
declare function xqo:load-generators($path as xs:string)
as function(*)*
{
  let $base:=resolve-uri($path,static-base-uri())
  return file:list($base,true(),"*.xqm")
       !translate(.,"\","/")
       ! inspect:functions(resolve-uri(.,$base))
};

(:~ 
 : parse tokens
 :)
 declare function xqo:tokens($s as xs:string)
 as xs:string*
 {
 $s=>normalize-space()=>tokenize("[\s,]+") 
};

(:~ 
 : zip all 
 : @param $target destination folder using file protocoleg file:///
 :)
 declare %updating
 function xqo:zip($target as xs:string,$name as xs:string)
 as empty-sequence()
 {
  let $files := file:list($target=>trace("Creating zip: "), true())!util:if(not(ends-with(.,file:dir-separator() )),.)
let $zip   := archive:create(
                   $files,
                   $files!file:read-binary($target || translate(.,"\","/"))
               )
return file:write-binary($target || $name ||".zip", $zip)
 };