xquery version "3.1";
(:~ annotation report
  @copyright (c) 2019-2022 Quodatum Ltd
  @author Andy Bunce, Quodatum, License: Apache-2.0
:)
module namespace _ = 'quodatum:xqdoca.generator.annotations';

import module namespace page = 'quodatum:xqdoca.page'  at "../lib/xqdoc-page.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "../lib/annotations.xqm";

declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~ HTML for annotations report :)
declare 
%xqdoca:global("annotations","Summary of XQuery annotation use")
%xqdoca:output("annotations.html","xhtml") 
function _:annotations($model as map(*),$opts as map(*))
as element(html){
  let $ns-map:=xqa:annotations($model)
  let $sections:=(
             _:summary($model, $opts, $ns-map),
             <section id="annotations">
                 <h2>Annotations</h2>

                 {
                 for $ns in map:keys($ns-map)
                 order by $ns
                 count $c
                 return <section id="{ $ns }">
                            <h3>{page:section((2,$c))} { $ns }</h3>
                            {sort(distinct-values($ns-map?($ns)?annotation?name)) 
                            !<span style="margin-left:1em" >
                                <a href="#{{{ $ns}}}{.}">{.}</a>
                             </span>}
                            {for $a in $ns-map?($ns)
                            group by $name:=$a?annotation?name
                            order by lower-case($name)
                            (:~ let $_:=trace($a?annotation,"ANNO: ") ~:)
                            return _:anno-calls($ns,$name,$a) 
                      } </section>       
           }</section>
  )
    let $links:= page:related-buttons("global","annotations", $opts)
  let $body:=<div>
              <h1>
                     Project 
                     <span class="badge badge-info">{ $opts?project }</span>
                  &#160;Annotations 
              </h1>
              
              <nav id="toc">
                        <h2>
                            <a href="index.html" >
                                { $opts? project }
                            </a>
                            / Annotations
                        </h2>
              { $links}
                <h3>
                  Contents
                </h3>
              { _:toc(map:keys($ns-map) => sort())}
              </nav>
             {$sections}
             
      </div>
  return  page:wrap($body,$opts)
};

declare function _:anno-calls($ns as xs:string, $name as xs:string,$a)
as element(div){
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
                       let $x:= xqa:name-detail($a2?xqdoc/../..,$a2?file)
                       return if($x instance of map(*)) then 
                                page:link-function2($x?uri,$x?name,$a2?file,false()) 
                              else 
                                ()
                     }</td>
                    <td>{ xqa:literals($a2?xqdoc/xqdoc:literal) }</td>
                </tr>
       }</tbody>
     </table>
</div>        
};

declare function _:summary($model,
                           $opts, 
                           $ns-map as map(*))
as element(section)
{
  <section id="summary">
    <h2>Summary</h2>
    <p>This project uses { map:size($ns-map) } annotation namespaces.</p>
     { page:related-links("global","annotations", $opts) }
 </section>
};

(:~ table of contents as list from namespace list :)
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
        {$t/*!page:tree-list(.,position(),page:toc-render#2,99)}
        </ol>    
};


