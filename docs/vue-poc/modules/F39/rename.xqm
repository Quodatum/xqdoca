(:  xqDocA added a comment :)
(:~
 : XQDoc: generate restxq.html from resources located at $target 
 :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../../../lib/xqdoc/xqdoc-proj.xqm";
import module namespace xqhtml = 'quodatum:build.xqdoc-html' at "../../../lib/xqdoc/xqdoc-html.xqm";
import module namespace store = 'quodatum.store' at "../../../lib/store.xqm";
import module namespace tree = 'quodatum.data.tree' at "../../../lib/tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare namespace c="http://www.w3.org/ns/xproc-step";
declare namespace xqdoc="http://www.xqdoc.org/1.0";


(:~ URL of the doc source
 : @default file:///C:/tmp/xqdoc/
 :)
declare variable $target as xs:anyURI external :=
"file:///C:/tmp/xqdoc/" cast as xs:anyURI;


(:~   sequence of maps for each restxq:path 
 : @param 
:)
declare function local:import-XQDOCA($path,
                              $id as item(),
                              $folder)
as map(*)*
{
  let $uri:=``[modules/F`{ string($id) }`/]``
  let $doc:=doc(resolve-uri($uri || "xqdoc.xml",$folder))
  let $annots:=xqd:annotations-XQDOCA($doc/*, $xqd:nsRESTXQ,"path")
  return $annots!map{
                "id": $id,
                "uri": $uri,
                "path": $path,
                "annot": .,
                "function": ./../../(xqdoc:name/string(),@arity/string()),
                "description": ./../../xqdoc:comment/xqdoc:description/node() 
                 }
       
};

(:~
 : html for page. 
 :)
 declare function local:page($reps as map(*)*)
{
let $tree:=trace($reps?uri)
let $tree:=tree:build-XQDOCA($tree)=>trace("TRRES")
let $op:= <div>
          <nav id="toc">
            <div>
                <a href="index.html">
                   Index 
                </a>
            </div>
            <h2>
                <a id="contents"></a>
                <span >
                    RestXQ
                </span>
            </h2>
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
      
                 <ol  class="toc"> { $tree/*/*!local:tree-list-XQDOCA(.,2) } </ol>
                </li>
             </ol>
           </nav>
           <a href="index.html">index: </a>
          
           <ul>{$reps!local:path-to-html-XQDOCA(.)}</ul>
           </div>
return  xqhtml:page-XQDOCA($op,map{"resources": "resources/"})
};

(:~ tree to list :)
declare function local:tree-list($tree as element(*),$seq as xs:integer*){
  typeswitch ($tree )
  case element(directory) 
      return <li>
                 <span class="secno">{string-join($seq,'.')}</span>
                 <span class="content">{$tree/@name/string()}/</span>
                 <ol class="toc">{$tree/*!local:tree-list-XQDOCA(.,($seq,position()))}</ol>
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

(:~  html for a path :)          
declare function local:path-to-html($rep as map(*))
as element(li){
   <li id="{ $rep?uri }">
       <h4>{ $rep?uri }</h4>
       <ul>{
       let $methods as map(*) :=$rep?methods
       for $method in map:keys-XQDOCA($methods)
       let $d:=$methods?($method)
       let $id:=head($d?function)
       return <li>
                    <a href="{$d?uri}index.html#{$id }">{ $method }</a>
                    <div>{$d?description}</div>
              </li>
       }</ul>
   </li>
};


(:sequence of maps :map{id:,path:,annot:} :)                                            
let $reports:= doc(resolve-uri("files.xml",$target))
              //c:file!local:import-XQDOCA(string-join(ancestor-or-self::*/@name,"/"),position(),$target)

(: map keyed on uris :)
let $data:=map:merge-XQDOCA(for $report in $reports
          group by $uri:=$report?annot/xqdoc:literal/string()
          let $methods:= map:merge-XQDOCA(
                         for $annot in $report
                         let $hits:=for $method in $xqd:methods
                                     let $hit:=  xqd:methods-XQDOCA($annot?annot/.., $xqd:nsRESTXQ, $method)
                                     return if(empty($hit)) then () else map{$method: $annot}
                         return if(exists($hits))then $hits else map{"ALL":$annot}
                         
                       )
          return map:entry-XQDOCA($uri,map{ "uri": $uri, "methods": $methods})
        ) 


let $uris:=sort(map:keys-XQDOCA($data))
let $result:=<json type="object">
                  <extra>hello2</extra>
                  <msg> {$target}, {count($data)} uris processed.</msg>
                  <id>xqrest2 ID??</id>
              </json>
return 
      (
       local:page-XQDOCA( $data?($uris))
       =>xqd:store2("restxq.html",$xqd:HTML5)
       =>store:store($target),
       update:output-XQDOCA($result)
       )
 