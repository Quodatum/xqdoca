xquery version "3.1";
(:~
<p>Analyse XQuery source</p>
  @copyright (c) 2019-2026 Quodatum Ltd
  @author Andy Bunce, Quodatum, License: Apache-2.0
 :)
 
module namespace xqd = 'quodatum:xqdoca.model';

import module namespace xqp = 'quodatum:xqdoca.parser' at "parser.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
import module namespace xqa = 'quodatum:xqdoca.model.annotations' at "annotations.xqm";
import module namespace xqdc = 'quodatum:xqdoca.model.xqdoc' at 'ast-to-xqdoc.xqm';

declare namespace xqdoc="http://www.xqdoc.org/1.0";


(:~ restxq namespace :)
declare variable $xqd:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqd:nsANN:='http://www.w3.org/2012/xquery';
(: statically known modules :)
declare variable $xqd:staticNS:=json:doc("../etc/models/basex.json", map { 'format': 'xquery' });
(:~ 
 : @see https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods 
 :)
declare variable $xqd:methods:=("GET","HEAD","POST","PUT","DELETE","PATCH");


(:~  file paths below folder with matching extensions
 @param $efolder start folder
 @param $extensions string using Glob_Syntax 
 @see https://docs.basex.org/wiki/Commands#Glob_Syntax
 :)
declare function xqd:find-sources($efolder as xs:string, $extensions as xs:string)
as xs:string*
{
  file:list($efolder,true(),$extensions)[matches(.,"[^\\/]$")]
};

(:~
  load and parse source xquery files
  @param $efolder root path for source files
  @param $files files to process as relative paths
  @param $platform target XQuery engine e.g "basex"
  @return state map
  @error xqd:platform "Unknown platform: "
 :)
