xquery version "3.1";
(:~
  <p>Generate HTML describing the rest interface</p> 
  @copyright (c) 2019-2022 Quodatum Ltd
  @author Andy Bunce, Quodatum, License: Apache-2.0
 :)

module namespace _ = 'quodatum:xqdoca.generator.rest';

import module namespace tree = 'quodatum:data.tree' at "../lib/tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at "../lib/model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../lib/xqdoc-page.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../lib/annotations.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~
 : rest interface html for page. 
 :)
declare 
%xqdoca:global("restxq","Summary of REST interface")
%xqdoca:output("restxq.html","xhtml") 
function _:restxq($model,$opts)
{
let $annots as map(*)*:= xqd:rxq-paths($model)
let $tree:=$annots?uri
let $tree:=tree:build($tree)=>tree:flatten()

let $sections:=(
           _:summary($model, $opts, $tree),

           <section id="rest">
             <h2>Rest interface paths</h2>
             {$annots!_:path-report(.,(2,position()))}
           </section>
        )
let $body:= <div>
              <h1>
                 Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;RestXQ documentation 
              </h1>
            {_:toc($opts,$tree,$annots)}
            { $sections }
           </div>
return  page:wrap($body,$opts)
};


declare function _:summary($model,$opts, $tree as element(directory)?)
as element(section)
{
     <section id="summary">
        <h2>Summary</h2> 
        {if(exists($tree))
        then 
        <div>    
        <p>This document provides details of the RestXQ annotations. These provide mappings from Web endpoints to XQuery code.</p>
         <dl>
            <dt>Base path</dt>
            <dd>{ tree:base($tree) }</dd>
        </dl>
        </div> 
        else 
        <p>No RESTXQ usage</p>}
        { page:related-links("global","restxq",$opts) }
     </section>
};


(:~  html for a path
 :   $anot={uri:.., methods:{METHOD:annotation}, function:..}
 :)          
declare function _:path-report($anot as map(*),$pos)
as element(div)
{
 let $methods as map(*) :=$anot?methods 
 return <div class="div3">
       <h3><a id="{ page:id($anot?uri) }"/>{page:section($pos) } { $anot?uri }
       <div style="float:right;"><a href="#{ page:id($anot?uri) }">#</a></div></h3>
       
       {
       for $method in map:keys($methods)
       let $amap:=$methods?($method)
       return _:method($method,$amap,$anot)
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
         { xqa:badges($annots, $amap?file, page:badge#3) }
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
  return if(exists($names))
         then
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
  let $ns:=$amap?file?namespaces
  let $p:=filter($annots,xqa:is-rest(?,"produces",$ns))
  let $s:=filter($annots, xqa:is-out(?,"method",$ns))
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

(:~  toc 
@param $annots {url:{methods:}..}
:)
declare function _:toc($opts as map(*),$tree as element(directory)?,$annots as map(*)*)
as element(nav)
{
     <nav id="toc">
            <h2>
                 <a href="index.html">
                    { $opts?project }
                </a>
                / RestXQ
            </h2>
           {page:related-buttons("global","restxq", $opts) }
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
                { $tree/*!page:tree-list(.,(2,position()),_:toc-render(?,?,$annots),1) } 
             </ol>
           </nav>
};


(:~ generate TOC
@param $pos eg "2.7"
@param $el <file> or <directory>
@param $annots 
:)
declare function _:toc-render($pos as xs:string,$el as element(*),$annots as map(*)*)
as element(*)*
{
let $target:= $el/@target  
let $label:=$el/head((@target,@name))=>_:rxpath("drop-pattern")
let $c:=(
<span class="secno">{$pos}</span>,
<span class="content">{ $label }</span>
)
return if($target) then
 <a href="#{ page:id($el/@target) }">
 { $c }
 <div  style="float:right;font-size:75%" title="RESTXQ methods">
 {let $methods:=$annots[?uri=$target]?methods
  return if($methods instance of map(*)) then map:keys($methods)!page:badge-method(.)}
 </div>
  </a>
else
 $c
};

(:~ annotation details :)
declare function _:annotations($annots as element(xqdoc:annotation)*)
as element(*)
{
		<details>
			<summary>Annotations ({ count($annots) })</summary>
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
 :  o/p table of parameters,wrapped in dd item
 :)
 declare function _:params($annots as element(xqdoc:annotation)*,
                                $name as xs:string,
                                $title as xs:string,
                                $amap as map(*))
as element(*)*
{
  let $aq:=filter($annots,xqa:is-rest(?,$name,$amap?file?namespaces))
  return if($aq) then 
  (<dt>{ $title }</dt>,
         <dd>
         <table class="data">
         <thead><tr>
            <th>Name</th><th>Type</th><th>Description</th><th>Default</th>
          </tr></thead>
         <tbody>
         {for $a in $aq
        (:  let $a:=trace($a,"A:") :)
          let $p:=$a/xqdoc:literal/string()
          
          let $name:=fn:replace($p[2],"\{\s*\$(\w*)\s*\}","$1") (: =>trace("NAME: ") :)
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

(:~ restxq path manipulations
 :)
declare function _:rxpath($path as xs:string,$action as xs:string)
as xs:string{
switch ($action)
(: "/locks/{$ctype}/{$cid=.+}/{$coid=.+}" -> '/locks/ctype/{$cid=.+}/{$coid=.+}' :)
case "name" 
     return fn:replace($path,"\{\s*\$(\w*)\s*\}","$1")

(: "/locks/{$ctype}/{$cid=.+}/{$coid=.+}" -> '/locks/{$ctype}/{$cid}/{$coid}' :)
case "drop-pattern"  
     return fn:replace($path,"\{\s*(\$\w*)=[^}]*\}","{$1}") 

default
   return error("unknown action: " || $action)
};
