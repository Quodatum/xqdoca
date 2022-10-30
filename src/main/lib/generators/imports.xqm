xquery version "3.1";
(:~
 : <p>generate html import summary</p>
 : @Copyright (c) 2019-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
 :)

module namespace _ = 'quodatum:xqdoca.generator.imports';

import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";

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

            { (:page:toc($opts?project,$sections,$links) :) }
            <nav id="toc">
                        <h2>
                            <a href="index.html" >
                                { $opts? project }
                            </a>
                            / Imports
                        </h2>
              { $links}
                <h3>
                  Contents
                </h3>
              { _:toc(map:keys($imports) => sort())}
              </nav> 
            { $sections}    
       </div>
  return  page:wrap($body,$opts)
};

(:~
@param $ns namespace
@param $files 
:)
declare function _:by-ns($ns as xs:string,
                         $files as map(*)*)
{
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

(:~ table of contents as list from namespace list :)
declare function _:toc($imports as xs:string*)
as element(ol)
{
 let $t:=<directory>
      <f target="#summary" name="Summary"/>
      <directory target="#imports" name="Imports {count($imports)}">{
     $imports!<f target="#{.}" name="{.}" />
      }</directory>
     </directory>
 return <ol class="toc">
        {$t/*!page:tree-list(.,position(),page:toc-render#2,99)}
        </ol>    
};
