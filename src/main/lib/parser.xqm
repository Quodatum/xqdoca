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

declare variable $xqp:trace as xs:boolean:=false();

 
(:~ default function namespace
 : NOTE if parse failed will return "http://www.w3.org/2005/xpath-functions"
 :)
declare function xqp:default-fn-uri($xqparse as element(XQuery))
as xs:string
{
  let $def-fn:= $xqparse/*//Prolog/DefaultNamespaceDecl
  return if( empty($def-fn) ) 
         then "http://www.w3.org/2005/xpath-functions"
         else $def-fn/URILiteral!substring(.,2,string-length(.)-2)
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
