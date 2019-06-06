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
 : <p>annotation report</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace _ = 'quodatum:xqdoca.generator.annotations';


import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../xqdoc-anno.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~ annotations page :)
declare 
%xqdoca:global("annotations","Summary of Annotation use")
%xqdoca:output("annotations.html","html5") 
function _:annotations-XQDOCA($model,$opts)
{
  let $ns-map:=xqa:annotations-XQDOCA($model)
  let $body:=<div>
                 <h1>
                     Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;Annotations 
              </h1>
               <nav id="toc">
                        <h2>
                            <a href="index.html" >
                                { $model?project }
                            </a>
                            / Annotations
                        </h2>
           
            <h3>
               Contents
            </h3>
           {_:toc-XQDOCA(map:keys-XQDOCA($ns-map)=>sort())}
           </nav>
             {_:summary-XQDOCA($model,$opts)}
             <div class="div2">
                 <h2><a id="annotations"/>2 Annotations</h2>
                 <p>There are { map:size-XQDOCA($ns-map) } annotation namespaces in use.</p>
                 {
                 for $ns in map:keys-XQDOCA($ns-map)
                 order by $ns
                 count $c
                 return <div class="div3">
                            <h3><a id="{ $ns }"/>{page:section-XQDOCA((2,$c))} { $ns }</h3>
                            {sort(distinct-values($ns-map?($ns)?annotation?name)) 
                            !<span style="margin-left:1em" >
                            <a href="#{{{ $ns}}}{.}">{.}</a>
                             </span>}
                            {for $a in $ns-map?($ns)
                            group by $name:=$a?annotation?name
                            order by lower-case($name)
                            return _:anno-calls-XQDOCA($ns,$name,$a) 
                      } </div>       
           }</div>
      </div>
  return  page:wrap-XQDOCA($body,$opts)
};

declare function _:anno-calls($ns as xs:string, $name as xs:string,$a)
{
 <div class="div4">
     <h4><a id="{{{ $ns }}}{ $name }"/>{{{ $ns }}}{$name}
      <div style="float:right"><span class="badge badge-info">{count($a)}</span></div>
     </h4>
    
     <table class="data">
       <thead><tr>
         <th>Attached to</th>
         <th>Values</th>
       </tr></thead>
       <tbody>{
          for $a2 in $a
          return <tr>
                    <td>{
                       let $x:= xqa:name-detail-XQDOCA($a2?xqdoc/../..,$a2?file)
                       return if($x instance of map(*)) then 
                                page:link-function2-XQDOCA($x?uri,$x?name,$a2?file,false()) 
                              else 
                                ()
                     }</td>
                    <td>{ xqa:literals-XQDOCA($a2?xqdoc/xqdoc:literal) }</td>
                </tr>
       }</tbody>
     </table>
</div>        
};

declare function _:summary($model,$opts)
as element(div)
{
  <div class="div2">
    <h2><a id="summary"/>1 Summary</h2>
    <p>This document itemizes the use of annotations in this project.</p>
   { page:module-links-XQDOCA("global", "annotations", $opts) }    
 </div>
};

declare function _:toc($ns as xs:string*)
as element(ol)
{
 let $t:=<directory>
      <f target="#summary" name="Summary"/>
      <directory target="#annotations" name="Annotations">{
     $ns!<f target="#{.}" name="{.}" />
      }</directory>
     </directory>
 return <ol class="toc">
        {$t/*!page:tree-list-XQDOCA(.,position(),page:toc-render#2,99)}
        </ol>    
};


