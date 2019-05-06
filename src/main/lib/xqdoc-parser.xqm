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
 : <h1>xqdoc-parser.xqm</h1>
 : <p>generate and Analyse XQuery parse tree</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace xqp = 'quodatum:xqdoca.parser';
import module namespace xp="expkg-zone58:text.parse";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqp:ns-fn:="http://www.w3.org/2005/xpath-functions";

declare variable $xqp:xparse_opts:=map{
                                       "lang":"xquery",
                                       "version":"3.1 basex",
                                       "flatten":true()
                                     };
(:~  enrich basex builtin xqdoc by
 : adding function source
 : xref info
 :)
declare function xqp:enrich($xqdoc as element(xqdoc:xqdoc),$xqparse as element(XQuery))
as element(xqdoc:xqdoc)
{
  let $fmap:=xqp:funmap($xqparse)

  let $moduri:=$xqdoc/xqdoc:module/xqdoc:uri/string()
   let $expand:=xqn:map-prefix(?,$xqp:ns-fn, xqp:prefixes($xqparse))
   (: insert function source :)
  let $xqdoc:= $xqdoc transform with {
    for $f in ./xqdoc:functions/xqdoc:function
    let $name:=xqn:qname($f/xqdoc:name,$expand)
    let $key:=concat("Q{",$name?uri,"}",$name?name,"#",$f/@arity)
    let $parse:= map:get($fmap,$key)
    return if(map:contains($fmap,$key))then
                  (
                    insert node <xqdoc:body>{$parse/string()}</xqdoc:body> into $f,
                    insert node xqp:references($parse,$expand) into $f
                )
               else
                  let $a:=trace(map:keys($fmap))
                  return error()  
  }
  return $xqdoc
};

(:~ scan tree below $e for references
 : @return sequence of xqdoc:invoked and xqdoc:var-refences elements
 :)
declare function xqp:references($e as element(*),$expand as function(*))
as element(*)*
{
  $e//FunctionCall!xqp:funcall(.,$expand),
  $e//ArrowExpr!xqp:funcall(.,$expand),
  $e//VarRef!xqp:ref-variable(.,$expand) 
};


(:~  build invoked nodes for function call
 : @param $e is FunctionCall or ArrowExpr 
 :)
declare function xqp:funcall($e as element(*),$expand as function(*))
as element(xqdoc:invoked)
{
let $commas:=count($e/ArgumentList/TOKEN[.=","])
let $hasarg:=boolean($e/ArgumentList/*[not(TOKEN)])
let $arity:= if($hasarg) then 1+$commas else 0
let $arity:= if(name($e)="ArrowExpr") then $arity +1 else $arity
let $fname:= if($e/QName) then $e/QName/string() else $e/TOKEN[1]/string() 
let $qname:=xqn:qname($fname,$expand)
 return <xqdoc:invoked arity="{ $arity }">
         <xqdoc:uri>{ $qname?uri }</xqdoc:uri>
         <xqdoc:name>{ $qname?name }</xqdoc:name>
        </xqdoc:invoked>   
};

(:~  build invoked nodes for function call
 : @param $e is variable reference @@TODO
 :)
declare function xqp:ref-variable($e as element(*),$expand as function(*))
as element(xqdoc:ref-variable)
{

let $fname:= if($e/QName) then $e/QName/string() else $e/TOKEN[1]/string() 
let $qname:=xqn:qname($fname,$expand)
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
declare function xqp:prefixes($e as element())
as map(*)
{
 (xqp:namespaces($e),xqn:static-prefix-map())
 =>map:merge()
};

(:~  map of function declarations
 : @result map{key:...,value:xquery parse }
 :)
declare function xqp:funmap($e as element(XQuery))
as map(*)
{
 let $expand:=xqn:map-prefix(?,$xqp:ns-fn, xqp:prefixes($e))
 let $items:=for $f in $e//FunctionDecl
             let $name:=if($f/QName[1]) then
                        xqn:qname($f/QName[1],$expand)
                        else if($f/URIQualifiedName) then
                        xqn:uriqname($f/URIQualifiedName)
                        else error()
             let $arity:=count($f/(Param|ParamList/Param))
             let $key:=concat("Q{",$name?uri,"}",$name?name,"#",$arity)
             return map:entry($key,$f)
 return map:merge($items)
};

(:~ parse XQuery 
 : result is <XQuery> or <ERROR>
 :)
declare function xqp:parse($xq as xs:string)
as element(*)
{  
  xp:parse($xq || "",$xqp:xparse_opts) 
};

