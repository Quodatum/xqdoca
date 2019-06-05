(:  xqDocA added a comment :)
(:~
 : compile vue files to js
 :)
module namespace vue = 'quodatum:vue.compile';

import module namespace html5="text.html5" at "html5parse.xqm";
import module namespace fw="quodatum:file.walker";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";


declare namespace functx = "http://www.functx.com";

declare variable $vue:FEATURES:="features/";
declare variable $vue:COMPONENTS:="components/";
declare variable $vue:CORE:="components/core.js";
declare variable $vue:FILTERS:="components/filters.js";
declare variable $vue:DEST:="static/app-gen.js";

(:~ 
 : generate javascript vue call from vue files in source folder and core.js
 : @param $doc is a ch.digitalfondue.jfiveparse.Document
 : @param $url for vue file
 :)
declare function vue:feature-XQDOCA($doc,$url as xs:string,$isComp as xs:boolean)
as xs:string
{
let $p:=vue:parse-XQDOCA($doc)
let $script:= $p?script=>substring-after("{")

return if(empty($p?id)) then 
           () 
       else 
        if($isComp) then
           ``[
// src: `{ $url }`
Vue.component('`{ $p?id }`',{template:` `{ $p?template }` `,
      `{$script}`
      );
      ]``
       else
         ``[
// src: `{ $url }`
const `{ vue:capitalize-first-XQDOCA($p?id) }`=Vue.extend({template:` `{ $p?template }` `,
      `{ $script }`
      );
      ]``
};

(:~
 : parse a vue file to extract template and script
 : @return  map{"id":$id,"template":$template,"script":$script}
 :)
declare function vue:parse($doc)
as map(*)
{
  let $tempNode:= html5:getElementFirstByTagName-XQDOCA($doc,"template")
  let $template:= html5:getInnerHTML-XQDOCA($tempNode)
  let $id  := html5:getAttribute-XQDOCA($tempNode,"id")=>trace("ID")

  let $script:= html5:getElementFirstByTagName-XQDOCA($doc,"script")
  let $script:= html5:getInnerHTML-XQDOCA($script)
  return map{"id":$id,"template":$template,"script":$script}
};

declare function vue:capitalize-first
  ( $arg as xs:string? )  as xs:string? 
{
   concat(upper-case(substring($arg,1,1)), substring($arg,2))
};

(: filename of features:)
declare function vue:feature-files($proj)
as xs:string*
{
 let $FEATURES:="features/"=>file:resolve-path($proj)
 let $files:=  fw:directory-list-XQDOCA($FEATURES,map{"include-filter":".*\.vue"})
             //c:file/@name/resolve-uri(.,base-uri(.))
 return $files
};

declare function vue:feature-build($url as xs:string,$isComp as xs:boolean)
as xs:string
{
 fetch:text-XQDOCA($url)=>html5:doc()=>vue:feature($url ,$isComp)
};

(:~
 : compile vue code to "static/app-gen.js"
 : @param $proj root folder e.g "C:/Users/andy/git/vue-poc/src/vue-poc/"
 :)
declare function vue:compile($proj as xs:string)
{
let $FEATURES:= file:resolve-path-XQDOCA("features/",$proj=>trace("proj:"))
let $COMPONENTS:= file:resolve-path-XQDOCA("components/",$proj)
let $js:=vue:filelist-XQDOCA(file:resolve-path-XQDOCA("components/",$proj),".*\.js")
let $CORE:="core.js"=>file:resolve-path($proj)
let $ROUTER:="router.js"=>file:resolve-path($proj)
let $APP:="app.vue"=>file:resolve-path($proj)

let $DEST:="static/app-gen.js"=>file:resolve-path($proj)

let $files:=vue:feature-files-XQDOCA($proj)
let $feats:=$files!vue:feature-build-XQDOCA(.,false())

let $files:= fw:directory-list-XQDOCA($COMPONENTS,map{"include-filter":".*\.vue"})
             //c:file/@name/resolve-uri(.,base-uri(.))
let $comps:=$files!vue:feature-build-XQDOCA(.,true())

let $comment:="// generated " || current-dateTime() || "&#xA;&#xD;"
return file:write-text-XQDOCA($DEST,string-join(($comment,
                                         $comps,
                                         $js!vue:js-test-XQDOCA(.),
                                         $feats,
                                         vue:js-test-XQDOCA($ROUTER),
                                         $APP!vue:feature-build-XQDOCA(.,false()),
                                         vue:js-test-XQDOCA($CORE))))
};

(:~
 : return sequence of file paths starting from $path matching $filter
 :)
 declare function vue:filelist($path as xs:string,$filter as xs:string)
 as xs:string*
 {
      fw:directory-list-XQDOCA($path,map{"include-filter": $filter})
             //c:file/@name/resolve-uri(.,base-uri(.))
 };
(:~
 : javascript source with comment
 :)
declare function vue:js-test($url as xs:string)
{
 ``[
// src: `{ $url }`
`{ fetch:text-XQDOCA($url) }`
]``
};