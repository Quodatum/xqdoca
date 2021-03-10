xquery version "3.1";
(:
 : Copyright (c) 2019-2020 Quodatum Ltd
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
module namespace _ = 'quodatum:xqdoca.generator.imports';

import module namespace tree = 'quodatum:data.tree' at "../tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../xqdoc-anno.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~ import page :)
declare 
%xqdoca:global("imports","Summary of import usage")
%xqdoca:output("imports.html","html5") 
function _:imports($model,$opts)
{
  let $imports:=xqd:imports($model)
  let $sections:=(
             _:summary($model,$opts),
             _:related($model,$opts),
              <section  id="annotations">
                 <h2>Namespaces</h2>
                 <p>There are { map:size($imports) } imported namespaces.</p>
                       {
               for $ns in map:keys($imports)
                 order by $ns
                 return  _:by-ns($ns,$imports?($ns))
                 }
              </section>
  )
  let $body:=<div>
     <h1>Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;Imports 
              </h1>

            {page:toc($opts?project,$sections), 
            $sections}    
       </div>
  return  page:wrap($body,$opts)
};


declare function _:by-ns($ns,$files){
   <div class="div3" >
           <h3><a id="{ $ns }"/>{ $ns } <small> is imported by </small>
           <div  style="float:right"><a href="#{ $ns }">#</a></div>
           </h3>
           <ul>
           {for $f in  $files
           return <li><a href="{$f?href}index.html">{ $f?namespace || ' @ ' || $f?path }</a> </li>
         }
           </ul>
           </div>
};

declare function _:summary($model,$opts)
as element(section)
{
  <section id="summary">
    <h2>Summary</h2>
    <p>Lists all modules imported.</p>
 </section>
};

declare function _:related($model,$opts)
as element(section)
{
  <section id="related">
    <h2>Related documents</h2>
   { page:view-list("global", $opts,"imports")}
 </section>
};