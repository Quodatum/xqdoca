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
module namespace xqhtml = 'quodatum:build.xqdoc-html';
import module namespace tree = 'quodatum:data.tree' at "tree.xqm";

declare namespace c="http://www.w3.org/ns/xproc-step";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqhtml:mod-xslt external :="html-module.xsl";


(:~ transform files to html
 : @param $params  keys: resources 
 : "ext-id": "299",
 : "src-folder": "C:/Users/andy/git/vue-poc/src/vue-poc",
 : "project": "vue-poc"
 :)
declare function xqhtml:index-html2($state as map(*),
                            $params as map(*)
                            )
as document-node()                            
{
let $d:=<div>
             <h1>
                  <span class="tag tag-success">
                      { $params?project }
                  </span>
                  XQuery module Documentation 
              </h1>
              { xqhtml:toc($params) }
              <dl>
              <dt><a href="restxq.html">RestXQ</a></dt>
              <dd>Summary of RESTXQ usage</dd>
              <dt> <a href="imports.html">Imports</a></dt>
              <dd>Summary of all imports</dd>
               </dl>
              <div>src: { $params?src-folder }</div>
             
              <div id="ns">
                  <h1>Module Uris</h1>
                  <table class="data">
                  <thead>
                  <tr>
                  <th>Uri</th>
                  <th>parsed</th>
                  <th>Restxq</th>
                  <th>Update</th>
                  </tr>
                  </thead>
                  <tbody>
                 
                     { for $file  at $pos in $state?files
                     
                       order by $file?namespace
                      return  <tr>
                               <td>
                             {xqhtml:link-module($file) }
                                </td>
                                <td>
                                { 
                                let $type:=$file?xqdoc/xqdoc:module/@type/string()
                                return if($file?xqparse/name="error") then "ERROR"
                                       else $type
                                 }
                                </td>
                                   <td>
                                { "R" }
                                </td>
                                  <td>
                                { "U" }
                                </td>       
                            </tr>
                      }
                  </tbody>
                  </table>
              </div>
               <div id="file">
                  <h1>Files</h1>
                  <ul>
                      { for $file  at $pos in $state?files
                   
                      return  <li>
                                <a href="{ $file?href }index.html">
                                   { $file?path }
                                </a>      
                                { $pos }
                            </li>
                      }
                  </ul>
              </div>

           </div>
return document{ xqhtml:page($d, $params ) }
};


(:~ 
 : build toc 
 : params: map{"project":..}
 :)
declare function xqhtml:toc($params)
as element()
{
    <nav id="toc">
            <h2>
                <a id="contents"></a>
                <span class="tag tag-success">
                    { $params?project }
                </span>
            </h2>
            <ol class="toc">
                <li>
                    <a href="#main">
                        <span class="secno">1 </span>
                        <span class="content">Introduction</span>
                    </a>
                </li>
                <li>
                    <a href="#ns">
                        <span class="secno">2 </span>
                        <span class="content">Module uris</span>
                    </a>
                </li>
                <li>
                    <a href="#file">
                        <span class="secno">3 </span>
                        <span class="content">Files</span>
                    </a>
                </li>
            </ol>
        </nav>
};

