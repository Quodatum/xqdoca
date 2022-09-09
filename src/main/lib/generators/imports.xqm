xquery version "3.1";
(: Copyright (c) 2019-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
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
%xqdoca:output("imports.html","xhtml") 
function _:imports($model,$opts)
{
  let $imports:=xqd:imports($model)
  let $sections:=(
             _:summary($model,$opts),
              <section  id="imports">
                 <h2>{ ``[Imports (`{ map:size($imports) }`)]`` }</h2>
                 {
                 for $ns in map:keys($imports)
                 order by $ns
                 return  _:by-ns($ns,$imports?($ns))
                 }
              </section>
  )
  let $links:= page:related-buttons("global","imports", $opts) 
  let $body:=<div>
     <h1>Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;Imports 
              </h1>

            {page:toc($opts?project,$sections,$links), 
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
    { page:related-links("global","imports", $opts) }
 </section>
};
