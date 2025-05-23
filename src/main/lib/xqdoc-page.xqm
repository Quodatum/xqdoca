xquery version "3.1";
(:~
<p>html utilities for page generation</p>
@copyright Copyright (c) 2019-2026 Quodatum Ltd
@author Andy Bunce, Quodatum, License: Apache-2.0
:)
 

module namespace page = 'quodatum:xqdoca.page';
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ prism version path from resources/ :)
declare variable $page:prism  as xs:string :="prism/1.29.0/";

(:~ make html href-able id :)
declare function page:id($id as xs:string)
as xs:string
{
 "ID_" || escape-html-uri($id)
};

(:~
 : generate link to module with namespace, may be multiple 
 :)
 declare function page:link-module($uri as xs:string,  $model as map(*))                       
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
   let $desc:=  $file?xqdoc/xqdoc:module/xqdoc:comment/xqdoc:description
   return <span>
    <a href="{ $file?href }index.html" title="{ page:line-wrap($desc,60) }">{ $file?namespace }</a> 
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
   let $pname:= xqn:prefixed-name($uri,$name,$file?namespaces)
   let $root:="../../"
   return if(empty($files)) then
           <span class="badge badge-warning" title="Externally defined">{ $clark }</span>
        else
           let $file:=head($files)
           return <span>
            <a href="{ $root }{ $file?href }index.html#{ $clark }" title="{ $file?path }">{ $pname }</a> 
           </span>
};

(:~  link to restxq view
 : @todo only if generated
 :)
declare 
function page:link-restxq($path as xs:string,
                          $method as xs:string,
                          $fromModule as xs:boolean
                            )                       
as element(span)
{  
 let $root:=if($fromModule) 
            then "../../" 
            else ""
  return  <span><a href="{ $root }restxq.html#{ $path}#{ $method }">{ page:badge-method($method)}</a></span>
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
   let $pname:= xqn:prefixed-name($uri,$name,$file?namespaces)
   let $root:=if($fromModule) then "../../" else ""
   return  <span>
            <a href="{ $root }{ $file?href }index.html#{ $clark }" title="{ $file?path }">{ $pname }</a> 
           </span>
};


(: badge for http method :)
declare function page:badge-method($method as xs:string)
as element(span)
{
      <span class="badge op-{ lower-case($method) }">{ $method }</span>
};

(:~
 :  connections 3 column list 
 :)
declare function page:calls($calls-this as item()*, $this, $called-by-this as item()*)
as element(div)?
{
  if(0=count($calls-this) and 0=count($called-by-this))then ()
  else 
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div style="flex-grow: 1;padding:10px;">{ if (count($calls-this)) 
                                  then $calls-this!<div style="text-align: right;" >{.}</div>
                                  else "(None)"   
      }</div>
                      
     <div style="display: flex; flex-direction: column; justify-content: center; padding:10px; background-color:blanchedalmond;">
         <div><div>imports</div>&#x2192;</div>
        <div class="badge badge-info">{ $this }</div>
        <div><div>imports</div>&#x2192;</div>
     </div>
     
    <div style="flex-grow: 1;padding:10px;justify-content: space-between;align-items:center;">
    <div style="">{ if(count($called-by-this)) 
                              then $called-by-this!<div style="text-align: left;">{.}</div>
                              else "(None)"
     }</div>
     </div>
</div> 
};

(:~ 
 : generate standard page wrapper
 : uses $opts?resources
  :)
declare function page:wrap($body,$opts as map(*)) 
as element(html)
{
  let $resources:=page:resource-path($opts)
  return
    <html>
      {page:head(  $opts?project || " - xqDocA",$resources)}
      <body class="home" id="top">
        <div id="main" class="line-numbers">
        {$body}
        </div>
        <div class="footer">
            <p style="text-align:right">Generated by 
            <a href="https://github.com/Quodatum/xqdoca" target="_blank">xqDocA <span>{$opts?xqdoca}</span></a>
            &#160; {$opts?version} on { page:date() }</p>
          </div>
         <script  src="{  $resources || $page:prism }prism.js" type="text/javascript"> </script>
        <script  src="{ $resources }xqdoca.js" type="text/javascript"> </script>
      </body>
    </html>
};

