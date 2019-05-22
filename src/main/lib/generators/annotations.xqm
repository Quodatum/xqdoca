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
module namespace _ = 'quodatum:xqdoca.generator.annotations';


import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~ annotations page :)
declare 
%xqdoca:global("annotations","Summary of Annotation use")
%xqdoca:output("annotations.html","html5") 
function _:annotations($model,$opts)
{
  let $ns-map:=map:merge(
          for $a in $model?files?annotations
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
                                { $model?project }
                            </a>
                            / Annotations
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
                 <li>
                    <a href="#annotations">
                        <span class="secno">2 </span>
                        <span class="content">Annotations</span>
                    </a>
                </li>
             </ol>
           </nav>
             {_:summary($model,$opts)}
             <div class="div2">
                 <h2><a id="annotations"/>2 Annotations</h2>
                 <ul>{
                 for $ns in map:keys($ns-map)
                 return <li>{ $ns }</li>
               }</ul>
             </div>       
  </div>
  return  page:wrap($body,$opts)
};

declare function _:summary($model,$opts)
as element(div)
{
  <div class="div2">
    <h2><a id="summary"/>1 Summary</h2>
    <p>This page itemizes the use of annotations in this project.</p>
    <p>Other perspectives:</p>
   { page:view-list( $opts(".renderers")?global,"annotations")}
 </div>
};
    