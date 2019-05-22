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
module namespace xqhtml = 'quodatum:build.xqdoc-html';

import module namespace tree = 'quodatum:data.tree' at "../tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";




(:~ transform files to html
 : @param $opts  keys: resources 
 : "project": "vue-poc"
 :)
declare 
%xqdoca:global("index","Index of sources")
%xqdoca:output("index.html","html5") 
function xqhtml:index-html2($model as map(*),
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
             
              { page:toc2($opts?project, 
                                <toc>
                                  <item href="#summary" >Summary</item>
                                  <item href="#ns" >Modules</item>
                                  <item href="#file" >Files</item>
                                  <item href="#annotation" >Annotations</item>
                                   <item href="#perspectives" >Other perspectives</item>
                                </toc>
                  )
                  , xqhtml:summary($model,$opts)
                  , xqhtml:modules($model,$opts)
 }
         
               <div class="div2">
                  <h2><a id="file"/>3 Files</h2>
                  <ul>{ 
                  for $file  at $pos in $model?files
                  return  <li>
                            <a href="{ $file?href }index.html">
                               { $file?path }
                            </a>      
                            { $pos }
                        </li>
                  }</ul>
              </div>

             {xqhtml:annot($model,$opts)
              ,xqhtml:perspectives($model,$opts)
           }
     </div>
return document{ page:wrap($d, $opts ) }
};

declare function xqhtml:summary($model,$opts)
as element(div)
{
  <div class="div2">
    <h2><a id="summary"/>1 Summary</h2>
    <p>This project contains:</p>
    <ul>
    <li>{ count($model?files) } modules. </li>
    <li>{ $model?files?annotations?annotation?uri=>distinct-values()=>count() } annotation namespaces.</li>
    </ul>
     <p>Source folder : { $model?base-uri }</p> 
 </div>
};

declare function xqhtml:perspectives($model,$opts)
as element(div)
{
 <div class="div2">
  <h2><a id="perspectives"/>5 Other perspectives</h2>
  { page:view-list( $opts(".renderers")?global,"index")}
  </div>
};

declare function xqhtml:annot($model,$opts)
as element(div)
{
   let $ns-map:=map:merge(
                        for $a in $model?files?annotations
                        group by $uri:=$a?annotation?uri
                         return map:entry($uri,$a)
                       )
   return <div class="div2">
              <h2><a id="annotation"/>4 Annotations</h2>
              <p>Total usage: {count( $model?files?annotations)} in {map:size(($ns-map))} namespaces.
              </p>{
               for $ns in map:keys($ns-map)
               order by $ns
               return <section>
                        <h3>{ $ns }</h3>
                        <div>
                        {for $a in $ns-map?($ns)
                        group by $name:=$a?annotation?name
                        order by lower-case($name)
                        return <a href="annotations.html" class="badge badge-info" style="margin-right:1em;">{$name}
                                 <span class="badge badge-light">{count($a)}</span>
                               </a>
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
    {xqhtml:modtable($model?files[?xqdoc/xqdoc:module/@type="main"])}
    </div>
     <div class="div3">
    <h3><a id="ns_library"/>2.2 Library modules</h3>
    {xqhtml:modtable($model?files[?xqdoc/xqdoc:module/@type="library"])}
    </div>
</div>
};

declare function xqhtml:modtable($files as map(*)*)
as element(table)
{
     <table class="data">
    <thead>
    <tr>
    <th>Type</th>
    <th>Uri</th>
   
    <th></th>
    <th>Annotations</th>
     <th>calls</th>
    </tr>
    </thead>
    <tbody>
   
       { for $file  at $pos in $files
        let $type:=if($file?xqparse/name()="ERROR") then 
                     "ERROR"
                    else
                        $file?xqdoc/xqdoc:module/@type/string()
         order by $type, $file?namespace
         let $annots:= for $a in $file?annotations
                       group by $ns:=$a?annotation?uri
                       order by $ns
                       return $ns
          let $updating  :=count(xqd:anno-updating($file?annotations))
        let $rest  :=count(xqd:anno-rest($file?annotations))
        return  <tr>
                <td>{  $type }</td>
                 <td>{page:link-module($file) }</td>
                
                 <td>{ 
                       if($updating) then <span class="badge badge-danger" title="Updating">U</span> else ()
                      ,if($rest) then <span class="badge badge-info" title="rest">R</span> else () 
                    }</td>       
                 <td>{ $annots!<span class="badge badge-info" title="{.}">{.}</span> }</td>
                 <td>{$file?xqdoc//xqdoc:invoked=>count() }</td>
              </tr>
        }
    </tbody>
    </table>
};

(:~ import page :)
declare 
%xqdoca:global("import","Summary of import usage")
%xqdoca:output("imports.html","html5") 
function xqhtml:imports($model,$opts)
{
  let $imports:=xqd:imports($model)
  let $body:=<div>
   <nav id="toc">
            <h2>
                <a href="index.html" class="badge badge-success">
                    { $model?project }
                </a>
                / Imports
            </h2>
           
            <h3>
               Contents
            </h3>
            <ol class="toc">
                <li>
                    <a href="#main">
                        <span class="secno">1 </span>
                        <span class="content">Introduction</span>
                    </a>
                </li>
                
             </ol>
           </nav>
           <a href="index.html">index</a>
           <p>Lists all modules imported.</p>
           {for $import in $imports
           order by $import?uri
           return <div  id="{ $import?uri }">
           <h4>{ $import?uri }
           <div  style="float:right"><a href="#{ $import?uri }">#</a></div>
           </h4>
           <ul>
           {for $f in  $import?where
           return <li><a href="{$f?href}index.html">{ $f?namespace }</a></li>
         }
           </ul>
           </div>
           }
  </div>
  return  page:wrap($body,$opts)
};

