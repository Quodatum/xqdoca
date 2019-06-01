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
 : <h1>xqdoc-links.xqm</h1>
 : <p>html utilities</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace page = 'quodatum:xqdoca.page';
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";

(:~ make html hrefable id :)
declare function page:id($id as xs:string)
as xs:string
{
 "ID_" || escape-html-uri($id)
};

(:~
 : generate link to module with namespace 
 :)
 declare function page:link-module($uri as xs:string,$model as map(*))                       
as element(span)
{
 let $files:=$model?files[?namespace=$uri]
 let $root:="../../"
 return if(empty($files)) then
           <span class="badge badge-warning" title="Externally defined">{ $uri }</span>
        else
           <span>
           <a href="{ $root }{ $files[1]?href }index.html" title="{ $files[1]?path }">{ $files[1]?namespace }</a>
           {for $file at $pos in tail($files)
           return ("&#160;",
                <a  href="{ $root }{ $file?href }index.html" title="{ $file?path }">
                <span class="badge badge-info">{1+$pos}</span>
                </a>
                )
         }</span> 
};

(:~ link to module :)
declare 
function page:link-module($file as map(*))                       
as element(span)
{  
   <span>
    <a href="{ $file?href }index.html" title="{ $file?path }">{ $file?namespace }</a> 
   </span>
};

(:~ link to fun or var in file
 : @param name of form 'fun#arity or '$name' 
:)
declare 
function page:link-function($uri as xs:string,
                            $name as xs:string,
                            $file as map(*),
                            $model as map(*))                       
as element(span)
{  
   let $files:= $model?files[?namespace=$uri]
   let $clark:= xqn:clark-name($uri,$name)
   let $pname:= xqn:prefixed-name($uri,$name,$file?prefixes)
   let $root:="../../"
   return if(empty($files)) then
           <span class="badge badge-warning" title="Externally defined">{ $clark }</span>
        else
           let $file:=head($files)
           return <span>
            <a href="{ $root }{ $file?href }index.html#{ $clark }" title="{ $file?path }">{ $pname }</a> 
           </span>
};

 
(:~ link to fun or var in file
 : @param name of form 'fun#arity' or ''$name' 
 : @param fromModule where called from
:)
declare 
function page:link-function2($uri as xs:string,
                             $name as xs:string,
                             $file as map(*),
                             $fromModule as xs:boolean
                           )                       
as element(span)
{  
   let $clark:= xqn:clark-name($uri,$name)
   let $pname:= xqn:prefixed-name($uri,$name,$file?prefixes)
   let $root:=if($fromModule) then "../../" else ""
   return  <span>
            <a href="{ $root }{ $file?href }index.html#{ $clark }" title="{ $file?path }">{ $pname }</a> 
           </span>
};

(:~
 :  connections 3 column list 
 :)
declare function page:calls($calls-this as item()*,$this,$called-by-this as item()*)
as element(div)?
{
  if(0=count($calls-this) and 0=count($called-by-this))then ()
  else 
      <div style="display: flex;width:100%; justify-content: space-between;">
        <div style="width:40%;">{ if (count($calls-this)) then
                                     $calls-this!<div style="text-align: right;" >{.}</div>
                                  else "(None)"   
      }</div>
                      
     <div style="display: flex; flex-direction: column; justify-content: center;">
         <div><div>imports</div>&#x2192;</div>
        <div class="badge badge-info">this</div>
        <div><div>imports</div>&#x2192;</div>
     </div>
     
    <div style="width:40%;">{ if(count($called-by-this)) then
                                $called-by-this!<div>{.}</div>
                              else
                               ("(None)")
     }</div>
</div> 
};

(:~ 
 : generate standard page wrapper
 : uses $opts?resources
  :)
