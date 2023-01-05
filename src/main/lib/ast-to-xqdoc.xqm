xquery version "3.1";
(:~
create xqdoc from parse tree 
 @Copyright (c) 2022 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
 @TODO refs,external
:)
 module namespace xqdc = 'quodatum:xqdoca.model.xqdoc';

import module namespace xqcom = 'quodatum:xqdoca.model.comment' at "comment-to-xqdoc.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ default options :)
declare variable $xqdc:defaults:=map{
                          "body-full": false(),  (: include full source as xqdoc:body :)
                          "body-items": true(), (: include item (fn,var) source as xqdoc:body :)
                          "refs": true()        (: include xref info :)
                          };

(:~ build xqdoc from parse tree :)
declare function xqdc:build($parse as element(XQuery))
as element(xqdoc:xqdoc)
{
   xqdc:build($parse,$xqdc:defaults)
};

(:~ build xqdoc from parse tree 
 @param $opts {body:, refs:}
:)
declare function xqdc:build($parse as element(XQuery),$opts as map(*))
as element(xqdoc:xqdoc)
{
  let $mod:= $parse/Module
  return <xqdoc:xqdoc xmlns:xqdoc="http://www.xqdoc.org/1.0">
    <xqdoc:control>
      <xqdoc:date>{ current-dateTime() }</xqdoc:date>
      <xqdoc:version>1.2</xqdoc:version>
	  </xqdoc:control>{
	   xqdc:module($mod, $opts)
    ,xqdc:imports($mod)
    ,xqdc:namespaces($mod)
    ,xqdc:variables($mod,$opts)
    ,xqdc:functions($mod,$opts)
  }</xqdoc:xqdoc>
};

declare %private function xqdc:module($parse as element(Module), $opts as map(*))
as element(xqdoc:module)
{
let $type:=if($parse/LibraryModule) then "library" else "main"
let $name:=$parse/LibraryModule/ModuleDecl/NCName/string()

let $uri:=$parse/LibraryModule/ModuleDecl/URILiteral/xqdc:unquote(.)
let $uri:= if(exists($uri)) then $uri else replace($opts?url,".*/(.*)","$1")

let $com:=$parse/(LibraryModule|MainModule)!xqcom:comment(.)
          (: =>trace("DD") :)
          
return 
    <xqdoc:module type="{ $type }">
      <xqdoc:uri>{ $uri }</xqdoc:uri>
      <xqdoc:name>{ $name }</xqdoc:name>
      { $com }
      { util:if($opts?body-full,xqdc:body(root($parse)))} 
    </xqdoc:module>
};

declare %private function xqdc:imports($parse as element(Module))
as element(xqdoc:imports)?
{
  let $imports:=$parse/(MainModule|LibraryModule)/Prolog/Import/ModuleImport
              
  return if(exists($imports))
         then <xqdoc:imports>{
                  for $import in $imports
                  let $uri:= $import/URILiteral/string(.)
                  return  <xqdoc:import type="library">
                            <xqdoc:uri>{ xqdc:unquote($uri[1]) }</xqdoc:uri>
                            {tail($uri)!<xqdoc:at>{ xqdc:unquote(.) }</xqdoc:at> 
                             ,xqcom:comment($import)}
                          </xqdoc:import>
                  }</xqdoc:imports>
}; 

declare %private function xqdc:namespaces($parse as element(Module))
as element(xqdoc:namespaces)
{
  let $this:=if($parse/LibraryModule)
             then
                let $name:=$parse/LibraryModule/ModuleDecl/(.|NCName)/NCName[not(NCName)]/string()
                let $uri:=$parse/LibraryModule/ModuleDecl/URILiteral/StringLiteral/xqdc:unquote(.)
                return <xqdoc:namespace prefix="{ $name}" uri="{ $uri }"/>
  return <xqdoc:namespaces>{
        $this,
        for $import in $parse/(MainModule|LibraryModule)/Prolog/(Import/ModuleImport|NamespaceDecl)
        (: let $_:=trace($import,"FFF:" ) :)
        let $uri:=($import/URILiteral/StringLiteral)[1]=>xqdc:unquote()
        let $prefix:= $import/NCName/string()
        return <xqdoc:namespace prefix="{ $prefix}" uri="{ $uri }">{
                   xqcom:comment($import)
        }</xqdoc:namespace>
  }</xqdoc:namespaces>
  (: =>trace("NSSS") :)
};  

