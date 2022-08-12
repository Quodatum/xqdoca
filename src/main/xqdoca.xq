xquery version "3.1";

(:~  
 : Generate documentation for for XQuery sources
 : @return info about the run (json format)  
 :)


import module namespace xqd = 'quodatum:xqdoca.model' at "lib/model.xqm";
import module namespace xqo = 'quodatum:xqdoca.outputs' at "lib/xqdoc-outputs.xqm";
import module namespace store = 'quodatum:store' at "lib/store.xqm";
 
declare option db:chop 'true';
 
(:~  URL of the root folder to document
 : @default C:/Users/andy/basex.home/webapp/dba/ 
 :)
declare variable $efolder as xs:string  external :=
(: "C:/Users/andy/Desktop/basex.sow8/legacy-migrate/" :)
"C:\Users\andy\Desktop\sow9\code\processor\psrv\"
              (: db:option("webpath") ||"/vue-poc/" :)
              (: db:option("webpath") ||"/dba/" :)
              (: file:parent(static-base-uri()) :)
              (: db:option("webpath") ||"/chat/" :)
              (: db:option("webpath") ||"/graphxq/" :) 
;

(:~ Location to save outputs as a base-uri 
 : @default  file:///{webpath}/static/xqdoc/{project}/
 :)
declare variable $target as xs:string external :="file:///{webpath}/static/xqdoc/{project}/" ;

(:~ Source file extensions to parse
 : @default  *.xqm,*.xq,*.xquery
 :)
declare variable $exts as xs:string external := "*.xqm,*.xq,*.xquery";
 
(:~  XQuery platform
 : @default basex 
 :)
declare variable $platform as xs:string  external := "basex";

prof:dump(($efolder,$target),"Vars: "),
let $efolder:=xs:anyURI($efolder) 
let $files:=xqd:find-sources($efolder,$exts)
let $model:= xqd:snap($efolder,$files,$platform) 
let $options:=map{
               "project": $model?project, 
               "outputs":  map{
                    "global": "index.html imports  annotations restxq xqdoca.xml"  , 
                    "module":  "module xqdoc xqparse "
                },
                "version": "0.3" 
               }
               
(: generate  outputs :)
let $pages:= xqo:render($model,$options)
let $target:=xqd:target($target,$options)   
 
return (
       store:store($pages,$target),
       xqo:export-resources($target),
       xqo:zip($target),
      (: arbitrary result for reporting :) 
       update:output(
         <json type="object">
            <project>{ $options?project }</project>
             <title>XQdocA generated</title>
              <source>{ $efolder }</source>
             <target>{ $target }</target>
              <created>{ current-dateTime() }</created>
             <status>completed</status>
             <msg>  {count($model?files)} files processed. Stored {count($pages)}</msg>
        </json> 
       )
)