(:~ common html head
@param resources relative path to resources
 :)
declare function page:head($title as xs:string,$resources as xs:string)
as element(head){
     <head>
       <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
       <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/> 
       <meta http-equiv="Generator" content="xqdoca - https://github.com/quodatum/xqdoca" />
        <title>{ $title } - xqDocA</title>
        
        <link rel="shortcut icon" type="image/x-icon" href="{ $resources }xqdoc.png" />
        <link rel="stylesheet" type="text/css" href="{ $resources || $page:prism }prism.css"/>
        <link rel="stylesheet" type="text/css" href="{ $resources }page.css" />
        <link rel="stylesheet" type="text/css" href="{ $resources }query.css" />
        <link rel="stylesheet" type="text/css" href="{ $resources }base.css" />   
      </head>
};

declare function page:resource-path($opts as map(*))
as xs:string
{
  if(map:contains($opts,"resources")) then $opts?resources else  "resources/"
};

(:~ 
 : build toc 
 : @param $name title
 : @param $tree xml 
 : @param $decorate function called on leafs
 :)
declare function page:toc3($head as item(),
$tree as element(directory),
$decorate as function(*))
as element(nav)
{
    <nav id="toc">
            <h2>
             <a href="../">^</a>      
                <a id="contents"></a>              
                   { $head }
            </h2>
            <ol class="toc">{
             $tree/*! page:tree-list(.,position(),$decorate,99)
          }</ol>
        </nav> 
};

(:~  section numbering util return dotted string :)
declare function page:section($pos as xs:anyAtomicType*)
as xs:string{
  string-join($pos,".") || "&#160;"
};

(:~ toc from sections
 : @param $head title
 : @param $section elements to toc
:)
declare function page:toc($head,$sections as element(section)*,$links)
as element(nav)
{
 <nav id="toc">
            <h2 class="h3 d-inline-block">
                <a href="../index.html" class="mr-5 bg-info">↖</a>
                <a id="contents"></a>              
                   { $head }
            </h2>
            {$links}
            <ol class="toc">{
			$sections!page:section-toc(.,position())
			}</ol>
</nav>
};

declare function page:section-toc($section as element(section),$pos as xs:integer*)
as element(li)
{
<li>
      <a href="#{ $section/@id/string() }">
           <span class="secno">{ string-join($pos,".") }</span>
           <span class="content">{ $section/*[1]/(*|text()) }</span>
      </a>
      { let $more:= outermost($section//section)
        return if($more) then
           <ol>{$more!page:section-toc(.,($pos,position()))}</ol>
           else ()
       }   
</li>
};

(:~ tree to list
 : @param tree file (@name.@target) directory elements 
 : @param $seq  section number as sequence of levels
:)
declare function page:tree-list($tree as element(*),
                                $seq as xs:integer*,
                                $render as function(*),
                                $maxdepth as xs:integer)
as element(li){
  let $pos:=page:section($seq)
  
  return <li>{
         $render($pos,$tree),
         if($tree  instance of element(directory) and $maxdepth > 0)then
          <ol >{ $tree/*!page:tree-list(.,($seq,position()),$render,$maxdepth -1 ) }</ol>
          else ()
        }</li>
 
};

declare function page:tree-list2($tree as element(*),
                                $seq as xs:integer*,
                                $render as function(*),
                                $maxdepth as xs:integer)
as element(li){
  let $pos:=page:section($seq)
  let $isNested:=$tree instance of element(directory) and $maxdepth > 0
  return <li>{
         (if($isNested)
          
          then 
            <span class="caret">
            {$render($pos,$tree)}/
            </span>
            
          else $render($pos,$tree),
     
         if($isNested) 
         then 
             <ul class="nested">{ 
             $tree/*!page:tree-list2(.,($seq,position()),$render,$maxdepth -1 ) 
             }</ul>
              
          else ()
        )}</li>
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
  <span title="{ $when }" >{ format-dateTime($when, "[FNn], [D1o] [MNn] [Y0000]") }</span>
};

(:~ formated datetime for now :)
declare function page:date()
as element(span)
{
 page:date(current-dateTime())
};

(:~ active renderer names :)
declare 
function page:active-renderers($type as xs:string,
                        $opts as map(*),
                        $exclude as xs:string*)
as xs:string*{
let $selected:=$opts?outputs?($type)
 let $renderers:=$opts(".renderers")?($type)
 return page:tokens($selected)[not(. = $exclude)]
};

(:~ buttons of renderers
 : @param type global or module
 : @param exclude list of renderers to omit
 :)
declare 
function page:related-buttons($type as xs:string,
                        $exclude as xs:string*,
                         $opts as map(*))                       
as element(span)
{
let $list:=page:active-renderers($type,$opts,$exclude)
 let $renderers:=$opts(".renderers")?($type)
 return <span class="ml-2"> {
      for  $name in $list 
      let $rend :=  $renderers[?name=$name]
      for $def in  $rend
      order by $def?name
      return page:alink($def)
}</span>
};

(:~ link to render output :)
declare function page:alink($def as map(*))
as element(a){
  let $target:=if($def?output = ("xml","text")) then "_blank" else "_self"
  return <a href="{ $def?uri }" title="{ page:line-wrap($def?description,60) }" 
        class="badge badge-pill badge-light"  style="margin-left:1em">{ 
                      attribute target { $target},
                      $def?name }</a>
};

(:~ table of renderers
 : @param type global or module
 : @param exclude list of renderers to omit
 :)
declare 
function page:related-docs($type as xs:string,
                        $opts as map(*),
                        $exclude as xs:string*)                       
as element(table)?
{
 let $list:=page:active-renderers($type,$opts,$exclude)
 let $renderers:=$opts(".renderers")?($type)
 return if(not(empty($list))) then
           <table class="data">
                 <thead>
                 <th>View</th>
                 <th>Description</th>
                 <th>Format</th>
                 </thead>
                 <tbody>
                 {
                  for  $name in $list 
                  let $rend :=  $renderers[?name=$name]

                  return (for $def in  $rend
                         order by $def?name
                         return <tr>
                                 <td>{page:alink($def)}</td>
                                  <td>{ $def?description }</td>
                                  <td>{ $def?output }</td>
                                 </tr>,
                         if(empty($rend)) 
                         then <tr>
                                <td><span class="badge badge-danger">{ $name }</span></td>
                                <td>No renderer found</td>
                               </tr>
                         else ()  
                             )
                  }    
                 </tbody>
        </table>
       else
         ()
};

(:~ related docs details 
 : @param $type "global" or "module"
:)
declare function page:related-links($type as xs:string, $exclude as xs:string, $opts as map(*))
as element(details)?
{
let $t:=page:related-docs($type, $opts,$exclude)
return if ($t) then
         <details>
            <summary>Related documents</summary>
            {$t}
          </details>
        else
           ()
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

(:~ 
 : parse tokens from comma space delimited string
 :)
 declare function page:tokens($s as xs:string)
 as xs:string*
 {
 $s=>normalize-space()=>tokenize("[\s,]+") 
};

(:~ extract comment for name :) 
declare function page:comment-for($name as xs:string,$v as element(xqdoc:parameters))
as xs:string*
{
 for $comment in $v/../xqdoc:comment/xqdoc:param[
                                       starts-with(normalize-space(.), $name) or 
                                       starts-with(normalize-space(.), concat('$',$name))
                                     ]
 return substring-after(normalize-space($comment), $name)  
};

(:~ line count :) 
declare function page:line-count($txt as xs:string?)
as xs:integer{
  tokenize($txt, '(\r\n?|\n\r?)')=>count()
};

(:~ break lines longer than width by inserting newline chars
:)
declare function page:line-wrap($string as xs:string?,$width as xs:integer)
as xs:string?{
  $string=>normalize-space()=>concat(" ")=>replace(``[(.{0,`{ $width }`})
]``,'$1&#xA;')
};