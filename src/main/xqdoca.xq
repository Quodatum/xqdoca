xquery version "3.1";

(:~  
 : Generate documentation for for XQuery sources
 : @return info about the run (json format)  
 :)


import module namespace xqd = 'quodatum:xqdoca.model' at "lib/model.xqm";
import module namespace xqo = 'quodatum:xqdoca.outputs' at "lib/xqdoc-outputs.xqm";
import module namespace store = 'quodatum:xqdoca:store' at "lib/store.xqm";
import module namespace opts = 'quodatum:xqdoca:options' at "lib/options.xqm"; 
declare option db:chop 'true';
 
(:~  path to XML options file :)
declare variable $src as xs:string  external;
let $src:=$src
          =>file:resolve-path(file:current-dir())

let $options:=opts:as-map(doc($src)/*)
               =>opts:merge(opts:as-map(doc("config.xqdoca")/*))
               =>map:merge(map:entry("project","DEF PROJ"))

let $efolder:=$options?source
              =>file:resolve-path(file:current-dir())
              =>xs:anyURI()

let $target:= $options?target

let $files:=xqd:find-sources($efolder, $options?extensions)
let $model:= xqd:snap($efolder, $files, $options?platform) 

(: generate  outputs :)
let $pages:= xqo:render($model,$options)
let $target:=xqd:target($target,$options)   
 
return (
       store:store($pages,$target),
       xqo:export-resources($target),
       (: xqo:zip($target, $options?project), :)
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
