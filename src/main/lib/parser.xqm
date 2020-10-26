xquery version "3.1";
(:
 : Copyright (c) 2019-2020 Quodatum Ltd
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
 : <h1>xqdoc-parser.xqm</h1>
 : <p>generate and Analyse XQuery parse tree</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 

module namespace xqp = 'quodatum:xqdoca.parser';

import module namespace xp="expkg-zone58:text.parse";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";



(:~ xparser defaults :)
declare variable $xqp:xparse_opts:=map{
  "basex":  map{ "lang":"xquery", "version":"3.1 basex",  "flatten":true() }
};

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
      let $_:= trace($err:description ,"Enrich error: ")
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
 
   (: add xqDoc-main for main modules :)
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
              
  (: swap imports and namespaces basex err :) 
   let $xqdoc:= $xqdoc transform with {
                replace node xqdoc:namespaces with xqdoc:imports,
                replace node xqdoc:imports with xqdoc:namespaces
              }          
 
    (: default function namespace? :)
    let $def-fn:= xqp:default-fn-uri($xqparse)
                   
     let $fmap:=map:merge((
                xqp:funmap($xqparse, $prefixes, $def-fn),
                if($body) then map:entry("Q{http://www.w3.org/2005/xquery-local-functions}xqDoc-main#0",$body) else ()
         ))                       
   (: insert function source :)
  let $xqdoc:= $xqdoc transform with {
    for $f in ./xqdoc:functions/xqdoc:function
  
    let $name:=xqn:qmap($f/xqdoc:name,$prefixes, $def-fn)
    let $key:=concat("Q{",$name?uri,"}",$name?name,"#",$f/@arity)
    let $parse:= map:get($fmap,$key)
    return if(map:contains($fmap,$key))then
                   (   
                    insert node xqp:references($parse,$prefixes, $def-fn) into $f,
                    insert node <xqdoc:body>{$parse/string()}</xqdoc:body> into $f
                  )
               else
                  let $a:=trace(map:keys($fmap),"FMAP: ")
                  return error(xs:QName("xqp:enrich"),"key not found " || $key)  
  }
 
  return $xqdoc
};

(:~ default function namespace
 : NOTE if parse failed will return "http://www.w3.org/2005/xpath-functions"
 :)
declare function xqp:default-fn-uri($xqparse as element(*))
as xs:string
{
  let $def-fn:= $xqparse/*//Prolog/DefaultNamespaceDecl
  return if( empty($def-fn) ) then
                    "http://www.w3.org/2005/xpath-functions"
                  else
                   $def-fn/StringLiteral!substring(.,2,string-length(.)-2)
};

(:~ scan tree below $e for references
 : @param $expand function to map prefixes to namespaces
 : @return sequence of xqdoc:invoked and xqdoc:var-refences elements
 :)
declare function xqp:references($e as element(*),$prefixes as map(*), $def-fn as xs:string)
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
                 $e as element(FunctionCall),
                 $prefixes as map(*),
                 $def-fn)
as element(xqdoc:invoked)*
{
let $commas:=count($e/ArgumentList/TOKEN[.=","])
let $hasarg:=boolean($e/ArgumentList/*[not(TOKEN)])
let $arity:= if($hasarg) then 1+$commas else 0
let $arity:= if(name($e)="ArrowExpr") then $arity +1 else $arity
let $fname:= if($e/QName) then $e/QName/string() else $e/TOKEN[1]/string() 
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
let $fname:=$arrow/following-sibling::*[1]
let $arglist:=$arrow/following-sibling::*[2]
let $arity:=1+count($arglist/*[not(TOKEN)])
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
declare function xqp:namespaces($n as element())
as map(*)
{
(
  $n//(ModuleDecl|ModuleImport|NamespaceDecl)
  !map:entry(NCName[1]/string(),StringLiteral[1]/substring(.,2,string-length(.)-2))
)=>map:merge()  
};



(:~  map of known namespaces including static :)
declare function xqp:prefixes($e as element(),$platform as xs:string)
as map(*)
{(
  xqp:namespaces($e),
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
                             let $_:=trace($name,"name")
                             return error(xs:QName("xqp:funmap"), "bad name: ", $name)
             let $arity:=count($f/(Param|ParamList/Param))
             let $key:=concat("Q{",$name?uri,"}",$name?name,"#",$arity)
             return map:entry($key,$f)
 return map:merge($items)
};


(:~  create dummy function for main modules
 :)
 declare function xqp:main($body as element(*)?)
 as element(xqdoc:function)?
 {
   if($body) then
        <xqdoc:function arity="0">
          <xqdoc:comment>
          <xqdoc:description>pseudo main function</xqdoc:description>
         </xqdoc:comment>
         <xqdoc:name>local:xqDoc-main</xqdoc:name>
         <xqdoc:signature>local:xqDoc-main()</xqdoc:signature>
         <xqdoc:body>{string($body)}</xqdoc:body>
         </xqdoc:function>
   else
    ()
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
  xp:parse($xq || "",$xqp:xparse_opts($platform)) 
};

