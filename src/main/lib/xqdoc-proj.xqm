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
 : <h1>xqdoc-proj.xqm</h1>
 : <p>Analyse XQuery source</p>
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
module namespace xqd = 'quodatum:build.xqdoc';

import module namespace store = 'quodatum:store' at 'store.xqm';
import module namespace xqhtml = 'quodatum:build.xqdoc-html' at "xqdoc-html.xqm";
import module namespace xqp = 'quodatum:build.parser' at "xqdoc-parser.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(: source file extensions :)
declare variable $xqd:exts:="*.xqm,*.xq";

declare variable $xqd:HTML5:=map{"method": "html", "version":"5.0", "indent": "no"};
declare variable $xqd:XML:=map{"indent": "no"};
declare variable $xqd:mod-xslt external :="html-module.xsl";
declare variable $xqd:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqd:cache external :=false();

(:~  @see https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods :)
declare variable $xqd:methods:=("GET","HEAD","POST","PUT","DELETE","PATCH");



(:~
: create documentation folder map
: map{"base-uri":.., "files":map(*)*}
:)
declare function xqd:read($efolder as xs:string)
as map(*)
{
let $files:= file:list($efolder,true(),$xqd:exts)
let $full:= $files!concat($efolder || "\",.)                                
return map{ 
             "base-uri": $efolder,
             "project": tokenize($efolder,"[/\\]")[last()],
             "files": for $file at $pos in $files
                      let $full:=concat($efolder || "\", $file)
                      let $spath:=translate($file,"\","/")
                      let $xqdoc:=xqd:xqdoc($full,map{"_source": $spath})
                      let $base:=map{
                        "path":$file,
                        "href": ``[modules/F`{ $pos }`/]``,
                        "namespace": $xqdoc?xqdoc/xqdoc:module/xqdoc:uri/string()
                      }
                      return map:merge(($base,$xqdoc))  
           }

};

(: return sequence of maps  are imported ns values are where imported:)
declare function xqd:imports($doc)
as map(*)*
{
for $f in $doc?files
for $in in $f?xqdoc//xqdoc:import[@type="library"]
group by $ns:=$in/xqdoc:uri
return map{ "uri": $ns, "where": $f}

};



   

(:~ generate xqdoc
 : result is <XQuery> or <ERROR>
 :)
declare function xqd:xqdoc($url as xs:string)
as element(xqdoc:xqdoc)
{  
 inspect:xqdoc($url)
};
(:~ 
 : Generate xqdoc adding custom opts 
 :)
declare function xqd:xqdoc($url as xs:string,$opts as map(*))
as map(*)
{  
  let $xqd:=xqd:xqdoc($url)
  let $src:=fetch:text($url)
  let $parse:=xqp:parse($src)
  let $enh:=$xqd transform with {
          for $tag in map:keys($opts)
          where xqdoc:module[@type="library"]
          return insert node <xqdoc:custom tag="_{ $tag }">{ $opts?($tag) }</xqdoc:custom> 
          into xqdoc:module[@type="library"]/xqdoc:comment
     }
  let $enh:=$enh transform with {
    insert node <xqdoc:body>{$src}</xqdoc:body> into xqdoc:module
  }
  return map{"xqdoc": $enh, 
             "xqparse": $parse
              }
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
declare function xqd:xqdoc-html($xqd as element(xqdoc:xqdoc),
                            $params as map(*)
                            )
as document-node()                            
{  
try{
     xslt:transform($xqd=>trace("WWW"),$xqd:mod-xslt,$params) 
 } catch *{
  document {<div>
             <div>Error: { $err:code } - { $err:description }</div>
              <pre>error { serialize($params,map{"method":"basex"}) } - { $xqd:mod-xslt }</pre>
            </div>}
}
};


(:~ return sequence of maps with maps uri and methods :)
declare function xqd:rxq-paths($state)
as map(*)* 
{
let $reports:= xqd:annots-rxq($state)  
(: map keyed on uris :)
let $data:=map:merge(for $report in $reports
          group by $uri:=$report?annot/xqdoc:literal/string()
          let $methods:= map:merge(
                         for $annot in $report
                         let $hits:=for $method in $xqd:methods
                                     let $hit:=  xqd:methods($annot?annot/.., $xqd:nsRESTXQ, $method)
                                     where $hit
                                     return map{$method: $annot}
                         return if(exists($hits))then $hits else map{"ALL":$annot}
                       )
          return map:entry($uri,map{ "uri": $uri, "methods": $methods})
        ) 
let $uris:=sort(map:keys($data))        
return $data?($uris)        
};
(:~ 
 : map for each restxq:path annotation
  :)
declare function xqd:annots-rxq($state as map(*))
as map(*)*
{
  for $f at $index in $state?files
  for $annot in xqd:annotations($f?xqdoc, $xqd:nsRESTXQ,"path")
  return map{
                "id": $index,
                "uri": $f?href,
                "path": $f?path,
                "annot": $annot,
                "function": $annot/../../(xqdoc:name/string(),@arity/string()),
                "description": $annot/../../xqdoc:comment/xqdoc:description/node() 
                 }
};

(:~ 
 : return all matching annotations in xqdoc
 :)
declare function xqd:annotations($xqdoc  as element(xqdoc:xqdoc),
                                 $annotns as xs:string,
                                 $aname as xs:string) 
as element(xqdoc:annotation)*
{
 let $prefixes:=$xqdoc//xqdoc:namespace[@uri=$annotns]/@prefix/string()
 return $xqdoc//xqdoc:annotations/xqdoc:annotation[@name=(for $p in $prefixes return concat($p,':',$aname))]

};

(:~ 
 : return annotations with namespace and name
  :)
declare function xqd:methods($annots  as element(xqdoc:annotations),
                                 $annotns as xs:string,
                                 $aname as xs:string) 
as element(xqdoc:annotation)*
{
   let $ns:=$annots/ancestor::xqdoc:xqdoc/xqdoc:namespaces
   let $prefixes:=$ns/xqdoc:namespace[@uri=$annotns]/@prefix/string()
  return $annots/xqdoc:annotation[@name=(for $p in $prefixes return concat($p,':',$aname))]

};



(: @return map of functions and variables having annotations :)
declare function xqd:annotation-map($xqdoc)
{
  let $ns:=map:merge((
           map:entry("", "http://www.w3.org/2012/xquery"),
           $xqdoc//xqdoc:namespace!map:entry(string(@prefix),string(@uri))
           ))
  let $f:=$xqdoc//xqdoc:function[xqdoc:annotations]!
                  map:entry(
                        xqdoc:name || "#" || @arity,
                        xqd:annots(xqdoc:annotations/xqdoc:annotation,$ns)
                   )
   let $v:=$xqdoc//xqdoc:variable[xqdoc:annotations]!
                 map:entry(
                   xqdoc:name ,
                   xqd:annots(xqdoc:annotations/xqdoc:annotation,$ns)
                 )
  return map:merge(($f,$v))
         
};

(: return annotation map for a name 
 :  map{ $ns: map{
 :        $aname: $values
 :      }
 : }
 :)
declare function xqd:annots(
 $annots as element(xqdoc:annotation)*,
 $ns as map(*)
) as map(*)
{
 map:merge( 
 for $a in $annots
 group by $prefix:=substring-before($a/@name,":")
 return for $p in $prefix
                  return map:entry(
                     $ns?($p),
                     map:merge((
                     for $x in $a
                     group by $aname:=if(contains($x/@name,":")) then substring-after($x/@name,":") else $x/@name
                     return map:entry($aname,$x/*/string())
                  ))
                )
)};        