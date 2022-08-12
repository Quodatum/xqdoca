xquery version "3.1";
(:
 : Copyright (c) 2019-2022 Quodatum Ltd
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
 : <h1>xqdoc-html.xqm</h1>
 : <p>Library to support html5 rendering of xqdoc</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
(:~
 : Generate XQuery  documentation in html
 : using file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models
 : $efolder:="file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models"
 : $target:="file:///C:/Users/andy/workspace/app-doc/src/doc/generated/models.xqm"
 :)
module namespace xqhtml = 'quodatum:xqdoca.generator.index';

import module namespace tree = 'quodatum:data.tree' at "../tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../xqdoc-anno.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~ transform files to html
 : @param $opts  keys: resources 
 : "project": "vue-poc"
 :)
declare 
%xqdoca:global("index.html","Index of sources")
%xqdoca:output("index.html","html5") 
function xqhtml:index-html($model as map(*),
                            $opts as map(*)
                            )
as document-node()                            
{
 let $sections:=(
                 xqhtml:summary($model,$opts),
                 xqhtml:modules("main_mods" ,"Main modules",$model?files[?xqdoc/xqdoc:module/@type="main"]),
                 xqhtml:modules("library_mods" ,"Library modules",$model?files[?xqdoc/xqdoc:module/@type="library"]),
                 xqhtml:files($model,$opts),
                 xqhtml:annot($model,$opts)
             )     
let $d:=<div>
             <h1>
                 Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;XQuery source documentation 
              </h1>
              <div style="text-align:right"><small >{ page:date()}</small></div>
             { page:toc($opts?project,$sections) }
        </div>
return document{ page:wrap(($d,$sections), $opts ) }
};


declare function xqhtml:summary($model,$opts)
as element(section)
{
  <section id="summary">
    <h2>Summary</h2>
     
    <p>The project 
    <span class="badge badge-info">{ $opts?project }</span> contains
  
    { count($model?files) } modules and references
 { $model?files?annotations?annotation?uri=>distinct-values()=>count() } annotation namespaces.
    </p>
     <p>This document was built from source folder <kbd>{ $model?base-uri }</kbd>.</p>
   { page:module-links("global","index.html", $opts) }
 </section>
};


(:~ 
 : summary of all annotations  in project
 :)
declare function xqhtml:annot($model,$opts)
as element(section)
{
   let $ns-map:=map:merge(
                        for $a in $model?files?annotations
                        group by $uri:=$a?annotation?uri
                         return map:entry($uri,$a)
                       )
   return <section id="annotation">
              <h2>Annotations</h2>
              <p>Annotations are defined in {map:size(($ns-map))} namespaces. A total of {count( $model?files?annotations)} annotations are defined.
              </p>{
               for $ns in map:keys($ns-map)
               order by $ns
               return <section id="{$ns}">
                        <h3>{ $ns }</h3>
                        <div>
                        {for $a in $ns-map?($ns)
                        group by $name:=$a?annotation?name
                        order by lower-case($name)
                        return <span style="margin-right:1em;">
                                  <a href="annotations.html#{{{ $ns }}}{ $name }" >{$name}</a>
                                  <span class="badge badge-info">{count($a)}</span>
                               </span>
                      }</div>
                     </section>
      }</section>
}; 
               
declare function xqhtml:modules($id,$title,$mods)
as element(section)
{
 <section id="{ $id }">
  
    <h2>{ ``[ `{ $title }` (`{ count($mods) }`)]`` }</h2>
    { xqhtml:modtable($mods) }

</section>
};


declare function xqhtml:files($model,$opts)
as element(section)
{
       let $t:=tree:build( $model?files?path)
       let $fmap:=map:merge($model?files!map:entry(?path,?href))
       let $f:=function($pos,$el){
          if($el/@target) then
            let $href:=substring($el/@target,2)
            let $a:=map:get($fmap,$href) 
            return <a href="{ $a }index.html">{ $el/@name/string() }</a>
          else
             $el/@name/string() 
       }
       return
      <section  id="file">
	      <h2>{ ``[File view (`{ count($model?files) }`)]`` }</h2>
	   
	      {
	        <ul class="tree">
	          { $t/*!page:tree-list2(.,(),$f,99) }
	       </ul>
	      }
	    </section>
};

declare function xqhtml:modtable($files as map(*)*)
as element(div)
{
  <div>{if (count($files)=0) then
          <p>None</p>
        else
     <table class="data">
    <thead>
    <tr>
    <th>Type</th>
    <th>Uri</th>
    <th>Description</th>
    <th></th>
    <th>Annotations</th>
     <th>Functions</th>

    </tr>
    </thead>
    <tbody>
   
       { for $file  at $pos in $files
        let $type:=xqd:file-parsed-type($file)
         order by $type, $file?namespace
         let $ns:=$file?prefixes
         let $annots:= for $a in $file?annotations
                       group by $ns:=$a?annotation?uri
                       order by $ns
                       return $ns
       
        return  <tr>
                <td title="{ $file?default-fn-uri }">{   xqhtml:file-usage($file) }</td>
                 <td>{page:link-module($file) }</td>
                 <td>{ $file?xqdoc/xqdoc:module/xqdoc:comment/xqdoc:description=>string() }</td>
               
                 <td>{ xqa:badges($file?xqdoc//xqdoc:annotation, $file) }</td>       
                 <td>{ $annots!<span class="badge badge-info" title="{.}">{.}</span> }</td>
                 <td style="text-align: right">{$file?xqdoc//xqdoc:function=>count() }</td>
              </tr>
        }
    </tbody>
    </table>
  }</div>
};

(:~ usage (import) info :)
declare 
function xqhtml:file-usage($file as map(*))                       
as element(span)
{ 
   switch( xqd:file-parsed-type($file))
   case "main"    return
                    let $imported:=0 
   					return <span><span title="Main">M</span>{ "&#10152;" || $imported}</span>
   					
   case "library" return
                    let $imported:=0
                    let $importedBy:=3 
                     return <span>{ $importedBy }<span>&#10152;</span><span title="Library">L</span>{ "&#10152;" || $imported}</span>
   
   default        return <span>#ERROR</span>
};
