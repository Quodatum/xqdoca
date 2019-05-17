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
import module namespace tree = 'quodatum:data.tree' at "tree.xqm";
import module namespace xqh = 'quodatum:xqdoca.mod-html' at "xqdoc-htmlmod.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqhtml:mod-xslt external :="html-module.xsl";

declare variable $xqhtml:toc1 :=<toc>
  <item href="#main" >Introduction</item>
  <item href="#ns" >Module Uris</item>
  <item href="#file" >Files</item>
  <item href="#annotation" >Annotations</item>
</toc>;

(:~ transform files to html
 : @param $params  keys: resources 
 : "ext-id": "299",
 : "src-folder": "C:/Users/andy/git/vue-poc/src/vue-poc",
 : "project": "vue-poc"
 :)
declare function xqhtml:index-html2($state as map(*),
                            $opts as map(*)
                            )
as document-node()                            
{
let $d:=<div>
             <h1>
                  <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;XQuery source documentation 
              </h1>
             
              { page:toc2($opts?project, $xqhtml:toc1) }
              { xqhtml:view-list($opts,"index")}
              <div>src: { $opts?src-folder }</div>
             
              <div id="ns">
                  <h1>Module Uris</h1>
                  <table class="data">
                  <thead>
                  <tr>
                  <th>Type</th>
                  <th>Uri</th>
                  <th>refs</th>
                  <th>Updating</th>
                  <th>Annotations</th>
                  </tr>
                  </thead>
                  <tbody>
                 
                     { for $file  at $pos in $state?files
                      let $type:=if($file?xqparse/name()="ERROR") then 
                                   "ERROR"
                                  else
                                      $file?xqdoc/xqdoc:module/@type/string()
                       order by $type, $file?namespace
                       let $annots:= for $a in $file?annotations
                                     group by $ns:=$a?annotation?uri
                                     order by $ns
                                     return $ns
                       let $updating:= xqhtml:has-annot($file?annotations,("http://www.w3.org/2012/xquery", "updating"))
                      return  <tr>
                              <td>{  $type }</td>
                               <td>{page:module($file) }</td>
                               <td>{$file?xqdoc//xqdoc:invoked=>count() }</td>
                               <td>{ if($updating) then <span class="badge badge-danger">U</span> else () }</td>       
                               <td>{ $annots!<span class="badge badge-info" title="{.}">{.}</span> }</td>
                              
                            </tr>
                      }
                  </tbody>
                  </table>
              </div>
               <div id="file">
                  <h1>Files</h1>
                  <ul>
                      { for $file  at $pos in $state?files
                   
                      return  <li>
                                <a href="{ $file?href }index.html">
                                   { $file?path }
                                </a>      
                                { $pos }
                            </li>
                      }
                  </ul>
              </div>
              
             <div id="annotation">
                  <h1>Annotations</h1>
                  Total usage: {count( $state?files?annotations)}
                   {
             let $ns-map:=map:merge(
                                  for $a in $state?files?annotations
                                  group by $uri:=$a?annotation?uri
                                   return map:entry($uri,$a)
                                 )
            
             for $ns in map:keys($ns-map)
             order by $ns
             return <section>
                      <h2>{ $ns }</h2>
                      <div>
                      {for $a in $ns-map?($ns)
                      group by $name:=$a?annotation?name
                      order by lower-case($name)
                      return <a href="annotations.html" class="badge badge-info" style="margin-right:1em;">{$name}
                               <span class="badge badge-light">{count($a)}</span>
                             </a>
                    }</div>
                   </section>
                }
              </div>
           </div>
return document{ page:wrap($d, $opts ) }
};

(:~ 
 : true if annotation found in set
 : @param $uri 1st item is uri, if 2nd then match name
 :)
declare function xqhtml:has-annot($annots as map(*)*,$uri as xs:string*)
as xs:boolean
{
  let $hit:=$annots?annotation[?uri=$uri[1]]
  return if(count($uri) eq 1) then
            count($hit)>0
         else
           count($hit[?name=$uri[2]])>0
};


(:~ tree to list :)
declare function xqhtml:tree-list($tree as element(*),$seq as xs:integer*){
  typeswitch ($tree )
  case element(directory) 
      return <li>
                 <span class="secno">{string-join($seq,'.')}</span>
                 <span class="content">{$tree/@name/string()}/</span>
                 <ol class="toc">{$tree/*!xqhtml:tree-list(.,($seq,position()))}</ol>
             </li>
   case element(file) 
      return <li>{if($tree/@target) then
                   <a href="#{$tree/@target}">
                     <span class="secno">{string-join($seq,'.')}</span>
                     
                      <span class="content" title="{$tree/@target}">{  $tree/@name/string() }</span>
                      <div class="badge badge-success" 
                            title="RESTXQ: {$tree/@target}">GET
                      </div>
                      <div class="badge badge-danger"  style="float:right"
                            title="RESTXQ: {$tree/@target}">X
                      </div>
                   </a>
               else 
                <span class="content">{$tree/@name/string()}</span>
             }</li>   
  default 
     return <li>unknown</li>
};

(:~
 : html for page. 
 :)
declare function xqhtml:restxq($state,$annots,$opts)
{
let $tree:=$annots?uri
let $tree:=tree:build($tree)
let $body:= <div>
          <nav id="toc">
            <h2>
                 <a href="index.html" class="badge badge-success">
                    { $state?project }
                </a>
                / RestXQ
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
                 <li  href="#main">
                    <a >
                        <span class="secno">2 </span>
                        <span class="content">Paths.</span>
                    </a>
                </li>
                <li>
      
                 <ol  class="toc"> { $tree/*/*!xqhtml:tree-list(.,2) } </ol>
                </li>
             </ol>
           </nav>
           <a href="index.html">index: </a>
          
           <ul>{$annots!xqhtml:path-to-html(.)}</ul>
           </div>
return  page:wrap($body,$opts)
};


(:~ import page :)
declare function xqhtml:imports($state,$imports,$opts)
{
  let $body:=<div>
   <nav id="toc">
            <h2>
                <a href="index.html" class="badge badge-success">
                    { $state?project }
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

(:~ annotations page :)
declare function xqhtml:annotations($state,$opts)
{
  let $ns-map:=map:merge(
          for $a in $state?files?annotations
          group by $uri:=$a?annotation?uri
           return map:entry($uri,$a)
         )
  let $body:=<div>
                 <h1>
                  <span class="badge badge-success">
                      { $opts?project }
                  </span>
                  &#160;Annotations 
              </h1>
               <nav id="toc">
                        <h2>
                            <a href="index.html" class="badge badge-success">
                                { $state?project }
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
           <a href="index.html">index</a>JJ
           <ul>{
             for $ns in map:keys($ns-map)
             return <li>{ $ns }</li>
           }</ul>
  </div>
  return  page:wrap($body,$opts)
};

(:~  html for a path :)          
declare function xqhtml:path-to-html($rep as map(*))
as element(li){
   <li id="{ $rep?uri }">
       <h4>{ $rep?uri }</h4>
       <ul>{
       let $methods as map(*) :=$rep?methods
       for $method in map:keys($methods)
       let $d:=$methods?($method)
       let $id:=head($d?function)
       return <li>
                    <a href="{$d?uri}index.html#{$id }">{ $method }</a>
                    <div>{$d?description}</div>
              </li>
       }</ul>
   </li>
};





(:~ views list with links :)
declare 
function xqhtml:view-list($opts as map(*),$exclude as xs:string*)                       
as element(dl)
{  
<dl>           
 {for $name in $opts?outputs?views
  where not($name eq $exclude)
  let $def:= map:get($opts?renderers?modules,$name)
  return (<dt><a href="{ $def?uri }">{ $name }</a></dt>
         ,<dd>{ $def?title }</dd>)
  }    
</dl>
};    