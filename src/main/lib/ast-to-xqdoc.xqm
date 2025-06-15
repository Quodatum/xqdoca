xquery version "3.1";
(:~
create xqdoc from parse tree 
 @Copyright (c) 2026 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
 @TODO refs
:)
 module namespace xqdc = 'quodatum:xqdoca.model.xqdoc';

import module namespace xqcom = 'quodatum:xqdoca.model.comment' at "comment-to-xqdoc.xqm";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";



(:~ build xqdoc from XQuery parse tree 
 @param $parse xml parse tree
 @param $url source path
 @param $opts {"body-full","body-items","refs"}

:)
declare function xqdc:build($parse as element(XQuery),
                            $url as xs:string,
                            $opts as map(*)
) as element(xqdoc:xqdoc)
{
  let $version:=$opts?xqdoc?version
  let $def-fn-uri:=xqdc:default-fn-uri($parse)
  let $mod:= $parse/Module
  let $staticNS:=xqn:ns-all($mod,$opts?platform)
 
  return <xqdoc:xqdoc xmlns:xqdoc="http://www.xqdoc.org/1.0">
    <xqdoc:control>
      <xqdoc:date>{ current-dateTime() }</xqdoc:date>
      <xqdoc:version>{$version}</xqdoc:version>
	  </xqdoc:control>{
	   xqdc:module($mod, $url, $opts)

    ,xqdc:wrap($parse/Module/(MainModule|LibraryModule)/Prolog/Import/ModuleImport
                ,xs:QName("xqdoc:imports")
                ,xqdc:import(?,$opts))
 
    ,xqdc:namespaces($mod,$staticNS)
    ,xqdc:variables($mod,$staticNS, $def-fn-uri,$opts)
    ,xqdc:functions($mod ,$staticNS, $def-fn-uri,$opts)
  }</xqdoc:xqdoc>
};

