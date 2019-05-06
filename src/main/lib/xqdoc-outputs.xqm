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

declare variable $xqo:cache  :=false();

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
                   "document": function ($state,$opts){xqhtml:annotations($state,xqd:annotations($state),$opts)},
                   "uri":'annotations.html', "opts":  $xqd:HTML5
      }
    }
;

(:~  files define an o/p created from a source item :)
declare variable $xqo:files:=
 map{ 
        "xqdoc":  map{
                   "title": "XML file XQdoc format",
                   "document": function($file, $params){ $file?xqdoc},
                    "uri": function($file){ $file?href || "/xqdoc.xml"}, "opts":  $xqd:XML
                 },
        "xqparse": map{
                   "title": "XML file xqparse output",
                   "document": function($file, $params){ $file?xqparse},
                    "uri":  function($file){ $file?href || "xqparse.xml"}, "opts":  $xqd:XML
                 },
        "html2":    map{
                   "title": "HTML page about the file", 
                   "document": function($file, $params){ xqhtml:xqdoc-html($file?xqdoc, $params)},
                   "uri": function($file){ $file?href || "index2.html"}, "opts":  $xqd:HTML5
                 },
      "html":    map{
                   "title": "HTML page about the file (new)", 
                   "document": function($file, $params){ xqhtml:xqdoc-html2($file?xqdoc, $params)},
                   "uri": function($file){ $file?href || "index.html"}, "opts":  $xqd:HTML5
                 }          
    }
;


(: render :)
declare function xqo:module($name as xs:string,
                            $state as map(*),
                            $opts as map(*))
as map(*){
  let $def:= map:get($xqo:modules,$name)
  let $doc:= apply($def?document,[$state,$opts])
  return map:merge((map{"document": $doc}, $def))
};

declare function xqo:file($name as xs:string,
                            $file as map(*),
                            $params as map(*))
as map(*){
  let $def:= map:get($xqo:files,$name)
  let $doc:= apply($def?document,[$file,$params])
  let $uri:= apply($def?uri,[$file])
  return map:merge((map{"document": $doc, "uri": $uri}, $def))
};

declare function xqo:files($outputs as xs:string*,$state as map(*),$opts as map(*))
as map(*)*
{
for $file at $pos in $state?files
let $params:=map:merge((map{
              "filename": $file?path,
              "cache": $xqo:cache,
              "show-private": true(),
              "root": "../../",
              "resources": "../../resources/"},
              $opts))
              
return $outputs!xqo:file(.,$file,$params)
};

(:~ save runtime support files to $target :)
declare %updating
function xqo:export-resources($target as xs:string)                       
as empty-sequence(){  
archive:extract-to($target, file:read-binary(resolve-uri('resources.zip')))
};