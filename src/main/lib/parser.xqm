xquery version "3.1";
(:~
<p>generate and Analyse XQuery parse tree</p>
@copyright (c) 2019-2022 Quodatum Ltd
@author Andy Bunce, Quodatum, License: Apache-2.0
:)

module namespace xqp = 'quodatum:xqdoca.parser';

import module namespace xp="expkg-zone58:text.parse";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";

declare namespace xqdoc="http://www.xqdoc.org/1.0";



(:~ xparser defaults :)
declare variable $xqp:xparse_opts:=map{
  "basex":  map{ "lang": "xquery", "version": "3.1 basex",  "flatten": false() }
  , "fat":  map{ "lang": "xquery", "version": "3.1 basex",  "flatten": false() }

};

declare variable $xqp:trace as xs:boolean:=true();

 (:~  Enrich trapping errors
 :)
declare function xqp:enrich-catch($xqdoc as element(xqdoc:xqdoc),
                                  $xqparse as element(*),
                                  $prefixes)
as element(xqdoc:xqdoc)
{
try{
      xqp:enrich($xqdoc,$xqparse,$prefixes) 
    }   catch * {
      let $err:=map{
        "code": $err:code, 
        "value": $err:value,
        "module": $err:module,
        "line-number": $err:line-number, (: line number where the error occurred:)
        "column-number": $err:column-number, (: column number where the error occurred :)
        "description": $err:description,
        "additional": $err:additional 
      } 
      let $_:= trace($err ,"Enrich error: ")
      return $xqdoc
} 
};

                                  
(:~  Enrich BaseX built-in xqDoc by
 : adding function source and X-ref info
 :)
declare function xqp:enrich(
                     $xqdoc as element(xqdoc:xqdoc),
                     $xqparse as element(XQuery),
                     $prefixes as map(*))
as element(xqdoc:xqdoc)
{
 
   (: add xqDoc-main for main modules
  let $body:= $xqparse//MainModule/*[2]
  let $xqdoc:= $xqdoc transform with {
               
                       if ($body) then (
                         insert node xqp:main($body) as last into xqdoc:functions,
                         insert node <xqdoc:namespace prefix="local" uri="http://www.w3.org/2005/xquery-local-functions"/>
                                into xqdoc:namespaces
                              )
                       else
                       ()
              }
              
    :)
 
    (: default function namespace? :)
    let $def-fn as xs:string:= xqp:default-fn-uri($xqparse)
     let $body:= $xqparse//MainModule/QueryBody             
     let $fmap:=map:merge((
                xqp:funmap($xqparse, $prefixes, $def-fn),
                if($body) 
                then map:entry("Q{http://www.w3.org/2005/xquery-local-functions}xqDoc-main#0",$body) 
                else ()
         ))
                     
   (: insert function source :)
  let $xqdoc:= $xqdoc transform with {
    for $f in ./xqdoc:functions/xqdoc:function
    let $name:=$f/xqdoc:name
    let $name:=xqn:qmap($name,$prefixes, $def-fn)
    let $key:=concat("Q{",$name?uri,"}",$name?name,"#",$f/@arity)
    let $parse:= map:get($fmap,$key)
    return if(map:contains($fmap,$key))then
                   (   
                    insert node xqp:references($parse,$prefixes, $def-fn) into $f,
                    insert node <xqdoc:body>{$parse/string()}</xqdoc:body> into $f
                  )
               else
                   error(xs:QName("xqp:enrich"),"key not found " || $key)  
  }
 
  return $xqdoc
};

(:~ default function namespace
 : NOTE if parse failed will return "http://www.w3.org/2005/xpath-functions"
 :)
