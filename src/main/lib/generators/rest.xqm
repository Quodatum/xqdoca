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
 : Generate RESTXQ XQuery  documentation in html
 :)
module namespace _ = 'quodatum:xqdoca.generator.rest';

import module namespace tree = 'quodatum:data.tree' at "../tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~
 : rest interface html for page. 
 :)
declare 
%xqdoca:global("restxq","Summary of REST interface")
%xqdoca:output("restxq.html","html5") 
function _:restxq($model,$opts)
{
let $annots:= xqd:rxq-paths($model) 
let $tree:=$annots?uri
let $tree:=tree:build($tree)
let $body:= <div>
              <h1>
                 Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;RestXQ documentation 
              </h1>
            {_:toc($model,$tree)}
            {_:summary($model,$opts)}
           <div class="div2">
             <h2><a id="rest"/>2 Rest interface paths</h2>
             <ul>{$annots!_:path-to-html(.)}</ul>
           </div>
           </div>
return  page:wrap($body,$opts)
};

declare function _:summary($model,$opts)
as element(div)
{
  <div class="div2">
    <h2><a id="summary"/>1 Summary</h2>
    <p>This page summaries the rest interface.</p>
    <p>Other perspectives:</p>
   { page:view-list( $opts(".renderers")?global,"restxq")}
 </div>
};

(:~  html for a path :)          
declare function _:path-to-html($rep as map(*))
as element(div)
{
  <div class="div4">
       <h4><a id="{ $rep?uri }"/>{ $rep?uri }</h4>
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
   </div>
};

(:~  toc :)
declare function _:toc($model as map(*),$tree)
as element(nav)
{
     <nav id="toc">
            <h2>
                 <a href="index.html" class="badge badge-success">
                    { $model?project }
                </a>
                / RestXQ
            </h2>
           <h3>
               Contents
            </h3>
            <ol class="toc">
                <li>
                    <a href="#summary">
                        <span class="secno">1 </span>
                        <span class="content">Summary</span>
                    </a>
                </li>
                 <li  >
                    <a href="#rest">
                        <span class="secno">2 </span>
                        <span class="content">Rest Paths</span>
                    </a>
                </li>
                <li>
      
                 <ol  class="toc"> { $tree/*/*!page:tree-list(.,2) } </ol>
                </li>
             </ol>
           </nav>
};