declare function xqd:snap($efolder as xs:string, $files as xs:string*,$opts as map(*))
as map(*)
{
  let $platform:=$opts?platform
let $_:=if(map:contains($xqp:xparse_opts,$platform)) 
        then () 
        else error(xs:QName('xqd:platform'),"Unknown platform: " || $platform) 
let $folder:= translate($efolder,"\","/")
let $_:=trace(count($files),"files :")
return map{ 
             "base-uri": $folder,
             "platform": $platform,

             "files": for $file at $pos in $files
                      let $id:= "F" || format-integer($pos,"000000")
                      let $full:= xqd:path-tidy(file:resolve-path($file,$efolder))
                                  =>trace(``[FILE `{ $pos }` :]``)
                      let $spath:= translate($file,"\","/")
                      let $analysis:= xqd:analyse($full, $spath, $opts)

                      let $base:=map{
                              "index": $pos,
                              "path": translate($file,"\","/"),
                              "href": ``[modules/`{ $id }`/]``
                               }
                      return map:merge(($base,$analysis))  
           }

};

declare function xqd:path-tidy($p as xs:string) as xs:string{
  let $p:=tokenize($p,"\\")
  let $f:=function($res,$this){
    if($this="..") 
    then tail($res)
    else ($this,$res)
  }
  let $a:= fold-left($p,(),$f)
  return string-join(reverse($a),"/")
};

declare function xqd:snap($efolder as xs:string, $platform as xs:string)
as map(*)
{
 xqd:snap($efolder , $platform ,"*.xqm,*.xq,*.xquery,*.xqy")
};


(:~ 
 : Generate parse and xqdoc for xquery at location $url 
 : @param $url xquery source
 : @param platform xquery platform id
 : @param $opts xqdoca opts
 : @result map keys of {xqdoc: <xqdoc:xqdoc/>
, xqparse: <XQuery/>
 }
 :)
declare function xqd:analyse($url as xs:string, $spath as xs:string, $opts as map(*))
as map(*)
{  
   let $xq as xs:string := unparsed-text($url)
   let $parse:= xqp:parse($xq,$opts?platform)
   let $isParsed:=  $parse instance of element(XQuery)
   let $result:= map{ 
              "xqparse": $parse,
              "isParsed":  $parse instance of element(XQuery)
              }
   
   let $analysis:= if($isParsed)
                   then let $xqdoc:=  xqdc:build($parse,$spath,$xqd:staticNS,$opts)                    
                     let $namespaces:= xqd:namespaces( $xqdoc, $opts?platform) 
                                                  (:~ =>trace("prefixes: ") ~:)
                      let $uri:= $xqdoc/xqdoc:module/xqdoc:uri/string(.)                 
                      return map{
                                "xqdoc": $xqdoc, 
                                "prefix": xqd:prefix-for-ns($uri,$namespaces),
                                "namespaces": $namespaces,
                                "annotations": xqd:anno($xqdoc,$opts?platform), (: sequence map{annotation:, xqdoc: } :)
                                "namespace":$xqdoc/xqdoc:module/xqdoc:uri/string(), 
                                "default-fn-uri": xqp:default-fn-uri($parse)      
                                }
                    else prof:dump($url,"PARSE FAIL: ")
    return ($result,$analysis)=>map:merge()                         
 
};

(:~ 
 : all annotations in xqdoc as { annotation:{{name: uri:},xqdoc:}}
 :)
declare function xqd:anno($xqdoc as element(xqdoc:xqdoc),$platform as xs:string)
as map(*)*
{
  let $ns:= xqd:namespaces($xqdoc,$platform)
 for $a in $xqdoc//xqdoc:annotation
 let $name:=xqn:qmap($a/@name,$ns,$xqd:nsANN)
 (:~ let $_:=trace($a,"ANNNNO: ") ~:)
 return map{"annotation":$name, "xqdoc": $a} 
};

(:~ return 'library','main','#ERROR' 
:)
declare function xqd:file-parsed-type($file as map(*))
as xs:string{ if($file?xqparse/name()="ERROR") then 
      "#ERROR"
   else
       $file?xqdoc/xqdoc:module/@type/string() 
};

(:~ 
 : extract set of namespace declarations from XQuery parse descendants to map{prefix->uri}
 :)
declare function xqd:namespaces-xqdoc($n as element(xqdoc:xqdoc))
as map(*)
{
(
  $n/xqdoc:namespaces/xqdoc:namespace !map:entry(@prefix/string(),@uri/string()) )=>map:merge()
(: =>trace("NSP: ") :)
};


(:~ return sequence of maps describing restxq ordered by rest:path
 : {uri:.., 
 : methods : {METHODS: {id:.., uri:.. ,function:}}
 : }
 :)
declare function xqd:rxq-paths($model)
as map(*)* 
{
let $reports:= xqd:annots-rxq($model)
(: map keyed on uris -ensure starts with / :)
let $fix:=function($a) as xs:string{if(starts-with($a,"/")) then $a else "/" || $a}
let $data:=map:merge(
          for $report in $reports
          group by $uri:=$report?annot/xqdoc:literal
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
 :  "file": $f,
 :  "annot": $annot,
 :  "description": $function/xqdoc:comment/xqdoc:description/node()
 :  "given": $name/string(),
 :  "uri": $qmap?uri, 
 :  "name": $lname, 
 :   "xqdoc": $e }
 :)
declare function xqd:annots-rxq($model as map(*))
as map(*)*
{
  for $f  in $model?files[?isParsed]
  for $annot in xqd:annotations($f?xqdoc, $xqd:nsRESTXQ,"path")
  let $function:= $annot/../..
  let $a:=((xqa:name-detail($function,$f),
            map{
                "file": $f,
                "annot": $annot,
                "description": $function/xqdoc:comment/xqdoc:description/node() 
                 }
               ))
   return map:merge($a)
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
declare function xqd:methods($annots  as element(xqdoc:annotations)?,
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
declare 
%private 
function xqd:namespaces($xqdoc as element(xqdoc:xqdoc))
as map(*)
{
  let $ns:=$xqdoc/xqdoc:namespaces/xqdoc:namespace
  return $ns
        !map:entry(string(@prefix),string(@uri))
        =>map:merge()
};

(:~  map of known namespaces including static 
like inspect:static-context((),"namespaces") 
:)
declare function xqd:namespaces($xqdoc as element(xqdoc:xqdoc),$platform as xs:string)
as map(*)
{(
  xqd:namespaces-xqdoc($xqdoc)
  (: =>trace("NS@xqdoc: ") :)
 ,xqn:static-prefix-map($platform)
) =>map:merge()
};

(:~ files that import given namespace :)
declare function xqd:where-imported($files as map(*)*, $uri as xs:string?)
as map(*)*
{ $files[?xqdoc/xqdoc:imports/xqdoc:import[xqdoc:uri=$uri]]
};

(: return  map{   imported-ns:(files that import...) }  :)
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

(: return  map, keys are imported ns, values are sequence of files where imported:)
declare function xqd:defs($model as map(*))
as map(*)
{ 
(
  for $f in $model?files
  group by $ns:=$f?namespace
  return map:entry( $ns, $f) ) =>map:merge(map { 'duplicates': 'combine' })
};


(:~ expand specials in target url, i.e. {project\} and {webpath\}
 :)
declare function xqd:target($target as xs:string,$opts as map(*))
as xs:string
{
 let $f:=function-lookup(QName("http://basex.org/modules/db","option"),1)
 let $webpath:= if(exists($f)) then $f("webpath") else "webpath"
return $target =>replace("\{project\}",string($opts?project))
=>replace("\{webpath\}",translate($webpath,"\","/"))
}; 

(:~
 @return map listing imports and usage
:)
declare function xqd:import-count($xqd as element(xqdoc:xqdoc),$model as map(*))
as map(*)
{
  let $uri:=$xqd/xqdoc:module/xqdoc:uri/string()
  let $importing:=xqd:imports($model)?($uri)
  let $imports:=$xqd/xqdoc:imports
  return map{
     "uri": $uri,    
     "imports": $imports/xqdoc:import,
     "importedby":  $importing
  }
};

(:~ the prefixes defined for this namespace in prefix map:)
declare function xqd:prefix-for-ns($namespace as xs:string,$prefixes as map(*))
as xs:string*{
map:for-each($prefixes,function($k,$v){if($v eq $namespace) then $k else()})
};