(:~ generate xqdoc:module from parse 
@param $url source location, the last segment is written to xqdoc:uri for main modules
:)
declare %private function xqdc:module($parse as element(Module),$url as xs:string, $opts as map(*))
as element(xqdoc:module)
{
let $type:=if($parse/LibraryModule) then "library" else "main"
let $name:=$parse/LibraryModule/ModuleDecl/NCName/string()

let $uri:=if($type eq 'library')
          then $parse/LibraryModule/ModuleDecl/URILiteral/xqdc:unquote(.) 
          else $url=>translate("\","/")=>replace(".*/(.*)","$1")

let $com:=util:or(xqcom:comment($parse)
                  ,xqcom:comment($parse/(LibraryModule|MainModule))
                 )
                (: =>trace("Mod comm: ") :)
          
return 
    <xqdoc:module type="{ $type }">
      <xqdoc:uri>{ $uri }</xqdoc:uri>
      <xqdoc:name>{ $name }</xqdoc:name>
      { $com }
      { if(xqdc:opt($opts,"body-full")) then xqdc:body(root($parse))} 
    </xqdoc:module>
};

(:~ xqdoc:import from ModuleImport :)
declare %private function xqdc:import($import as element(ModuleImport), $opts as map(*))
as element(xqdoc:import)
{
   let $uri:= $import/URILiteral/string(.)
   return <xqdoc:import type="library">
              <xqdoc:uri>{ xqdc:unquote($uri[1]) }</xqdoc:uri>
              {(if(xqdc:is11($opts)) then tail($uri)!<xqdoc:at>{ xqdc:unquote(.) }</xqdoc:at>) 
                ,xqcom:comment($import)}
          </xqdoc:import>
};


declare %private function xqdc:namespaces(
  $parse as element(Module),
  $staticNS as map(*)
) as element(xqdoc:namespaces)
{
  let $this:=if($parse/LibraryModule)
             then
                let $name:=$parse/LibraryModule/ModuleDecl/(.|NCName)/NCName[not(NCName)]/string()
                let $uri:=$parse/LibraryModule/ModuleDecl/URILiteral/StringLiteral/xqdc:unquote(.)
                return <xqdoc:namespace prefix="{ $name}" uri="{ $uri }"/>
  let $namespaces:=(
        $this,
        for $import in $parse/(MainModule|LibraryModule)/Prolog/(Import/ModuleImport|NamespaceDecl)
        (: let $_:=trace($import,"FFF:" ) :)
        let $uri:=($import/URILiteral/StringLiteral)[1]=>xqdc:unquote()
        let $prefix:= $import/NCName/string()
        return <xqdoc:namespace prefix="{ $prefix}" uri="{ $uri }">{
                   xqcom:comment($import)
        }</xqdoc:namespace>
  )
   let $prefixes:=$parse//QName[contains(.,":")]!substring-before(.,":")=>distinct-values()
   let $prefixes:=$prefixes[not(.=$namespaces/@prefix)]
   let $static:=$prefixes!(if(map:contains($staticNS,.))
                          then <xqdoc:namespace prefix="{ . }" uri="{ $staticNS(.) }" />
                          )
 
  return <xqdoc:namespaces>{ $namespaces,$static }</xqdoc:namespaces>
  (: =>trace("NSSS") :)
};  

declare %private function xqdc:variables($parse as element(Module), 
                                         $staticNS as map(*),
                                         $def-fn-uri as xs:string,
                                         $opts as map(*))
as element(xqdoc:variables)
{
  <xqdoc:variables>{ 
	$parse/*/Prolog/AnnotatedDecl/VarDecl!xqdc:variable(., $staticNS ,$def-fn-uri, $opts)
	}</xqdoc:variables>
};

declare %private function  xqdc:variable($vardecl as element(VarDecl), 
                                         $staticNS as map(*),
                                         $def-fn-uri as xs:string,
                                         $opts as map(*))
as element(xqdoc:variable){
	let $name:=$vardecl/VarName/string()
  (: =>trace("VAR: ") :)

  return <xqdoc:variable>
     { if(xqdc:is11($opts)) 
       then $vardecl/TOKEN[.="external"]!attribute external {"true"} }
			<xqdoc:name>{ $name }</xqdoc:name>
      { 
         xqcom:comment($vardecl/..)
        ,xqdc:wrap($vardecl/parent::AnnotatedDecl/Annotation
                   ,xs:QName('xqdoc:annotations')
                   ,xqdc:annotation#1) 

       ,$vardecl/TypeDeclaration/SequenceType!xqdc:type(.)

       ,if(xqdc:is11($opts)) then xqdc:refs($vardecl,$staticNS,$def-fn-uri)

       ,if(xqdc:is11($opts) and xqdc:opt($opts,"body-items"))
        then xqdc:body($vardecl) }
		</xqdoc:variable>
};

declare %private function xqdc:functions($module as element(Module), 
                                         $staticNS as map(*),
                                         $def-fn-uri as xs:string, 
                                         $opts as map(*))
as element(xqdoc:functions)
{
  let $items:= $module/*/Prolog/AnnotatedDecl/FunctionDecl  
  return <xqdoc:functions>{  
          $items!xqdc:function(.,$staticNS,$def-fn-uri, $opts)
          ,xqdc:main($module/MainModule/QueryBody)
        (:~ @TODO
        if ($body) then (
              insert node xqp:main($body) as last into xqdoc:functions,
              insert node <xqdoc:namespace prefix="local" uri="http://www.w3.org/2005/xquery-local-functions"/>
                    into xqdoc:namespaces
                  ) ~:)
                      
          }</xqdoc:functions>
};

(:~  create dummy function for main modules
@todo pull real comments
 :)
 declare function xqdc:main($body as element(*)?)
 as element(xqdoc:function)?
 {
   if($body) then
        <xqdoc:function arity="0">
          <xqdoc:comment>
          <xqdoc:description>The query body.</xqdoc:description>
          <xqdoc:custom tag="note">pseudo main function as per http//xqdoc.org</xqdoc:custom>
         </xqdoc:comment>
         <xqdoc:name>local:xqDoc-main</xqdoc:name>
         <xqdoc:signature>local:xqDoc-main()</xqdoc:signature>
         <xqdoc:body>{string($body)}</xqdoc:body>
         </xqdoc:function>
 };

declare %private function xqdc:function($fundecl as element(FunctionDecl),
                                        $staticNS as map(*),
                                        $def-fn-uri as xs:string,
                                        $opts as map(*))
as element(xqdoc:function){
  let $params:= $fundecl/(.|ParamList)/Param
  return <xqdoc:function>
    {  $fundecl/TOKEN[.="external"]!attribute external {"true"},
       attribute arity {count($params)},
      xqcom:comment(util:or($fundecl/..,$fundecl/../Prolog))}
		<xqdoc:name>{ 
      $fundecl/EQName/string() 
      (:~ =>trace("FUN: ") ~:)
      }</xqdoc:name>

     { $fundecl/parent::AnnotatedDecl/Annotation
       =>xqdc:wrap( xs:QName('xqdoc:annotations'), xqdc:annotation#1) }
      
      
      <xqdoc:signature>{$fundecl/((*|text()) except FunctionBody)/string()
                        =>string-join(" ")=>normalize-space()
       }</xqdoc:signature>

      {   xqdc:parameters($params)  
        , xqdc:return($fundecl)
        , xqdc:refs($fundecl,$staticNS,$def-fn-uri) 
        ,if(xqdc:opt($opts,"body-items")) then xqdc:body($fundecl) }
  </xqdoc:function>
};


(: xqdoc parameter from parse Param :)
declare %private function xqdc:parameters($params as element(Param)*)
as element(xqdoc:parameters)?
{
  if(exists($params))
  then <xqdoc:parameters>{
          $params!<xqdoc:parameter>
                      <xqdoc:name>{ EQName/string() }</xqdoc:name>
                      { TypeDeclaration/SequenceType!xqdc:type(.)}
                  </xqdoc:parameter>
      }</xqdoc:parameters>
};

(: xqdoc return from parse fundecl :)
declare %private function xqdc:return($fundecl as element(FunctionDecl))
as element(xqdoc:return)?
{
  if($fundecl/SequenceType)
  then <xqdoc:return>{ xqdc:type($fundecl/SequenceType) }</xqdoc:return>
};

(:~ xqdoc type from parse sequencetype :)
declare %private function xqdc:type($type as element(SequenceType)?)
as element(xqdoc:type)?
{
  if(exists($type))
  then 
 <xqdoc:type >{
       if($type/OccurrenceIndicator)
       then attribute occurrence {$type/OccurrenceIndicator/string()}
      ,string-join($type/*[not(self::OccurrenceIndicator)])
 }</xqdoc:type>
};

(:~ sequence of invoked and ref-variable elements :)
declare %private function xqdc:refs($ast as element(*), 
                                    $staticNS as map(*),
                                    $def-fn as xs:string)
as element(*)*
{
 (: let $_:=trace(substring($ast,65),"----refs->>") :)
 let $refs:=xqdc:references($ast, $staticNS , $def-fn )
 return $refs 
};

(:~  :)
declare %private 
function xqdc:invoked($element as xs:string,
                      $uri as xs:string,
                      $name as xs:string,
                      $arity as xs:integer?)
as element(*)
{
 element {$element} {
         $arity!attribute arity {$arity},
         <xqdoc:uri>{$uri}</xqdoc:uri>,
         <xqdoc:name>{$name}</xqdoc:name>
       }
 };
 
 (:~ source code :)
declare %private function xqdc:body($ast as element(*))
as element(xqdoc:body)
{
<xqdoc:body>{$ast/string()}</xqdoc:body>
 };
 
 (:~ annotation code 
 <pre>
 <Annotation><TOKEN>%</TOKEN><TOKEN>updating</TOKEN></Annotation>
 </pre>
 :)
declare %private function xqdc:annotation($anno as element(Annotation))
as element(xqdoc:annotation)
{
<xqdoc:annotation name="{ $anno/EQName/string() }">{
 for $a in $anno/*
 return typeswitch($a)
        case element(Literal) 
          return <xqdoc:literal type="xs:string">{ xqdc:unquote($a) }</xqdoc:literal>
        case element(TOKEN)  | element(EQName) | text()  (: ignore these :)
          return ()
        default 
        return ( prof:dump(name($a),"DDDDD") ,error())
}</xqdoc:annotation>
};

(:~  get boolean option :)
declare %private function xqdc:opt($opts as map(*), $opt as xs:string)
as xs:boolean{
   $opts?xqdoc($opt)=>xs:boolean() (: =>trace($opt || ": " ) :)
};

(:~ return true if o/p xqdoc 1.1 format :)
declare %private function xqdc:is11($opts as map(*))
as xs:boolean{
 $opts?xqdoc?version eq "1.1"
};

(:~ default function namespace
 : NOTE if parse failed will return "http://www.w3.org/2005/xpath-functions"
 :)
declare function xqdc:default-fn-uri($xqparse as element(XQuery))
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
declare  function xqdc:references($e as element(*),$prefixes as map(*), $def-fn as xs:string)
as element(*)*
{
  $e//FunctionCall!xqdc:invoke-fn(.,$prefixes, $def-fn),
  $e//NamedFunctionRef!xqdc:named-function-ref(.,$prefixes, $def-fn),
  (: $e//ArrowExpr!xqdc:invoke-arrow(.,$prefixes, $def-fn), :)
  $e//VarRef!xqdc:ref-variable(.,$prefixes, $def-fn) 
};

(:~  build invoked nodes for function call
 : @param $e is FunctionCall or ArrowExpr 
 :)
declare function xqdc:named-function-ref(
                 $e as element( (:  NamedFunctionRef :) ),
                 $prefixes as map(*),
                 $def-fn as xs:string)
as element(xqdoc:invoked)
{
let $arity:= $e//IntegerLiteral/string() 
let $fname:= $e//FunctionName/string()           
let $qname:=xqn:qmap($fname,$prefixes, $def-fn)
 return <xqdoc:invoked arity="{ $arity }">
         <xqdoc:uri>{ $qname?uri }</xqdoc:uri>
         <xqdoc:name>{ $qname?name }</xqdoc:name>
        </xqdoc:invoked> 
};


(:~  build invoked nodes for function call
 : @param $e is FunctionCall or ArrowExpr 
 :)
declare function xqdc:invoke-fn(
                 $e as element( (:  FunctionCall :) ),
                 $prefixes as map(*),
                 $def-fn as xs:string)
as element(xqdoc:invoked)*
{

let $commas:=count($e/ArgumentList/TOKEN[.=","])
let $hasarg:=boolean($e/ArgumentList/*[not(self::TOKEN)])
let $arity:= if($hasarg) then 1+$commas else 0
let $arity:= if(name($e)="ArrowExpr") then $arity +1 else $arity
let $fname:= $e/(FunctionEQName|QName|URIQualifiedName|TOKEN)/string()            
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
declare function xqdc:invoke-arrow($e as element(ArrowExpr),
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

(:~  build invoked nodes for declared var call
 : @param $e is variable reference 
 :)
declare function xqdc:ref-variable($e as element(*),$prefixes as map(*), $def-fn as xs:string)
as element(xqdoc:ref-variable)?
{
let $fname:= string($e)
return if(contains($fname,":")) (:ok? :)
       then let $qname:=xqn:qmap($fname, $prefixes, $def-fn)=>trace("------------VAR: ")
            return <xqdoc:ref-variable >
                      <xqdoc:uri>{ $qname?uri }</xqdoc:uri>
                      <xqdoc:name>{ $qname?name }</xqdoc:name>
                    </xqdoc:ref-variable>
        else ()   
};

(:~ if items then apply $fun to each and wrap result sequence in $qname :)
declare %private function xqdc:wrap($items as item()*,$qname as xs:QName,$fun as function(*))
as element(*)?{
  if(exists($items))
  then element {$qname}{ $items!$fun(.)}
};

(:~  remove start and end quote marks :)
declare %private function xqdc:unquote($s as xs:string)
as xs:string{
  replace($s,'^[''"](.*)[''"]$','$1')
};

