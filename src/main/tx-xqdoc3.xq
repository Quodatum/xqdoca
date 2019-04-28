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
 : <h1>tx-xqdoc.xq</h1>
 : <p>Driver for xquery documentation generator </p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
(:~
 : Generate html for for XQuery sources
 : @return info about the run (json format)
 :)


import module namespace xqd = 'quodatum:build.xqdoc' at "lib/xqdoc-proj.xqm";
import module namespace xqhtml = 'quodatum:build.xqdoc-html' at "lib/xqdoc-html.xqm";
import module namespace store = 'quodatum:store' at "lib/store.xqm";

declare option db:chop 'true';

(:~ URL of the root folder to document
 : @default C:/Users/andy/git/vue-poc/src/vue-poc
 :)
declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");

declare variable $id as element(last-id):=db:open("vue-poc","/state.xml")/state/last-id;

let $target:="file:///" || db:option("webpath") || "/static/xqdoc/" || $id || "/"

let $state:=xqd:read($efolder)
let $opts:=map{
               "src-folder": $efolder, 
               "project": $state?project, 
               "ext-id": $id/string(),
               "resources": "resources/"
               }

(: generate o/ps per source file  :)
let $modmap:=for $file at $pos in $state?files
               let $params:=map:merge((map{
                              "source":  $file?xqparse/string(),
                              "filename": $file?path,
                              "cache": $xqd:cache,
                              "show-private": true(),
                              "root": "../../",
                              "resources": "resources/"},
                              $opts))
               return (
                 map{
                   "document": $file?xqdoc,
                    "uri":  $file?href || "/xqdoc.xml", "opts":  $xqd:XML
                 },
                  map{
                   "document": $file?xqparse,
                    "uri":  $file?href || "xqparse.xml", "opts":  $xqd:XML
                 },
                  map{
                   "document": xqd:xqdoc-html($file?xqdoc,$params),
                   "uri":  $file?href || "index.html", "opts":  $xqd:HTML5
                 }
               )
               
 let $index:= map{ 
                   "document": xqhtml:index-html2($state,$opts),
                   "uri": ``[index.html]``, "opts":  $xqd:HTML5
                 }
                 
 let $restxq:= map{
                   "document": xqhtml:restxq($state, xqd:rxq-paths($state),$opts),
                     "uri": ``[restxq.html]``, "opts":  $xqd:HTML5
                 }
let $imports:=map{
                   "document": xqhtml:imports($state,xqd:imports($state),$opts),
                     "uri": ``[imports.html]``, "opts":  $xqd:HTML5
                 }
return (
       store:store(($index,$restxq,$imports,$modmap),$target),
       xqhtml:export-resources2($target),
       replace value of node $id with 1+$id,
       update:output(
         <json type="object">
            <extra>XQdoc generated</extra>
            <msg> {$target}, {count($state?files)} files processed.</msg>
            <id>{$id/string()}</id>
        </json>
            )
       )

