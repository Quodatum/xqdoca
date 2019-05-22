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
module namespace xqd = 'quodatum:xqdoca.model';

import module namespace xqp = 'quodatum:xqdoca.parser' at "parser.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";

declare namespace xqdoc="http://www.xqdoc.org/1.0";



declare variable $xqd:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqd:nsANN:='http://www.w3.org/2012/xquery';

(:~  @see https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods :)
declare variable $xqd:methods:=("GET","HEAD","POST","PUT","DELETE","PATCH");


declare variable $xqd:platforms:= map{
  "basex": map{"parser": 42}
};

(:~
 : load and parse source xquery files
 : @param $efolder root path for source files
 : @param $platform target XQuery engine e.g "basex"
 : @return state map
 :)
declare function xqd:snap($efolder as xs:string, $platform as xs:string, $extensions as xs:string)
as map(*)
{
let $files:= file:list($efolder,true(),$extensions)
let $folder:= translate($efolder,"\","/")
return map{ 
             "base-uri": $folder,
             "platform": $platform,
             "project": tokenize($folder,"/")[last()-1],
             "files": for $file at $pos in $files
                      let $full:=concat($efolder || "/", $file=>trace("FILE: "))
                      let $spath:=translate($file,"\","/")
                      let $xqdoc:=xqd:analyse($full,$platform,map{"_source": $spath})
                      let $base:=map{
                        "path": $file,
                        "href": ``[modules/F`{ $pos }`/]``,
                        "namespace": $xqdoc?xqdoc/xqdoc:module/xqdoc:uri/string()
                      }
                      return map:merge(($base,$xqdoc))  
           }

};




(:~ generate xqdoc
 : result is <XQuery> or <ERROR>
 :)
declare function xqd:xqdoc($url as xs:string)
as element(xqdoc:xqdoc)
{  
 try{
   inspect:xqdoc($url)
 } catch * { 
   <xqdoc:xqdoc>{$err:code } - { $err:description }</xqdoc:xqdoc>
}
};

(:~ 
 : Generate xqdoc adding custom opts 
 : @param $url xquery source
 : @param platform xquery platform id
 : @param $opts custom tags to add
 : @result map keys of {xqdoc: <xqdoc:xqdoc/>, xqparse: <XQuery/> ,annotations:{}*}
 :)
declare function xqd:analyse($url as xs:string,$platform as xs:string,$opts as map(*))
as map(*)
{  
  let $xqd:=xqd:xqdoc($url)
  (: add custom tags :)
  let $enh:=$xqd transform with {
          for $tag in map:keys($opts)
          where xqdoc:module[@type="library"]
          return insert node <xqdoc:custom tag="_{ $tag }">{ $opts?($tag) }</xqdoc:custom> 
          into xqdoc:module[@type="library"]/xqdoc:comment
     }
  (: insert full source into module :)
  let $src:=fetch:text($url)   
  let $enh:=$enh transform with {
    if(xqdoc:module) then 
          insert node <xqdoc:body>{$src}</xqdoc:body> into xqdoc:module
    else
        ()
  }
  (: add enrichments from parse tree :)
  let $parse:=xqp:parse($src,$platform)
  let $enh:=try{
                          xqp:enrich($enh,$parse) 
                    }   catch * { 
                            let $_:= trace($err:description ,"Enrich error: ")
                            return $enh
                    } (: parse fails :)
  return map{"xqdoc": $enh, 
             "xqparse": $parse,
             "annotations":xqd:anno($enh)
              }
};

(:~ 
 : all annotations in xqdoc as { annotation:{{name: uri:},xqdoc:}}
 :)
declare function xqd:anno($xqdoc)
as map(*)*{
  let $ns:= xqd:namespaces($xqdoc)
 for $a in $xqdoc//xqdoc:annotation
 let $name:=xqn:qname-anno($a/@name,$ns)
 return map{"annotation":$name, "xqdoc": $a} 
};
         
(:~ return sequence of maps with maps uri and methods :)
declare function xqd:rxq-paths($model)
as map(*)* 
{
let $reports:= xqd:annots-rxq($model)  
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
declare function xqd:annots-rxq($model as map(*))
as map(*)*
{
  for $f at $index in $model?files
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



(:~ 
 : all namespaces in xqdoc as map{prefix.. uri}
  :)
declare function xqd:namespaces($xqdoc as element(xqdoc:xqdoc))
{
$xqdoc/xqdoc:namespaces/xqdoc:namespace
!map:entry(string(@prefix),string(@uri))
=>map:merge()
};

declare function xqd:where-imported($uri as xs:string,$model as map(*))
{
  $model?files[?xqdoc/xqdoc:imports/xqdoc:import[xqdoc:uri=$uri]]?namespace
};

(: return sequence of maps  are imported ns values are where imported:)
declare function xqd:imports($model)
as map(*)
{
map:merge(  
for $f in $model?files
 for $in in $f?xqdoc//xqdoc:import[@type="library"]
group by $ns:=$in/xqdoc:uri
return map:entry( $ns,  $f)
)
};

(:~ 
 : filter annotation by uri and name
 : @param $uri 1st item is uri, if 2nd then match name
 :)
declare function xqd:filter-annot($annots as map(*)*,$uri as xs:string*)
as map(*)*
{
  let $hit:=$annots?annotation[?uri=$uri[1]]
  return if(count($uri) eq 1) then
            $hit
         else
           $hit[?name=$uri[2]]
};

(:~  filter for updating :)
declare function xqd:anno-updating($anno as map(*)*)
as map(*)*
{
xqd:filter-annot($anno,("http://www.w3.org/2012/xquery", "updating"))
};

(:~  filter for rest :)
declare function xqd:anno-rest($anno as map(*)*)
as map(*)*
{
xqd:filter-annot($anno,("http://exquery.org/ns/restxq", "path"))
};
 