declare function page:wrap($body,$opts as map(*)) 
as element(html)
{
    <html>
      <head>
       <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
       <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/> 
       <meta http-equiv="Generator" content="xqdoca - https://github.com/quodatum/xqdoca" />
        <title>
          { $opts?project } - xqDocA
        </title>
        
        <link rel="shortcut icon" type="image/x-icon" href="{ $opts?resources }xqdoc.png" />
        <link rel="stylesheet" type="text/css" href="{ $opts?resources }prism.css"/>
        <link rel="stylesheet" type="text/css" href="{ $opts?resources }page.css" />
        <link rel="stylesheet" type="text/css" href="{ $opts?resources }query.css" />
        <link rel="stylesheet" type="text/css" href="{ $opts?resources }base.css" />
     
      
      </head>

      <body class="home" id="top">
        <div id="main" >
        {$body}
        </div>
        <div class="footer">
            <p style="text-align:right">Generated by 
            <a href="https://github.com/Quodatum/xqdoca" target="_blank">xqDocA</a> 
            at { page:date() }</p>
          </div>
         <script  src="{ $opts?resources }prism.js" type="text/javascript"> </script>
       
      </body>
    </html>
};

(:~ 
 : build toc 
 : @param $name title
 : @param $tree xml 
 : @param $decorate function called on leafs
 :)
declare function page:toc3($name as xs:string,$tree as element(directory),$decorate as function(*))
as element(nav)
{
    <nav id="toc">
            <h2>
                <a id="contents"></a>
                <span >
                   { $name }
                </span>
            </h2>
            <ol class="toc">{
             $tree/*! page:tree-list(.,position(),$decorate)
          }</ol>
        </nav> 
};

(:~  section numbering util return dott joined string :)
declare function page:section($pos as xs:anyAtomicType*)
as xs:string{
  string-join($pos,".") || "&#160;"
};

(:~ tree to list
 : @param tree file (@name.@target) directory elements 
 : @param $seq  section number as sequence of levels
:)
declare function page:tree-list($tree as element(*),$seq as xs:integer*,$render as function(*))
as element(li){
  let $pos:=page:section($seq)
  
  return <li>{
         $render($pos,$tree),
         if($tree  instance of element(directory))then
          <ol >{ $tree/*!page:tree-list(.,($seq,position()),$render) }</ol>
          else ()
        }</li>
 
};

(:~ 
 : simple toc render 
 : @see tree-list
 :)
declare function page:toc-render($pos as xs:string,$el as element(*))
as element(*)
{
let $c:=(
<span class="secno">{$pos}</span>,
<span class="content">{$el/@name/string()}</span>
)
return if($el/@target) then
 <a href="{$el/@target}">{ $c }</a>
else
 <span>{$c}</span>
};

(:~ formated datetime
 : @param $when date to now
 :)
declare function page:date($when as xs:dateTime)
as element(span)
{
  <span title="{ $when }" >{ format-dateTime($when, "[h].[m01][Pn] on [FNn], [MNn] [D1o] [Y0000]") }</span>
};

(:~ formated datetime for now :)
declare function page:date()
as element(span)
{
 page:date(current-dateTime())
};

(:~ table of renderers
 : @todo only show in referenced in $opts
 :)
declare 
function page:view-list($renderers as map(*)*,$exclude as xs:string*)                       
as element(table)
{
 <table class="data">
 <thead>
 <th>View</th>
 <th>Description</th>
 </thead>
 <tbody>
 {
  for  $def in $renderers
  where not($def?name = $exclude)
  return <tr><td><a href="{ $def?uri }">{ $def?name }</a></td>
             <td>{ $def?description }</td>
         </tr>
  }    
 </tbody>
</table>
};

(:~ 
 : Coloured <span/> as bootstrap badge
 :)
declare function page:badge($label as xs:string,$color as xs:string,$title as xs:string)
as element(span)
{
  <span class="badge badge-{$color}" title="{ $title }">{$label}</span>
};

(:~ 
 :true() if $url represents a url
 :@see http://urlregex.com/ 
 :)
declare function page:is-url($url as xs:string)
as xs:boolean
{
  matches($url,"^(https?|ftp|file)://[-a-zA-Z0-9+&amp;@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&amp;@#/%=~_|]","j")
};
