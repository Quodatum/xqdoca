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
import module namespace xqd = 'quodatum:xqdoca.xqdoc' at "xqdoc-proj.xqm";
import module namespace xqhtml = 'quodatum:build.xqdoc-html' at "xqdoc-html.xqm";
import module namespace xqh = 'quodatum:xqdoca.mod-html' at "xqdoc-htmlmod.xqm";


(:~  modules define an o/p created from the state :)
declare variable $xqo:modules:=
 map{ 
         "index":  map{
                      "title": "Index of sources",
                      "document": xqhtml:index-html2#2, 
                      "uri": 'index.html', "opts":  $xqd:HTML5
         },
         "restxq": map{
                      "title": "Http interface",
                      "document": function ($state,$opts){ xqhtml:restxq($state, xqd:rxq-paths($state),$opts)},
                      "uri": 'restxq.html', "opts":  $xqd:HTML5
         },
        "imports": map{
                   "title": "Module import",
                   "document": function ($state,$opts){ xqhtml:imports($state,xqd:imports($state),$opts)},
                   "uri": 'imports.html', "opts":  $xqd:HTML5
         },
        "annotations":map{
                   "title": "Annotation summary",
                   "document": function ($state,$opts){xqhtml:annotations($state,$opts)},
                   "uri":'annotations.html', "opts":  $xqd:HTML5
      }
    }
;

(:~  files define an o/p created from a source item :)
declare variable $xqo:files:=
 map{ 
        "xqdoc":  map{
                   "title": "XML file XQdoc format",
                   "document": function($file, $params,$state){ $file?xqdoc},
                    "uri": function($file){ $file?href || "/xqdoc.xml"}, "opts":  $xqd:XML
                 },
        "xqparse": map{
                   "title": "XML file of xquery parse tree output",
                   "document": function($file, $params,$state){ $file?xqparse},
                    "uri":  function($file){ $file?href || "xqparse.xml"}, "opts":  $xqd:XML
                 },
      "html":    map{
                   "title": "HTML page about the file (new)", 
                   "document": function($file, $params,$state){ xqh:xqdoc-html2($file?xqdoc, $params,$state)},
                   "uri": function($file){ $file?href || "index.html"}, "opts":  $xqd:HTML5
                 }          
    }
;


(: render an output :)
declare function xqo:module($name as xs:string,
                            $state as map(*),
                            $opts as map(*))
as map(*){
  let $def:= map:get($xqo:modules,$name)
  let $doc:= apply($def?document,[$state,$opts])
  return map:merge((map{"document": $doc}, $def))
};

(:~ render a per file o/p
 :)
declare function xqo:file($name as xs:string,
                            $file as map(*),
                            $params as map(*),
                            $state as map(*))
as map(*){
  let $def:= map:get($xqo:files,$name)
  let $doc:= apply($def?document,[$file,$params,$state])
  let $uri:= apply($def?uri,[$file])
  return map:merge((map{"document": $doc, "uri": $uri}, $def))
};

(:~
 : render all outputs for all per file outputs 
 :)
declare function xqo:files($outputs as xs:string*,$state as map(*),$opts as map(*))
as map(*)*
{
for $file at $pos in $state?files
let $params:=map:merge((
            map{
              "filename": $file?path,
              "show-private": true(),
              "root": "../../",
              "resources": "../../resources/"
            },
              $opts))
              
return $outputs!xqo:file(.,$file,$params,$state)
};

(:~ save runtime support files to output
 : @param $target destination folder
 :)
declare %updating
function xqo:export-resources($target as xs:string)                       
as empty-sequence(){  
archive:extract-to($target, file:read-binary(resolve-uri('resources.zip')))
};
