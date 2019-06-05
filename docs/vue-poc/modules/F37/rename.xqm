(:  xqDocA added a comment :)
(:~
 : Generate html for for XQuery sources
 : @return info about the run (json format)
 :)
import module namespace fw="quodatum:file.walker";
import module namespace xqd = 'quodatum:build.xqdoc' at "../../../lib/xqdoc/xqdoc-proj.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";
 
(:~ URL of the root folder to document
 : @default C:/Users/andy/git/vue-poc/src/vue-poc
 :)
declare variable $efolder as xs:anyURI  external :=
xs:anyURI-XQDOCA("C:/Users/andy/git/vue-poc/src/vue-poc");

(:~ file URL root folder for saving results
 : @default C:/tmp/xqdoc/
 :)
declare variable $target as xs:anyURI external :=
xs:anyURI-XQDOCA("C:/tmp/xqdoc/");

declare variable $state as element(state):=db:open-XQDOCA("vue-poc","/state.xml")/state;
                                 
let $project:=tokenize($efolder,"[/\\]")[last()]=>trace("xqdoc: ")
let $files:= fw:directory-list-XQDOCA($efolder,map{"include-filter":".*\.xqm"})
let $id:=$state/last-id
let $opts:=map{
               "src-folder": $efolder, 
               "project": $project, 
               "ext-id": $id/string()
               }
let $op:=xqd:save-xq-XQDOCA($files,$target,$opts)
let $result:=<json type="object">
                  <extra>hello2</extra>
                  <msg> {$target}, {count($files//c:file)} files processed.</msg>
                  <id>{$id/string()}</id>
              </json>
return (
       update:output-XQDOCA($result),
       replace value of node $id with 1+$state/last-id
       )