declare %private function xqdc:variables($parse as element(Module), $opts as map(*))
as element(xqdoc:variables)
{
  <xqdoc:variables>{ 
	$parse/*/Prolog/AnnotatedDecl/VarDecl!xqdc:variable(., $opts)
	}</xqdoc:variables>
};

declare %private function  xqdc:variable($vardecl as element(VarDecl), $opts as map(*))
as element(xqdoc:variable){
	let $name:=$vardecl/VarName/string()
  (: =>trace("VAR: ") :)

  return <xqdoc:variable>
     {$vardecl/TOKEN[.="external"]!attribute external {"true"}}
			<xqdoc:name>{ $name }</xqdoc:name>
      { $vardecl/parent::AnnotatedDecl/Annotation
        !<xqdoc:annotations>{xqdc:annotation(.)}</xqdoc:annotations>,
 
		  xqcom:comment($vardecl/..),
      $vardecl/TypeDeclaration/SequenceType!xqdc:type(.),
      xqdc:refs($vardecl),
      util:if($opts?body-items,xqdc:body($vardecl)) }
		</xqdoc:variable>
};

declare %private function xqdc:functions($module as element(Module), $opts)
as element(xqdoc:functions)
{
  let $items:= $module/*/Prolog/AnnotatedDecl/FunctionDecl 
  let $_:=trace(count($items),"FUNDEC")  
  return <xqdoc:functions>{  
          $items!xqdc:function(., $opts)
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

declare %private function xqdc:function($fundecl as element(FunctionDecl), $opts as map(*))
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

     { if($fundecl/parent::AnnotatedDecl[Annotation])
      then <xqdoc:annotations>{
              $fundecl/parent::AnnotatedDecl/Annotation!xqdc:annotation(.) }
          </xqdoc:annotations>}
      
      <xqdoc:signature>{$fundecl/((*|text()) except EnclosedExpr)/string()
                        =>string-join(" ")=>normalize-space()
       }</xqdoc:signature>

      <xqdoc:parameters>
         { $params!xqdc:param(.) }
      </xqdoc:parameters>

      {   xqdc:return($fundecl)
        , xqdc:refs($fundecl) 
        ,util:if($opts?body-items,xqdc:body($fundecl)) }
  </xqdoc:function>
};


(: xqdoc parameter from parse Param :)
declare %private function xqdc:param($param as element(Param))
as element(xqdoc:parameter)
{
 <xqdoc:parameter>
 	  <xqdoc:name>{ $param/EQName/string() }</xqdoc:name>
	 { $param/TypeDeclaration/SequenceType!xqdc:type(.)}
 </xqdoc:parameter>
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
      ,$type/*=>head()=>string() 
 }</xqdoc:type>
};

(:~ sequence of invoked and ref-variable elements :)
declare %private function xqdc:refs($ast as element(*))
as element(*)*
{
 (:~ let $_:=trace("refs",$ast) ~:)
  () 
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
          return <xqdoc:literal type="xs:string">{ string($a) }</xqdoc:literal>
        case element(TOKEN)  | element(EQName) | text()  (: ignore these :)
          return ()
        default 
        return ( prof:dump(name($a),"DDDDD") ,error())
}</xqdoc:annotation>
};


(:~  remove start and end quote marks :)
declare %private function xqdc:unquote($s as xs:string)
as xs:string{
replace($s,'^[''"](.*)[''"]$','$1')
};

