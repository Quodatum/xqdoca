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
 : Generate html for for XQuery sources
 : @return info about the run (json format)
 :)


import module namespace xqd = 'quodatum:xqdoca.xqdoc' at "lib/xqdoc-proj.xqm";
import module namespace xqo = 'quodatum:xqdoca.outputs' at "lib/xqdoc-outputs.xqm";
import module namespace store = 'quodatum:store' at "lib/store.xqm";

declare option db:chop 'true';

(:~ URL of the root folder to document
 : @default C:/Users/andy/git/xqdoca
 :)
declare variable $efolder as xs:anyURI  external := xs:anyURI("C:/Users/andy/git/xqdoca");
declare variable $target as xs:string external :="file:///" || db:option("webpath") || "/static/xqdoc/" || $id || "/";
declare variable $host as xs:string  external := "basex";

declare variable $id as element(last-id):=db:open("vue-poc","/state.xml")/state/last-id;


let $state:=xqd:read($efolder,$host)
let $opts:=map{
               "src-folder": $efolder, 
               "project": $state?project, 
               "ext-id": $id/string(),
               "resources": "resources/",
               "outputs":  map{
                    "views": ("index","restxq","imports","annotations"),
                    "byfile": ("xqdoc","xqparse","html","html2")    
                },
                "renderers": map{
                  "modules": $xqo:modules,
                  "files": $xqo:files
                }              
               }
               
(: generate root outputs :)
let $pages:= $opts?outputs?views !xqo:module(.,$state,$opts)     
(: generate o/ps per source file  :)
let $modmap:= $opts?outputs?byfile !xqo:files(.,$state,$opts)
  
return (
       store:store(($pages,$modmap),$target),
       xqo:export-resources($target),
       replace value of node $id with 1+$id,
       update:output(
         <json type="object">
            <extra>XQdoc generated</extra>
            <msg> {$target}, {count($state?files)} files processed.</msg>
            <id>{$id/string()}</id>
        </json>
       )
)
