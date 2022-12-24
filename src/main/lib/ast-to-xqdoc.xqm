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
    ,$mod/LibraryModule/Prolog[ModuleImport]!xqdc:imports($mod)
    ,xqdc:namespaces($mod)
     (:~ =>trace("NS: ") ~:)
    ,xqdc:variables($mod,$opts)
    ,xqdc:functions($mod,$opts)
  }</xqdoc:xqdoc>
};

declare %private function xqdc:module($parse as element(Module), $opts as map(*))
as element(xqdoc:module)
{
let $type:=if($parse/LibraryModule) then "library" else "main"
let $name:=$parse/LibraryModule/ModuleDecl/NCName/string()

let $uri:=$parse/LibraryModule/ModuleDecl/StringLiteral/xqdc:unquote(.)
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
as element(xqdoc:imports)
{
  <xqdoc:imports>{
    for $import in $parse/LibraryModule/Prolog/ModuleImport
    let $s:=$import/StringLiteral!xqdc:unquote(.)
    return  <xqdoc:import type="library">
              <xqdoc:uri>{$s[1] }</xqdoc:uri>
            </xqdoc:import>
}</xqdoc:imports>
}; 

declare %private function xqdc:namespaces($parse as element(Module))
as element(xqdoc:namespaces)
{
  let $this:=if($parse/LibraryModule)
             then
                let $name:=$parse/LibraryModule/ModuleDecl/NCName/string()
                let $uri:=$parse/LibraryModule/ModuleDecl/StringLiteral/xqdc:unquote(.)
                return <xqdoc:namespace prefix="{ $name}" uri="{ $uri }"/>
  return <xqdoc:namespaces>{
        $this,
        for $import in $parse/LibraryModule/Prolog/(ModuleImport|NamespaceDecl)
        let $_:=trace($import,"III")
        let $uri:=$import/StringLiteral[1]=>xqdc:unquote()
        let $prefix:= $import/NCName/string()
        return <xqdoc:namespace prefix="{ $prefix}" uri="{ $uri }">{
                   xqcom:comment($import)
        }</xqdoc:namespace>
  }</xqdoc:namespaces>
};  

declare %private function xqdc:variables($parse as element(Module), $opts as map(*))
as element(xqdoc:variables)
{
  element {"xqdoc:variables"} { 
	$parse/*/Prolog/AnnotatedDecl/VarDecl!xqdc:variable(., $opts)
	}
};

declare %private function  xqdc:variable($vardecl as element(VarDecl), $opts as map(*))
as element(xqdoc:variable){
	let $name:=$vardecl/QName/string()

  return <xqdoc:variable>
     {$vardecl/TOKEN[.="external"]!attribute external {"true"}}
			<xqdoc:name>{ $name }</xqdoc:name>
      { $vardecl/parent::AnnotatedDecl/Annotation
        !<xqdoc:annotations>{xqdc:annotation(.)}</xqdoc:annotations>,
 
		  xqcom:comment($vardecl/..),
      $vardecl/TypeDeclaration!xqdc:type(.),
      xqdc:refs($vardecl),
      util:if($opts?body-items,xqdc:body($vardecl)) }
		</xqdoc:variable>
};

declare %private function xqdc:functions($parse as element(Module), $opts)
as element(xqdoc:functions)
{
  let $items:= $parse/*/Prolog/AnnotatedDecl/FunctionDecl   
  return element {"xqdoc:functions"} {  $items!xqdc:function(., $opts)}
}; 

declare %private function xqdc:function($fundecl as element(FunctionDecl), $opts as map(*))
as element(xqdoc:function){
 <xqdoc:function arity="{ count($fundecl/(Param|ParamList/Param)) }">
    
      {$fundecl/TOKEN[.="external"]!attribute external {"true"}}
       {  xqcom:comment(util:or($fundecl/..,$fundecl/../Prolog))}
			<xqdoc:name>{ $fundecl/QName/string() }</xqdoc:name>
       { $fundecl/parent::AnnotatedDecl/Annotation
         !<xqdoc:annotations>{xqdc:annotation(.)}</xqdoc:annotations>}
 
      <xqdoc:signature>{$fundecl/((*|text()) except EnclosedExpr)/string()
                        =>string-join(" ")=>normalize-space()
       }</xqdoc:signature>
			
      <xqdoc:parameters>
      { $fundecl/(.|ParamList)/Param!xqdc:param(.) }
      </xqdoc:parameters>
			<xqdoc:return><xqdoc:type>{
        $fundecl/SequenceType!( attribute occurrence {TOKEN/string() },  QName/string() ),
        if(not($fundecl/SequenceType))
        then $fundecl/*[last()-1]/string() (: before EnclosedExpr :)
      }</xqdoc:type></xqdoc:return>
      { xqdc:refs($fundecl) }
      { util:if($opts?body-items,xqdc:body($fundecl)) }
	</xqdoc:function>
};

declare %private function xqdc:param($param as element(Param))
as element(xqdoc:parameter)
{
 <xqdoc:parameter>
 	  <xqdoc:name>{ $param/QName/string() }</xqdoc:name>
	 { $param/TypeDeclaration!xqdc:type(.)}
 </xqdoc:parameter>
};

declare %private function xqdc:type($type as element(TypeDeclaration))
as element(xqdoc:type){
 <xqdoc:type >{
     $type/SequenceType!attribute occurrence {TOKEN/string() },  
     ($type | $type/SequenceType)/QName/string() 
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
<xqdoc:annotation name="{ $anno/*[2]/string() }">{
 for $a in $anno/*
 return typeswitch($a)
        case element(StringLiteral) 
          return <xqdoc:literal type="xs:string">{ xqdc:unquote($a) }</xqdoc:literal>
        case element(TOKEN) | element(QName) | text()  (: ignore these :)
          return ()
        default 
        return error()
}</xqdoc:annotation>
};

(:~  remove start and end quote marks :)
declare %private function xqdc:unquote($s as xs:string)
as xs:string{
replace($s,'^[''"](.*)[''"]$','$1')
};

