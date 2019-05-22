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

declare option db:chop 'true';
 
(:~ URL of the root folder to document
 : @default C:/Users/andy/git/xqdoca 
 :)
declare variable $efolder as xs:anyURI  external :=
              xs:anyURI(db:option("webpath") ||"/vue-poc/")
              (: xs:anyURI(db:option("webpath") ||"/dba/") :)
              (: xs:anyURI(file:parent(static-base-uri()) :)
              (: xs:anyURI(db:option("webpath") ||"/chat/") :) 
;


declare variable $platform as xs:string  external := "basex";

(:~ source file extensions to parse :)
declare variable $exts as xs:string external := "*.xqm,*.xq,*.xquery"; (: *.xqy:)

(: hack for unique ids @TODO use date:)
declare variable $id as element(last-id):=db:open("vue-poc","/state.xml")/state/last-id;

(:~ location to save outputs as a base-uri :)
declare variable $target as xs:string external :="file:///" || db:option("webpath") || "/static/xqdoc/" || $id || "/";

let $model:= xqd:snap($efolder,$platform,$exts) 
let $options:=map{
               "project": $model?project, 
               "resources": "resources/",
               "outputs":  map{
                    "global": ("index","restxq","imports","annotations","meta","xqdoc-validate"),
                    "module": ("xqdoc","xqparse","module")  
                }    
               }
               
(: generate  outputs :)
let $pages:= xqo:render($model,$options)   
(: arbitary result :)
let $result:=   <json type="object">
                    <extra>XQdoc generated</extra>
                    <msg> {$target}, {count($model?files)} files processed. Stored {count($pages)}</msg>
                    <id>{$id/string()}</id>
                </json> 
return (
       store:store($pages,$target),
       xqo:export-resources($target),
       replace value of node $id with 1+$id,
       update:output($result)
)