(:~ tree to list :)
declare function xqhtml:tree-list($tree as element(*),$seq as xs:integer*){
  typeswitch ($tree )
  case element(directory) 
      return <li>
                 <span class="secno">{string-join($seq,'.')}</span>
                 <span class="content">{$tree/@name/string()}/</span>
                 <ol class="toc">{$tree/*!xqhtml:tree-list(.,($seq,position()))}</ol>
             </li>
   case element(file) 
      return <li>{if($tree/@target) then
                   <a href="#{$tree/@target}">
                     <span class="secno">{string-join($seq,'.')}</span>
                     
                      <span class="content" title="{$tree/@target}">{  $tree/@name/string() }</span>
                      <div class="tag tag-success" 
                            title="RESTXQ: {$tree/@target}">GET
                      </div>
                      <div class="tag tag-danger"  style="float:right"
                            title="RESTXQ: {$tree/@target}">X
                      </div>
                   </a>
               else 
                <span class="content">{$tree/@name/string()}</span>
             }</li>   
  default 
     return <li>unknown</li>
};

(:~
 : html for page. 
 :)
declare function xqhtml:restxq($state,$annots,$opts)
{
let $tree:=trace($annots?uri)
let $tree:=tree:build($tree)=>trace("TRRES")
let $body:= <div>
          <nav id="toc">
            <h2>
                 <a href="index.html" class="tag tag-success">
                    { $state?project }
                </a>
                / RestXQ
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
                 <li  href="#main">
                    <a >
                        <span class="secno">2 </span>
                        <span class="content">Paths.</span>
                    </a>
                </li>
                <li>
      
                 <ol  class="toc"> { $tree/*/*!xqhtml:tree-list(.,2) } </ol>
                </li>
             </ol>
           </nav>
           <a href="index.html">index: </a>
          
           <ul>{$annots!xqhtml:path-to-html(.)}</ul>
           </div>
return  xqhtml:page($body,$opts)
};

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
declare function xqhtml:xqdoc-html($xqd as element(xqdoc:xqdoc),
                            $params as map(*)
                            )
as document-node()                            
{  
try{
     xslt:transform($xqd=>trace("WWW"),$xqhtml:mod-xslt,$params) 
 } catch *{
  document {<div>
             <div>Error: { $err:code } - { $err:description }</div>
              <pre>error { serialize($params,map{"method":"basex"}) } - { $xqhtml:mod-xslt }</pre>
            </div>}
}
};

(:~ import page :)
declare function xqhtml:imports($state,$imports,$opts)
{
  let $body:=<div>
   <nav id="toc">
            <h2>
                <a href="index.html" class="tag tag-success">
                    { $state?project }
                </a>
                / Imports
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
                
             </ol>
           </nav>
           <a href="index.html">index</a>
           <p>Lists all modules imported.</p>
           {for $import in $imports
           order by $import?uri
           return <div  id="{ $import?uri }">
           <h4>{ $import?uri }
           <div  style="float:right"><a href="#{ $import?uri }">#</a></div>
           </h4>
           <ul>
           {for $f in  $import?where
           return <li><a href="{$f?href}index.html">{ $f?namespace }</a></li>
         }
           </ul>
           </div>
           }
  </div>
  return  xqhtml:page($body,$opts)
};
(:~  html for a path :)          
declare function xqhtml:path-to-html($rep as map(*))
as element(li){
   <li id="{ $rep?uri }">
       <h4>{ $rep?uri }</h4>
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
   </li>
};
(:~ 
 : generate standard page wrapper
 : uses $opts?resources
  :)
declare function xqhtml:page($body,$opts as map(*)) 
as element(html)
{
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta http-equiv="Generator" content="xqdoc-r - https://github.com/quodatum/xqdoc-r" />

        <title>
          { $opts?project } - xqDocA
        </title>
        <link rel="shortcut icon" type="image/x-icon" href="{$opts?resources}xqdoc.png" />
        <link rel="stylesheet" type="text/css" href="{$opts?resources}page.css" />
        <link rel="stylesheet" type="text/css" href="{$opts?resources}query.css" />
        <link rel="stylesheet" type="text/css" href="{$opts?resources}base.css" />

      </head>

      <body class="home" id="top">
        <div id="main">
        {$body}
        </div>
        <div class="footer">
            <p style="text-align:right">generated at {current-dateTime()}</p>
          </div>
      </body>
    </html>
};

(:~ save runtime support files to $target :)
declare %updating
function xqhtml:export-resources2($target as xs:string)                       
as empty-sequence(){  
archive:extract-to($target, file:read-binary(resolve-uri('resources.zip')))
};

(:~ link to module :)
declare 
function xqhtml:link-module($file as map(*))                       
as element(a)
{  
   <a href="{ $file?href }index.html" title="{ $file?path }">{ $file?namespace }</a>
};    