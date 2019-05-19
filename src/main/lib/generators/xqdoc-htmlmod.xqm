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
 : <h1>xqdoc-htmlmod.xqm</h1>
 : <p>Library to support html5 rendering of single xqdoc source</p>
 :
 : @author Andy Bunce
 : @version 0.1
 : @see https://github.com/Quodatum/xqdoca
 :)
 
(:~
 : Generate  html for xqdoc
 :)
module namespace xqh = 'quodatum:xqdoca.mod-html';
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";

declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare namespace xsl="http://www.w3.org/1999/XSL/Transform";
 
(:~ transform xqdoc to html 
 : <pre>map { "root": "../../", 
 :        "cache": false(), 
 :        "resources": "resources/", 
 :        "ext-id": "51", 
 :        "filename": "src\main\lib\parsepaths.xq", 
 :        "show-private": true(), 
 :        "src-folder": "C:/Users/andy/git/xqdoca", 
 :         "project": "xqdoca", 
 :         "source": () }</pre> 
 :)
declare 
%xqdoca:module("module","Html5 report on the XQuery source")
%xqdoca:output("index.html","html5")
function xqh:xqdoc-html2($file as map(*),
                            $opts as map(*),
                            $state as map(*)
                            )
as document-node()                         
{
let $xqd:=$file?xqdoc 
let $d:=<div>{
         xqh:summary($xqd/xqdoc:module,$opts),
         xqh:toc($xqd,$opts,$file),
         xqh:imports($xqd/xqdoc:imports,$state), 
         xqh:variables($xqd/xqdoc:variables),
         xqh:functions($xqd/xqdoc:functions),
         xqh:when($xqd/xqdoc:namespaces[xqdoc:namespace],xqh:namespaces#1),
         xqh:restxq($xqd),
          <div class="div2">
            <h2 ><a id="source"/>7 Source Code</h2>
            <pre><code class="language-xquery">{ $xqd/xqdoc:module/xqdoc:body/string() }</code></pre>
          </div>
       }</div>

 return document{ page:wrap($d, $opts )  }                 
};

declare function xqh:summary($mod as element(xqdoc:module),
                            $opts as map(*)
                            )
 {
   let $restxq:= true()
   return(	<h1>
			<span class="badge badge-info">{ $mod/xqdoc:uri/string() }</span>&#160;
			<small>{ $mod/@type/string() } module</small>
     { if($restxq) then
          <span  title="RestXQ" class="badge badge-success" style="float:right">R</span>
        else ()  
       }
      {if($mod//xqdoc:annotations/xqdoc:annotation[@name='updating']) then
              <div class="badge badge-danger" title="Updating" style="float:right">U</div>
        else
        ()
      }
		</h1>,
    
		<dl>
		{xqh:when($mod/xqdoc:comment/xqdoc:description,xqh:description#1) }
			<dt>Tags</dt>
			<dd>
			{xqh:tags($mod/xqdoc:comment/(* except xqdoc:description)) }
			</dd>
		</dl>,
		<div> Imported by <a href="{ $opts?root }imports.html#{ $mod/xqdoc:uri/string() }">*</a></div>,
    <ul>
     <li style="display:inline">Raw XML files: </li>
     <li style="display:inline"><a href="xqdoc.xml" target="xqdoc">xqdoc.xml</a>, </li>
     <li style="display:inline"><a href="xqparse.xml" target="xqparse">xqparse.xml</a></li>
     </ul>
  )
  };
  
declare function xqh:toc($xqd,$opts,$file)
as element(nav){
  let $vars:=$xqd//xqdoc:variable[$opts?show-private or not(xqdoc:annotations/xqdoc:annotation/@name='private')]
  let $funs:=$xqd//xqdoc:function[$opts?show-private or not(xqdoc:annotations/xqdoc:annotation/@name='private')]
	return	<nav id="toc">
			<h2>
			    <a href="{ $opts?root || "index.html" }" >{ $opts?project }</a>
                / Module
       </h2>
			<h3>
				<a id="contents"></a>
				<span class="">{ $xqd/xqdoc:module/xqdoc:uri/string() }</span>
			</h3>
			<ol class="toc">
				<li>
					<a href="#main">
						<span class="secno">1 </span>
						<span class="content">Introduction</span>
					</a>
				</li>
				<li>
          <a href="#imports">
            <span class="secno">2 </span>
            <span class="content">Imports</span>
          </a>
        </li>
				<li>
					<ol class="toc">
						<li>
							<a href="#variables">
								<span class="secno">3 </span>
								<span class="content">Variables</span>
							</a>
							<ol class="toc">
              {for $var  in $vars
              order by $var/xqdoc:name
              let $id:=concat('$',$var/xqdoc:name)
              count $pos
              return
									<li>
										<a href="#{$id}">
											<span class="secno">{ concat('3.',$pos) }</span>
											<span class="content">{ $id }</span>
										</a>
									</li>
							}
							</ol>
						</li>
					</ol>
				</li>
				<li>
					<ol class="toc">
						<li>
							<a href="#functions">
								<span class="secno">4 </span>
								<span class="content">Functions</span>
							</a>
							<ol class="toc">
                {for $fun  in $funs
              group by $name:=$fun/xqdoc:name
              order by $name
              let $restxq:=true()
              let $update:=true()
              count $pos
              return
									<li>
										<a href="#{$name}">
											<span class="secno">{ concat('4.',$pos[1]) }</span>
											<span class="content" title="{$fun[1]/xqdoc:description/string()}">{ $name }
                      {if($restxq) then 
                        <div class="badge badge-success" style="float:right"	title="RESTXQ:">R</div>
                      else
                        ()}
                       {if($update) then 
                        <div class="badge badge-danger" style="float:right"	title="Updating">U</div>
                      else
                        ()}  
                      </span>
										</a>
									</li>
							}
							
							</ol>
						</li>
					</ol>

				</li>
				<li>
					<a href="#namespaces">
						<span class="secno">5 </span>
						<span class="content">Namespaces</span>
					</a>
				</li>
				<li>
					<ol class="toc">
						<li>
							<a href="#restxq">
								<span class="secno">6 </span>
								<span class="content">Restxq</span>
							</a>
							<ol class="toc">
              
								<xsl:for-each-group select="qd:restxq($funs)"
									group-by="doc:literal/string()">
									<xsl:sort select="current-grouping-key()" />
									<xsl:variable name="id" select="current-grouping-key()" />
									<li>
										<a href="# TODO">
											<span class="secno">
												<xsl:value-of select="concat('5.',position())" />
											</span>
											<span class="content">
												<xsl:value-of select="current-grouping-key()" />
											</span>
										</a>
									</li>
								</xsl:for-each-group>
							</ol>
						</li>
					</ol>

				</li>
       	<li>
					<a href="#source">
						<span class="secno">7 </span>
						<span class="content">Source</span>
					</a>
				</li> 
			</ol>
		</nav>
};   

declare function xqh:imports($imports as element(xqdoc:imports),$state as map(*))
as element(div){
    
    <div class="div2">
    <h2><a id="imports"/>2 Imports</h2>
    <p> { count($imports/xqdoc:import) } modules are imported by this module and {"?"} import this module.</p>
    <details>
      <table class="data" style="float:none">
        <thead>
          <tr>
            <th>Type</th>
            <th>Uri</th>
          </tr>
        </thead>
        <tbody>
        {for $import in $imports/xqdoc:import
        order by lower-case($import/xqdoc:uri)
        return 
            <tr>
              <td>{ $import/@type/string() }</td>
              <td>{ page:link-module($import/xqdoc:uri/string(),$state) }
               
              </td>
            </tr>
       }
        </tbody>
      </table>
      </details>
    </div>
}; 

declare function xqh:variables($vars as element(xqdoc:variables))
as element(div)
{
  <div class="div2">
			<h2>
				<a id="variables"/>3 Variables
			</h2>
		{for $v in $vars/xqdoc:variable
      order by  lower-case($v/xqdoc:name)
      count $index
	   return xqh:variable($v,(3,$index)),
     if(empty( $vars/xqdoc:variable)) then <p>None</p> else ()
   }
		</div>
};

declare function xqh:variable($v as element(xqdoc:variable),$section as xs:anyAtomicType*)
as element(div)
{
let $id:= concat('$',$v/xqdoc:name)
let $summary:= $v/xqdoc:comment/xqdoc:description/(node()|text())
return
		<div class="div3">
			<h3><a id="{$id }"/>{ page:section($section) } {$id }</h3>
			<dl>
        <dt class="label">Summary</dt>
		   <dd>{ $summary }</dd>
				<dt class="label">Type</dt>
				<dd>{ $v/xqdoc:type/string() }	{ $v/xqdoc:type/@occurrence/string() }</dd>
			</dl>
      {xqh:tags($v/xqdoc:comment/(* except xqdoc:description)) }
      { xqh:when($v/xqdoc:annotation,xqh:annotations#1) }
		</div>
};  

declare function xqh:functions($funs as element(xqdoc:functions))
as element(div)
{
  <div class="div2">
			<h2><a id="functions"/>4 Functions</h2>
		{ for $f in $funs/xqdoc:function
      order by  lower-case($f/xqdoc:name)
      count $pos
	   return xqh:function($f,(4,$pos)),
      if(empty( $funs/xqdoc:function)) then <p>None</p> else ()
   }
		</div>
};

(:~   o/p details for function $funs has all defined arities
 :)
declare function xqh:function($funs as element(xqdoc:function)*,$section as xs:anyAtomicType*)
as element(div)
{
		let $id:=$funs[1]/xqdoc:name/string()
	  return
		<div class="div3">
			<h3><a id="{$id}"/>{ page:section($section) } { $id }
			  <div style="float:right">
				<a href="#{$id}" >#</a>
				</div>
			</h3>

		{ xqh:when ($funs/xqdoc:comment/xqdoc:description[1],xqh:description#1) }
			<dt class="label">Signature</dt>
			<dd>
			{$funs!xqh:function-signature(.) }
			</dd>
			{ $funs[1]/xqdoc:parameters!xqh:parameters(.) } 
	    { $funs[1]/xqdoc:return!xqh:return(.) }
		  { $funs[1]/xqdoc:comment/xqdoc:error!xqh:error(.) }
       {xqh:tags($funs/xqdoc:comment/(* except xqdoc:description)) }
      { $funs/xqdoc:annotations!xqh:annotations(.) }
      
      { xqh:when ($funs/xqdoc:invoked,xqh:invoked#1) }
     
       <details>
      <summary>External functions that invoke this function</summary>
      todo
      </details>
       <details>
      <summary>Source</summary>
      { $funs! <pre><code class="language-xquery">{ xqdoc:body/string() }</code></pre> }
      </details>
		</div>
};

(:~ 
 :
 :)
declare function xqh:invoked($invoked as element(xqdoc:invoked)*)
{
 let $msg:= ``[References `{ count($invoked) }` functions from `{ count(distinct-values($invoked/xqdoc:uri)) }` modules ]``
 return <details>
      <summary>{ $msg }</summary>
      <table class="data">
      <thead>
      <tr>
      <td>Type</td>
      <td>uri</td>
      <td>Name</td>
      </tr>
      </thead>
      <tbody>
      {for $i in $invoked
      order by $i/xqdoc:uri,$i/@arity
      return <tr>
      <td>Fn</td>
       <td>{ $i/xqdoc:uri/string() }</td>
       <td>{ $i/xqdoc:name/string() || "#" || $i/@arity }</td>
       </tr>
    }
      </tbody>
      </table>
      </details> 
};

declare function xqh:custom($v as element(xqdoc:custom))
as element(p)
{
		<p>{ $v/@tag/string() }: { $v/* }</p>
};

(:~ 
 :The @see tag provides the ability to hypertext link to an external web site, a library or main module contained in xqDoc, 
 :a specific function (or variable) defined in a library or main module contained in xqDoc, or arbitrary text. To link to  
 :an external site, use a complete URL such as http://www.xquery.com. To link to a library or main module contained in  
 :   
 :xqDoc, simply provide the URI for the library or main module. To link to a specific function (or variable) defined in an 
 :xqDoc library or main module, simply provide the URI for the library or main module followed by a ';' and finally the     
 :function or variable name. To provide a name for a link, simply include a second ';' followed by the name. To provide     
 :text, simply include the 'text'. Multiple @see tags can be specified (one per link or string of text). 
 : @see http://www.xquery.com
 : @see xqdoc/xqdoc-display
 : @see xqdoc/xqdoc-display;build-link
 : @see xqdoc/xqdoc-display;$months
 : @see xqdoc/xqdoc-display;$months;month variable
 : @see http://www.xquery.com;;xquery
 : @see some text
 :)
declare function xqh:see($v as element(xqdoc:see))
as element(p)
{
  let $items:=tokenize($v,";")
  let $first:=$items[1]
  return  <p>See also:
          {switch(true())
          case count($items) eq 3 return <a href="{ $first }">{ $items[3] }</a>
          case count($items) eq 2 return <a href="{ $first }#{ $items[2] }">{ $items[2] }</a>
          default return if(xqh:is-url($first)) then <a href="{ $first }">{ $first }</a> else $first
        }</p>
};
  
declare function xqh:annotations($v as element(xqdoc:annotations))
as element(*)
{
		<details>
			<summary>Annotations</summary>
			<table class="data">
				<tbody>{ 
       for $a in $v/xqdoc:annotation
       return 	
             <tr>
                <td>
                  <code class="function">%{ $a/@name/string() }</code>
                </td>
                <td>
                  <code class="arg">{ $a/xqdoc:literal }</code>
                </td>
              </tr>
    }</tbody>
			</table>
		</details>
};

(:~ 
 :true() if $url represents a url
 :@see http://urlregex.com/ 
 :)
declare function xqh:is-url($url as xs:string)
as xs:boolean
{
  matches($url,"^(https?|ftp|file)://[-a-zA-Z0-9+&amp;@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&amp;@#/%=~_|]","j")
};


declare function xqh:namespaces($namespaces as element(xqdoc:namespaces))
as element(div)
{
     <div class="div2">
			<h2><a id="namespaces"/>5 Namespaces</h2>
			<p>The following namespaces are defined:</p>
			<table class="data" style="float:none">
				<thead>
					<tr>
						<th>Prefix</th>
						<th>Uri</th>
					</tr>
				</thead>
				<tbody>{ 
        for $ns in $namespaces/xqdoc:namespace
					order by lower-case($ns/@prefix)
          return
						<tr>
							<td>{string($ns/@prefix) }</td>
							<td>{ string($ns/@uri) }</td>
						</tr>
			}</tbody>
			</table>
		</div>
};

declare function xqh:parameters($v as element(xqdoc:parameters))
as element(*)*
{
	<dt class="label">Parameters</dt>,
		<dd>
			<ul>{
         for $p in $v/xqdoc:parameter
         return 	<li>
                    { $p/xqdoc:name/string() }
                    <code class="as">&#160;as&#160;</code>
                    <code class="return-type">
                      { $p/xqdoc:type/string() }
                      { $p/xqdoc:type/@occurrence/string() }
                    </code>
                    { let $name:=string($p/xqdoc:name)
                    for $comment in $v/../xqdoc:comment/xqdoc:param[
                                                             starts-with(normalize-space(.), $name) or 
                                                             starts-with(normalize-space(.), concat('$',$name))
                                                           ]
                    return substring-after(normalize-space($comment), $name) 
                   }
                </li>
    }</ul>
		</dd>
};

declare function xqh:return($v as element(xqdoc:return))
as element(*)*
{
		<dt class="label">Return</dt>,
		<dd>
			<ul>
				<li>
					<code class="return-type">
					{ $v/xqdoc:type/string() }
					{ $v/xqdoc:type/@occurrence/string() }
					</code>
					{for $comment in $v/xqdoc:comment/xqdoc:return
					return $comment/(node()|text())
        }
				</li>
			</ul>
		</dd>
};
 
declare function xqh:error($v as element(xqdoc:error))
{
		<dt class="label">Error</dt>,
		<dd>
		{ $v/(node()|text()) }
		</dd>
};

declare function xqh:function-signature($v as element(xqdoc:function))
as element(div){
		<div class="proto">
			<code class="function">{ $v/xqdoc:name/string() }</code>
		  ( 
			{for $p in $v/xqdoc:parameters/xqdoc:parameter
			return	(
        <code class="arg">${ $p/xqdoc:name/string() }</code>,
				<code class="as">&#160;as&#160;</code>,
				<code class="type">{ $p/xqdoc:type/string() }	{ $p/xqdoc:type/@occurrence/string() }</code>,
			  if(not($p is $v/xqdoc:parameters/xqdoc:parameter[last()] )) then ", " else () 
		)}
	 )
			<code class="as">&#160;as&#160;</code>
			<code class="return-type">
			{ $v/xqdoc:return/xqdoc:type }
			{ $v/xqdoc:return/xqdoc:type/@occurrence/string() }
			</code>
      
		</div>
};
	
declare function xqh:description($v as element(xqdoc:description))
as element(*)*{
  		<dt class="label">Summary</dt>,
		<dd>
			{ $v/(node()|text()) }
		</dd>
};

declare function xqh:tags($tags as element(*)*)
{
 for $tag in $tags return
typeswitch ($tag)
  case element (xqdoc:see) return	xqh:see($tag)
  case element (xqdoc:author) return	<p>Author: {string($tag)}</p>
  case element (xqdoc:version) return<p>Version: {string($tag)}</p>
  case element (xqdoc:custom) return<p>{ $tag/@tag/string()} : {string($tag)}</p>  
  default return()
};
 
declare function xqh:restxq($xqd)
as element(div)
{
   <div class="div2">
			<h2><a id="restxq"/>6 RestXQ</h2>
      <p>TODO</p>
    </div>
};

(:~ run function when value is non empty :)
declare function xqh:when($value,$fun as function(*))
{
 if($value) then $fun($value) else ()
};
