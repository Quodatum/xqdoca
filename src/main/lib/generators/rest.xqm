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
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../xqdoc-anno.xqm";
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
            {_:summary($model, $opts, $tree)}
           <div class="div2">
             <h2><a id="rest"/>2 Rest interface paths</h2>
             {$annots!_:path-report(.,(2,position()))}
           </div>
           </div>
return  page:wrap($body,$opts)
};


declare function _:summary($model,$opts, $tree)
as element(div)
{
    let $base:=tree:base($tree)
    return <div class="div2">
        <h2><a id="summary"/>1 Summary</h2>      
        <p>This document summaries the RestXQ interface.</p>
      { page:module-links("global", "restxq", $opts) }    
         <dl>
            <dt>Base path</dt>
            <dd>{ $base }</dd>
        </dl>
     </div>
};

(:~  html for a path
 :   $rep={uri:.., methods:{METHOD:annotation}, function:..}
 :)          
declare function _:path-report($rep as map(*),$pos)
as element(div)
{
 let $methods as map(*) :=$rep?methods 
 return <div class="div3">
       <h3><a id="{ page:id($rep?uri) }"/>{page:section($pos) } { $rep?uri }
       <div style="float:right;"><a href="#{ page:id($rep?uri) }">#</a></div></h3>
       
       {
       for $method in map:keys($methods)
       let $amap:=$methods?($method)
       return _:method($method,$amap,$rep)
       }
   </div>
};

(:~  method entry :)
declare function _:method($method as xs:string,$amap as map(*),$rep as map(*))
as element(div)
{
  let $annots:=$amap?xqdoc//xqdoc:annotation
  
  return <div>
    <h4>
        <a id="{ $rep?uri}#{ $method}"/>
        <a href="#{ $rep?uri}#{ $method}">{ page:badge-method($method)}</a> &#160;
         { $rep?uri }
         <div style="float:right">
         { xqa:badges($annots,$amap?file) }
       </div> 
    </h4>
    <dl>
    <dt>Description</dt>
    <dd><p>{$amap?description}</p>
      {  page:link-function2($amap?uri, $amap?name, $amap?file, false())  }
    </dd>
    {_:outputs($annots,$amap)}
    { _:url-params($rep?uri,$amap) }
    { _:params($annots,"query-param","Query parameters",$amap) }
    { _:params($annots,"form-param","Form parameters",$amap) }
    { _:params($annots,"header-param","Header parameters",$amap) }
    </dl>
    { _:annotations($annots) }
  </div>
};

(:~  output form :)
declare function _:url-params($url as xs:string, 
                           $amap as map(*))
as element(*)*
{
  let $names:=xqa:extract-restxq($url)!substring-before(. || "=","=")
  let $function:=$amap?annot/../..
  return if($names)then
  (<dt>Url parameters</dt>,
  <dd>
  <table class="data">
    <thead><tr><th>Name</th><th>Description</th></tr></thead>
    <tbody>{ 
    for $name  in $names
    let $desc:=page:comment-for($name,$function/xqdoc:parameters)
    return <tr><td>{$name}</td><td>{$desc}</td></tr>
  }
    </tbody>
  </table>
  </dd>)
  else
   ()
};
(:~  output form :)
declare function _:outputs($annots as element(xqdoc:annotation)*, 
                           $amap as map(*))
as element(*)*
{
  let $ns:=$amap?file?prefixes
  let $p:=filter($annots,xqa:is-rest("produces",?,$ns))
  let $s:=filter($annots, xqa:is-out("method",?,$ns))
  return if ($p or $s)then
       (<dt>Output</dt>,
        <dd>{if($s)then
           <div>Serialization: {$s/xqdoc:literal/string()}</div>
          else
            ()
        }{if($p)then
           <div>Produces: { $p/xqdoc:literal/string()}</div>
          else
            ()
        }  
        </dd>)
    else
        ()
};

(:~  toc :)
declare function _:toc($model as map(*),$tree)
as element(nav)
{
     <nav id="toc">
            <h2>
                 <a href="index.html">
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
                { $tree/*/*!page:tree-list(.,(2,position()),_:toc-render#2,1) } 
             </ol>
           </nav>
};


declare function _:toc-render($pos as xs:string,$el as element(*))
as element(*)*
{
let $c:=(
<span class="secno">{$pos}</span>,
<span class="content">{$el/@name/string()}</span>
)
return if($el/@target) then
 <a href="#{ page:id($el/@target) }">
 { $c }
 <div class="badge badge-info"  style="float:right" title="RESTXQ: {$el/@target}"></div>
  </a>
else
 $c
};

(:~ annotation details :)
declare function _:annotations($annots as element(xqdoc:annotation)*)
as element(*)
{
		<details>
			<summary>Annotations</summary>
			<table class="data">
				<tbody>{ 
       for $a in $annots
       return 	
             <tr>
                <td>
                  <code class="function">%{ $a/@name/string() }</code>
                </td>
                <td>
                  <code class="arg">{ xqa:literals($a/xqdoc:literal) }</code>
                </td>
              </tr>
    }</tbody>
			</table>
		</details>
};

(:~
 :  
 :)
 declare function _:params($annots as element(xqdoc:annotation)*,
                                $name as xs:string,
                                $title as xs:string,
                                $amap as map(*))
as element(*)*
{
  let $aq:=filter($annots,xqa:is-rest($name,?,$amap?file?prefixes))
  return if($aq) then 
  (<dt>{ $title }</dt>,
         <dd>
         <table class="data">
         <thead><tr>
            <th>Name</th><th>Type</th><th>Description</th><th>Default</th>
          </tr></thead>
         <tbody>
         {for $a in $aq
          let $p:=$a/xqdoc:literal/string()
          let $name:=xqa:extract-restxq($p[2])=>trace("NAME: ")
          let $fn:=$amap?annot/../..
          let $desc:=page:comment-for($name,$fn/xqdoc:parameters)
          let $type:=$fn/xqdoc:parameters/xqdoc:parameter[xqdoc:name=$name]/xqdoc:type/concat(.,@occurrence)
          return <tr>
             <td>{$name}</td>
             <td>{ $type} </td>
             <td>{ $desc }</td>
             <td>{$p[3]}</td>
             </tr>}
         </tbody>
         </table>
         </dd>)
      else 
      ()
};

