xquery version "3.1";
(:~
 <p>Library to support html5 rendering of xqdoc</p>
 @copyright Copyright (c) 2019-2022 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
:)
 
(:~
 : Generate XQuery  documentation in html
 :)
module namespace xqhtml = 'quodatum:xqdoca.generator.index';

import module namespace tree = 'quodatum:data.tree' at "../lib/tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at "../lib/model.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../lib/annotations.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../lib/xqdoc-page.xqm";

declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

(:~ left arrow :)
declare variable $xqhtml:larr:="&#8598;";

(:~ transform files to html
 : @param $opts  keys: resources 
 : "project": "vue-poc"
 :)
declare 
%xqdoca:global("report","Index of sources")
%xqdoca:output("index.html","xhtml") 
function xqhtml:index-html($model as map(*),
                            $opts as map(*)
                            )
as document-node()                            
{
 let $sections:=(
                 xqhtml:summary($model,$opts),
                 xqhtml:modules("main_mods" ,"XQuery Main",$model?files[?xqdoc/xqdoc:module/@type="main"],$model),
                 xqhtml:modules("library_mods" ,"XQuery Library",$model?files[?xqdoc/xqdoc:module/@type="library"],$model),
                 xqhtml:files($model,$opts),
                 xqhtml:annot($model,$opts)
             )
let $links:= page:related-buttons("global","report", $opts)                 
let $d:=<div>
             <h1>
                 Project <span class="badge badge-info">
                      { $opts?project }
                  </span>
                  &#160;XQuery source documentation 
              </h1>
             { page:toc($opts?project,$sections,$links) }
        </div>
return document{ page:wrap(($d,$sections), $opts ) }
};



declare function xqhtml:summary($model as map(*),$opts as map(*))
as element(section)
{
  <section id="summary">
    <h2>Summary</h2>
     
    <p>The project 
    <span class="badge badge-info">{ $opts?project }</span> contains
    { count($model?files) } XQuery source files, and uses
 { $model?files?annotations?annotation?uri=>distinct-values()=>count() } annotation namespaces.
    </p>
     <p>This document was built from source folder <kbd>{ $model?base-uri }</kbd> on
     { page:date()}.</p>
   { page:related-links("global","index.html", $opts) }
 </section>
};


(:~ 
 : summary of all annotations  in project
 :)
declare function xqhtml:annot($model as map(*), $opts as map(*))
as element(section)
{
   let $ns-map:=map:merge(
                        for $a in $model?files?annotations
                        group by $uri:=$a?annotation?uri
                         return map:entry($uri,$a)
                       )
   return <section id="annotation">
              <h2>{ ``[Annotation namespaces (`{ map:size($ns-map) }`)]`` }</h2>
              <p> A total of {count( $model?files?annotations)} annotations are defined. 
              </p>{
               for $ns in map:keys($ns-map)
               order by $ns
               return <section id="{$ns}">
                        <h3>{ $ns }</h3>
                        <div>
                        {for $a in $ns-map?($ns)
                        group by $name:=$a?annotation?name
                        order by lower-case($name)
                        return <span style="margin-right:1em;">
                                  <a href="annotations.html#{{{ $ns }}}{ $name }" >{$name}</a>
                                  <span class="badge badge-info">{count($a)}</span>
                               </span>
                      }</div>
                     </section>
      }</section>
}; 
               
(:~ create module table section :)
declare function xqhtml:modules($id,$title,$mods, $model)
as element(section)
{
 <section id="{ $id }">
  
    <h2>{ ``[ `{ $title }` (`{ count($mods) }`)]`` }</h2>
    { xqhtml:modtable($mods,$model) }

</section>
};

(:~ file summary section :)
declare function xqhtml:files($model as map(*),$opts as map(*))
as element(section)
{
       let $t:=tree:build( $model?files?path)
       let $fmap:=map:merge($model?files!map:entry(?path,?href))
       let $f:=function($pos,$el){
          if($el/@target) then
            let $href:=substring($el/@target,2)
            let $a:=map:get($fmap,$href) 
            return <a href="{ $a }index.html">{ $el/@name/string() }</a>
          else
             $el/@name/string() 
       }
       return
      <section  id="file">
	      <h2>{ ``[File view (`{ count($model?files) }`)]`` }</h2>
	   
	      {
	        <ul class="tree">
	          { $t/*!page:tree-list2(.,(),$f,99) }
	       </ul>
	      }
	    </section>
};

declare function xqhtml:modtable($files as map(*)*,$model as map(*))
as element(div)
{
  <div>{if (count($files)=0) then
          <p>None</p>
        else
     <table class="data">
           <colgroup>
               <col  style="width: 35%;"/>
                <col  style="width: 10%;"/>
                <col  style="width: 25%;"/>
                <col  style="width: 10%;"/>
                <col  style="width: 10%;"/>
		            <col  style="width: 10%;"/>
		    </colgroup>
		    <thead>
		    <tr>
          <th>Uri</th>
          <th>Prefix</th>
          
          <th>Description</th>
          <th>Use</th>
          <th title="Annotations">A</th>
          <th>Metrics</th>
		    </tr>
		    </thead>
    <tbody>
   
       { for $file  at $pos in $files
        let $type:=xqd:file-parsed-type($file)
         order by $type, $file?namespace
         let $annots:= for $a in $file?annotations
                       group by $ns:=$a?annotation?uri
                       order by $ns
                       return $ns
         let $desc:= $file?xqdoc/xqdoc:module/xqdoc:comment/xqdoc:description=>string()
        return  <tr>
                <td style="word-break:break-all;">{page:link-module($file) }</td>
                <td title="prefix">{ $file?prefix}</td>
                 <td title="{ page:line-wrap($desc,60) }">{ xqhtml:truncate-text($desc,50) }</td>
                 <td >{   xqhtml:file-usage($file,$model) }</td>

                 <td title="{ $annots }">{ xqa:badges($file?xqdoc//xqdoc:annotation, $file,page:badge#3) }</td>       
              
                 <td style="text-align: right">
                 <div>V#{$file?xqdoc//xqdoc:variable=>count() }</div>
                 <div>F#{$file?xqdoc//xqdoc:function=>count() }</div>
                 </td>
              </tr>
        }
    </tbody>
    </table>
  }</div>
};

(:~ usage (import) info
 :)
declare 
function xqhtml:file-usage($file as map(*),$model as map(*))                       
as element(div)
{ 
   let $x:=xqd:import-count($file?xqdoc,$model)
   return switch( xqd:file-parsed-type($file))
   case "main"    
   					return <div>
   					          <div title="Main module" class="badge badge-info">Main</div>
   					          <div title="imports" style="float:right">{ $xqhtml:larr }{ count($x?imports)}</div>
   					       </div>
   					
   case "library" 
             return <div>
                        <div title="imported by">{ count($x?importedby) }<span>{ $xqhtml:larr }</span></div>
                        <div title="Library module" class="badge badge-info">Library</div>
                        <div title="imports" style="float:right">{ $xqhtml:larr }{ count($x?imports)}</div>
                    </div>
   
   default        return <div>#ERROR</div>
};

(:~ chop long text :)
declare 
function xqhtml:truncate-text($text as xs:string,$max as xs:integer) 
as xs:string{
if(string-length($text) lt $max)
then $text
else substring($text,1, $max -3) || "..."
};  