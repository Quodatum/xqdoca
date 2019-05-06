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
 :)
 
(:~
 : Generate  html for xqdoc
 :)
module namespace xqh = 'quodatum:xqdoca.mod-html';


declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xsl="http://www.w3.org/1999/XSL/Transform";
 
(:~ transform xqdoc to html 
 : map { "root": "../../", 
 :        "cache": false(), 
 :        "resources": "resources/", 
 :        "ext-id": "51", 
 :        "filename": "src\main\lib\parsepaths.xq", 
 :        "show-private": true(), 
 :        "src-folder": "C:/Users/andy/git/xqdoca", 
 :         "project": "xqdoca", 
 :         "source": () } 
 :)
declare function xqh:xqdoc-html2($xqd as element(xqdoc:xqdoc),
                            $params as map(*)
                            )
as element()*                          
{  
 let $_:=trace($xqd, "EEE")
 return (
   xqh:module($xqd/xqdoc:module,$params),
   xqh:toc($xqd,$params),
   xqh:imports($xqd/xqdoc:imports),
   xqh:variables($xqd/xqdoc:variables),
   xqh:functions($xqd/xqdoc:functions),
   xqh:when($xqd/xqdoc:namespaces[xqdoc:namespace],xqh:namespaces#1),
   xqh:restxq($xqd),
  
   if($xqd//xqdoc:import) then xqh:imports($xqd//xqdoc:imports) else (),
      <div>
        <h3 id="source">Original Source Code</h3>
        <pre><code class="language-xquery">{ $xqd/xqdoc:module/xqdoc:body/string() }</code></pre>
      </div>
  )                  
};

declare function xqh:module($mod as element(xqdoc:module),
                            $opts as map(*)
                            )
 {
   let $restxq:= true()
   return(	<h1>
			<span class="tag tag-success">{ $mod/xqdoc:uri/string() }</span>
			<small>{ $mod/@type/string() } module</small>
     { if($restxq) then
          <span  title="RestXQ" class="tag tag-success" style="float:right">R</span>
        else ()  
       }
      {if($mod//xqdoc:annotations/xqdoc:annotation[@name='updating']) then
              <div class="tag tag-danger" title="Updating" style="float:right">U</div>
        else
        ()
      }
		</h1>,
    <ul>
     <li style="display:inline">Raw XML files: </li>
     <li style="display:inline"><a href="xqdoc.xml" target="xqdoc">xqDoc</a>, </li>
     <li style="display:inline"><a href="xqparse.xml" target="xqparse">xqParse</a></li>
     </ul>,
		<dl>
		{xqh:when($mod/xqdoc:comment/xqdoc:description,xqh:description#1) }
			<dt>Tags</dt>
			<dd>
			{xqh:tags($mod/xqdoc:comment/(* except xqdoc:description)) }
			</dd>
		</dl>,
		<div> Imported by <a href="{ $opts?root }imports.html#{ $mod/xqdoc:uri/string() }">*</a></div>
  )
  };
  
declare function xqh:toc($xqd,$opts)
as element(nav){
  let $vars:=$xqd//xqdoc:variable[$opts?show-private or not(xqdoc:annotations/xqdoc:annotation/@name='private')]
  let $funs:=$xqd//xqdoc:function[$opts?show-private or not(xqdoc:annotations/xqdoc:annotation/@name='private')]
	return	<nav id="toc">
			<h2>
			    <a href="{ $opts?root || "index.html" }" class="tag tag-success">{ $opts?project }</a>
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
                        <div class="tag tag-success" style="float:right"	title="RESTXQ:">R</div>
                      else
                        ()}
                       {if($update) then 
                        <div class="tag tag-danger" style="float:right"	title="Updating">U</div>
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

declare function xqh:imports($imports as element(xqdoc:imports))
as element(div){
    
    <div id="imports">
    <h3>Imports ({ count($imports/xqdoc:import) })</h3>
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
              <td>{ $import/xqdoc:uri/string() }
                <xsl:sequence select="qd:nslink(doc:uri)"/>
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
  <div id="variables">
			<h3>
				<a href="#variables">Variables</a>
			</h3>
		{for $v in $vars/xqdoc:variable
      order by  lower-case($v/xqdoc:name)
	   return xqh:variable($v),
     if(empty( $vars/xqdoc:variable)) then "None" else ()
   }
		</div>
};

declare function xqh:variable($v as element(xqdoc:variable))
as element(div)
{
let $id:= concat('$',$v/xqdoc:name)
return
		<div id="{ $id }">
			<h4>
				<a href="#{ $id }">{$id }</a>
			</h4>
			<dl>
        <dt class="label">Summary</dt>,
		   <dd>{ $v/xqdoc:comment/xqdoc:description/(node()|text()) }</dd>
				<dt class="label">Type</dt>
				<dd>{ $v/xqdoc:type/string() }	{ $v/xqdoc:type/@occurrence/string() }</dd>
			</dl>
      { xqh:when($v/xqdoc:annotation,xqh:annotations#1) }
		</div>
};  

declare function xqh:functions($funs as element(xqdoc:functions))
as element(div)
{
  <div id="functions">
			<h3>
				<a href="#functions">Functions</a>
			</h3>
		{ for $f in $funs/xqdoc:function
      order by  lower-case($f/xqdoc:name)
	   return xqh:function($f)
   }
		</div>
};

(:~   o/p details for function $funs has all defined arities
 :)
declare function xqh:function($funs as element(xqdoc:function)*)
as element(div)
{
		let $id:=$funs[1]/xqdoc:name/string()
	  return
		<div id="{$id}">
			<h4>
			   { $id }
			  <div style="float:right">
				<a href="#{$id}" >#</a>
				</div>
			</h4>

		{ xqh:when ($funs/xqdoc:comment/xqdoc:description[1],xqh:description#1) }
			<dt class="label">Signature</dt>
			<dd>
			{$funs!xqh:function-signature(.) }
			</dd>
			{ $funs[1]/xqdoc:parameters!xqh:parameters(.) } 
	    { $funs[1]/xqdoc:return!xqh:return(.) }
		  { $funs[1]/xqdoc:comment/xqdoc:error!xqh:error(.) }
      { $funs/xqdoc:annotations!xqh:annotations(.) }
       <details>
      <summary>Source</summary>
      { $funs! <pre><code class="language-xquery">{ xqdoc:body/string() }</code></pre> }
      </details>
      { xqh:when ($funs/xqdoc:invoked,xqh:invoked#1) }
     
       <details>
      <summary>External functions that invoke this function</summary>
      todo
      </details>
		</div>
};
declare function xqh:invoked($invoked as element(xqdoc:invoked)*)
{
  <details>
      <summary>Names referenced by this function</summary>
      <table class="complex data">
      <thead>
      <tr>
      <td>Type</td>
      <td>uri</td>
      <td>Name</td>
      </tr>
      </thead>
      <tbody>
      {for $i in $invoked
      order by $i/xqdoc:uri,$i/xqdoc:uri,$i/@arity
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
as element(*)
{
		<p>{ $v/@tag/string() }: { $v/* }</p>
};
declare function xqh:see($v as element(xqdoc:see))
{
		'See also:',
		<xsl:for-each select="tokenize(.,'[ \t\r\n,]+')[. ne '']">
			<xsl:if test="position() ne 1">
				<xsl:text>, </xsl:text>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="contains(.,'#')">
					<a
						href="#{ concat('func_', replace(substring-before(.,'#'), ':', '_'),
            '_', substring-after(.,'#')) }">
						<xsl:value-of select="." />
					</a>
				</xsl:when>
				<xsl:when test="starts-with(.,'$')">
					<a href="#{ concat('var_', replace(substring-after(.,'$'), ':', '_')) }">
						<xsl:value-of select="." />
					</a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="." />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
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

declare function xqh:namespaces($namespaces as element(xqdoc:namespaces))
as element(div)
{
		<div id="namespaces">
			<h3>
				<a href="#namespaces">Namespaces</a>
			</h3>
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
 for $n in $tags return
typeswitch ($n)
 
  case element (xqdoc:author) return	<p>Author: {string($n)}</p>
  case element (xqdoc:version) return<p>Version: {string($n)}</p>
  case element (xqdoc:custom) return<p>{ $n/@tag/string()} : {string($n)}</p>  
  default return()
};
 
declare function xqh:restxq($xqd)
as element(div)
{
  <div>TODO resthq</div>
};

declare function xqh:when($value,$fun as function(*))
{
 if($value) then $fun($value) else ()
};
