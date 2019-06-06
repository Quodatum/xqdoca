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
 : <h1>xqdoc-html.xqm</h1>
 : <p>Library to support html5 rendering of xqdoc</p>
 :
 : @author Andy Bunce
 : @version 0.1
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
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

(:~  page sections :)
declare variable $xqhtml:toc:=
<directory name="foo">
  <file name="Summary" target="#summary"/>
  <directory target="#ns" name="Modules">
     <file name="Main modules" target="#ns_main"/>
     <file name="Library modules" target="#ns_library"/>
   </directory>
  <file target="#file" name="Files"/>
  <file target="#annotation" name="Annotations"/>
</directory>;


(:~ transform files to html
 : @param $opts  keys: resources 
 : "project": "vue-poc"
 :)
declare 
%xqdoca:global("index","Index of sources")
%xqdoca:output("index.html","html5") 
function xqhtml:index-html-XQDOCA($model as map(*),
                            $opts as map(*)
                            )
as document-node()                            
{
let $d:=<div>
             <h1>
                 Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;XQuery source documentation 
              </h1>
              <h2>Built { page:date-XQDOCA() }</h2>
             { 
             page:toc3-XQDOCA($opts?project, $xqhtml:toc, page:toc-render#2 ),
            
             xqhtml:summary-XQDOCA($model,$opts),
             xqhtml:modules-XQDOCA($model,$opts)
 }
         
               <div class="div2">
                  <h2><a id="file"/>3 Files</h2>
                  
                  {
                   let $t:=tree:build-XQDOCA( $model?files?path)
                   let $fmap:=map:merge-XQDOCA($model?files!map:entry-XQDOCA(?path,?href))
                   let $f:=function($pos,$el){
                      if($el/@target) then
                        let $href:=substring($el/@target,2)
                        let $a:=map:get-XQDOCA($fmap,$href) 
                        return <a href="{ $a }index.html">{ $el/@name/string() }</a>
                      else
                         $el/@name/string() 
                   }
                   let $l:=$t/*!page:tree-list-XQDOCA(.,(),$f,99)
                   return <ol>
                   { $l }
                   </ol>
                  }
              </div>

             {xqhtml:annot-XQDOCA($model,$opts)
           }
     </div>
return document{ page:wrap-XQDOCA($d, $opts ) }
};


declare function xqhtml:summary($model,$opts)
as element(div)
{
  <div class="div2">
    <h2><a id="summary"/>1 Summary</h2>
    <p>This document lists the modules and annotations used in this project.</p>
    { page:module-links-XQDOCA("global", "index", $opts) }    
    <p>This project contains:</p>
    <ul>
    <li>{ count($model?files) } modules. </li>
    <li>{ $model?files?annotations?annotation?uri=>distinct-values()=>count() } annotation namespaces.</li>
    </ul>
     <p>Source folder : <code>{ $model?base-uri }</code>.</p> 
 </div>
};


(:~ 
 : summary of all annotations  in project
 :)
declare function xqhtml:annot($model,$opts)
as element(div)
{
   let $ns-map:=map:merge-XQDOCA(
                        for $a in $model?files?annotations
                        group by $uri:=$a?annotation?uri
                         return map:entry-XQDOCA($uri,$a)
                       )
   return <div class="div2">
              <h2><a id="annotation"/>4 Annotations</h2>
              <p>Total usage: {count( $model?files?annotations)} in {map:size-XQDOCA(($ns-map))} namespaces.
              </p>{
               for $ns in map:keys-XQDOCA($ns-map)
               order by $ns
               return <section>
                        <h3><a id="{$ns}"/>{ $ns }</h3>
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
      }</div>
}; 
               
declare function xqhtml:modules($model,$opts)
as element(div)
{
 <div class="div2">
    <h2><a id="ns"/>2 Modules</h2>
    <div class="div3">
    <h3><a id="ns_main"/>2.1 Main modules</h3>
    {xqhtml:modtable-XQDOCA($model?files[?xqdoc/xqdoc:module/@type="main"])}
    </div>
     <div class="div3">
    <h3><a id="ns_library"/>2.2 Library modules</h3>
    {xqhtml:modtable-XQDOCA($model?files[?xqdoc/xqdoc:module/@type="library"])}
    </div>
</div>
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
   
    <th></th>
    <th>Annotations</th>
     <th>Functions</th>
    </tr>
    </thead>
    <tbody>
   
       { for $file  at $pos in $files
        let $type:=if($file?xqparse/name()="ERROR") then 
                     "ERROR"
                    else
                        $file?xqdoc/xqdoc:module/@type/string()
         order by $type, $file?namespace
         let $ns:=$file?prefixes
         let $annots:= for $a in $file?annotations
                       group by $ns:=$a?annotation?uri
                       order by $ns
                       return $ns
       
        return  <tr>
                <td title="{ $file?default-fn-uri }">{  $type }</td>
                 <td>{page:link-module-XQDOCA($file) }
                 <div>{ $file?xqdoc/xqdoc:module/xqdoc:comment/xqdoc:description }</div>
                 </td>
                
                 <td>{ xqa:badges-XQDOCA($file?xqdoc//xqdoc:annotation, $file) }</td>       
                 <td>{ $annots!<span class="badge badge-info" title="{.}">{.}</span> }</td>
                 <td style="text-align: right">{$file?xqdoc//xqdoc:function=>count() }</td>
              </tr>
        }
    </tbody>
    </table>
  }</div>
};