declare function xqp:default-fn-uri($xqparse as element(XQuery))
as xs:string
{
  let $def-fn:= $xqparse/*//Prolog/DefaultNamespaceDecl
  return if( empty($def-fn) ) then
                    "http://www.w3.org/2005/xpath-functions"
                  else
                   $def-fn/URILiteral!substring(.,2,string-length(.)-2)
};

(:~ scan tree below $e for references
 : @param $expand function to map prefixes to namespaces
 : @return sequence of xqdoc:invoked and xqdoc:var-refences elements
 :)
declare  function xqp:references($e as element(*),$prefixes as map(*), $def-fn as xs:string)
as element(*)*
{
  $e//FunctionCall!xqp:invoke-fn(.,$prefixes, $def-fn),
  $e//ArrowExpr!xqp:invoke-arrow(.,$prefixes, $def-fn),
  $e//VarRef!xqp:ref-variable(.,$prefixes, $def-fn) 
};



(:~  build invoked nodes for function call
 : @param $e is FunctionCall or ArrowExpr 
 :)
declare function xqp:invoke-fn(
                 $e as element( (:  FunctionCall :) ),
                 $prefixes as map(*),
                 $def-fn)
as element(xqdoc:invoked)*
{

let $commas:=count($e/ArgumentList/TOKEN[.=","])
let $hasarg:=boolean($e/ArgumentList/*[not(self::TOKEN)])
let $arity:= if($hasarg) then 1+$commas else 0
let $arity:= if(name($e)="ArrowExpr") then $arity +1 else $arity
let $fname:= $e/(QName|URIQualifiedName|TOKEN)/string()            
let $_:= if(empty($fname)) then trace($e,"??????") 
let $qname:=xqn:qmap($fname,$prefixes, $def-fn)
 return <xqdoc:invoked arity="{ $arity }">
         <xqdoc:uri>{ $qname?uri }</xqdoc:uri>
         <xqdoc:name>{ $qname?name }</xqdoc:name>
        </xqdoc:invoked>   
};
(:~  build invoked nodes for arrow expression
 : @param $e is FunctionCall or ArrowExpr 
 :)
declare function xqp:invoke-arrow($e as element(ArrowExpr),
                                  $prefixes as function(*),
                                  $def-fn as xs:string)
as element(xqdoc:invoked)*
{
for $arrow in $e/TOKEN[. = "=&gt;"]
let $fname:=$arrow/(following-sibling::QName|following-sibling::TOKEN)
let $arglist:=$arrow/following-sibling::ArgumentList
let $arity:=1+count($arglist/*[not(self::TOKEN)])
let $qname:=xqn:qmap($fname,$prefixes, $def-fn)
 return <xqdoc:invoked arity="{ $arity }">
         <xqdoc:uri>{ $qname?uri }</xqdoc:uri>
         <xqdoc:name>{ $qname?name }</xqdoc:name>
        </xqdoc:invoked> 
};

(:~  build invoked nodes for function call
 : @param $e is variable reference @@TODO
 :)
declare function xqp:ref-variable($e as element(*),$prefixes as map(*), $def-fn as xs:string)
as element(xqdoc:ref-variable)
{

let $fname:= if($e/QName) then $e/QName/string() else $e/TOKEN[1]/string() 
let $qname:=xqn:qmap($fname, $prefixes, $def-fn)
 return <xqdoc:ref-variable >
         <xqdoc:uri>{ $qname?uri }</xqdoc:uri>
         <xqdoc:name>{ $qname?name }</xqdoc:name>
        </xqdoc:ref-variable>   
};



(:~ 
 : extract set of namespace declarations from XQuery parse descendants to map{prefix->uri}
 :)
declare function xqp:namespaces-parse($n as element())
as map(*)
{
(
  $n//(ModuleDecl|ModuleImport|NamespaceDecl)
  !map:entry(NCName[1]/string(),URILiteral[1]/substring(.,2,string-length(.)-2))
)=>map:merge()
=>trace("NSP: ")
};



(:~  map of known namespaces including static 
like inspect:static-context((),"namespaces") 
:)
declare function xqp:namespaces($e as element(),$platform as xs:string)
as map(*)
{(
  xqp:namespaces-parse($e),
 xqn:static-prefix-map($platform)
) =>map:merge()
};

(:~  map of function declarations
 : @result map where keys are Qname with # arity items are xqParse trees
 : @param $def-fn default function namespace
 :)
declare function xqp:funmap($e as element(XQuery),$prefixes as map(*),$def-fn as xs:string)
as map(*)
{
 let $items:=for $f in $e//FunctionDecl
             let $name:=$f/*[2]
             let $name:=if($name instance of element(QName)
                        or $name instance of element(TOKEN)) then
                              xqn:qmap($name,$prefixes,$def-fn)
                        else if($name instance of element(URIQualifiedName)) then
                                xqn:uriqname($name)
                        else 
                             error(xs:QName("xqp:funmap"), "bad name: ", $name)
             let $arity:=count($f/(Param|ParamList/Param))
             let $key:=concat("Q{",$name?uri,"}",$name?name,"#",$arity)
             return map:entry($key,$f)
 return map:merge($items)
};




 (:~ 
 : all namespaces in xqdoc as map{prefix.. uri}
  :)
declare 
%private 
function xqp:namespaces-xqdoc($xqdoc as element(xqdoc:xqdoc))
as map(*)
{
  $xqdoc/xqdoc:namespaces/xqdoc:namespace
  !map:entry(string(@prefix),string(@uri))
  =>map:merge()
};

(:~ parse XQuery 
 : result is <XQuery> or <ERROR>
 :)
declare function xqp:parse($xq as xs:string,$platform as xs:string)
as element(*)
{ 
  xp:parse($xq ,$xqp:xparse_opts($platform)) 
};

declare function xqp:trace($items as item()*,$label as xs:string)
as item()*
{  
  if($xqp:trace) then trace($items,$label)
};
