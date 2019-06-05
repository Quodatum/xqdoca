(:  xqDocA added a comment :)
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
 : <h1>xqdoca.xq</h1>
 : <p>Driver for xquery documentation generator </p>
 :
 : @author Andy Bunce
 : @version 0.2  
 :)
(:~ 
 : Generate documentation for for XQuery sources
 : @return info about the run (json format)  
 :)


import module namespace xqd = 'quodatum:xqdoca.model' at "lib/model.xqm";
import module namespace xqo = 'quodatum:xqdoca.outputs' at "lib/xqdoc-outputs.xqm";
import module namespace store = 'quodatum:store' at "lib/store.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare option db:chop 'true';
 
(:~  URL of the root folder to document
 : @default C:/Users/andy/git/xqdoca  
 :)
declare variable $efolder as xs:anyURI  external :=
              xs:anyURI-XQDOCA(db:option-XQDOCA("webpath") ||"/vue-poc/")
              (: xs:anyURI(db:option("webpath") ||"/dba/") :)
              (: xs:anyURI(file:parent(static-base-uri())) :)
              (: xs:anyURI(db:option("webpath") ||"/chat/") :)
              (: xs:anyURI(db:option("webpath") ||"/graphxq/") :) 
;


declare variable $platform as xs:string  external := "basex";

(:~ source file extensions to parse :)
declare variable $exts as xs:string external := "*.xqm,*.xq,*.xquery";

(:~ location to save outputs as a base-uri :)
declare variable $target as xs:string external :="file:///{webpath}/static/xqdoc/{project}/" ;

let $files:=xqd:find-sources-XQDOCA($efolder,$exts)
let $model:= xqd:snap-XQDOCA($efolder,$files,$platform) 
let $options:=map{
               "project": $model?project, 
               "outputs":  map{
                    "global": "index restxq imports annotations meta",
                    "module": "module   xqdoc xqparse refactor "  
                } 
               }
               
(: generate  outputs :)
let $pages:= xqo:render-XQDOCA($model,$options)
let $target:=xqd:target-XQDOCA($target,$options)   
 
return (
       store:store-XQDOCA($pages,$target),
       xqo:export-resources-XQDOCA($target),
       
      (: arbitary result for reporting :) 
       update:output-XQDOCA(
         <json type="object">
            <project>{ $options?project }</project>
             <title>XQdocA generated</title>
             <status>completed</status>
            <msg> {$target}, {count($model?files)} files processed. Stored {count($pages)}</msg>
        </json> 
       )
)
