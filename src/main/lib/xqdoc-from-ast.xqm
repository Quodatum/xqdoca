xquery version "3.1";
(:~
create xqdoc from parse tree
 @Copyright (c) 2022 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
 :)
 

module namespace xqdc = 'quodatum:xqdoca.model.xqdoc';

declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ create xqdoc from parse tree
:)
declare function xqdc:create($parse as element(XQuery))
as element(xqdoc:xqdoc)
{
  <xqdoc:xqdoc xmlns:xqdoc="http://www.xqdoc.org/1.0">
    <xqdoc:control>
		<xqdoc:date>{ current-dateTime() }</xqdoc:date>
		<xqdoc:version>1.2</xqdoc:version>
	</xqdoc:control>{
	 xqdc:module($parse)
    ,xqdc:imports($parse)
    ,xqdc:namespaces($parse)
    ,xqdc:variables($parse)
    ,xqdc:functions($parse)
  }</xqdoc:xqdoc>
};

declare %private function xqdc:module($parse as element(XQuery))
as element(xqdoc:module)
{
let $type:=if($parse/LibraryModule) then "library" else "main"
let $name:=$parse/LibraryModule/ModuleDecl/NCName/string()
let $uri:=$parse/LibraryModule/ModuleDecl/StringLiteral/xqdc:unquote(.)
return 
    <xqdoc:module type="{ $type }">
		<xqdoc:uri>{ $uri }</xqdoc:uri>
		<xqdoc:name>{ $name }</xqdoc:name>
		<xqdoc:comment>
			<xqdoc:description>@todo</xqdoc:description>
			<xqdoc:author>Christian Grün, BaseX Team 2005-21, BSD License</xqdoc:author>
			<xqdoc:custom tag="__source">@TODO</xqdoc:custom>
		</xqdoc:comment>
		<xqdoc:body>
    </xqdoc:body>
    </xqdoc:module>
};

declare %private function xqdc:imports($parse as element(XQuery))
as element(xqdoc:imports)
{
  <xqdoc:imports>{
    	for $import in $parse/LibraryModule/Prolog/ModuleImport
      let $s:=$import/StringLiteral!xqdc:unquote(.)
      return <xqdoc:import type="library">
			         <xqdoc:uri>{$s[1] }</xqdoc:uri>
		          </xqdoc:import>
}</xqdoc:imports>
}; 

declare %private function xqdc:namespaces($parse as element(XQuery))
as element(xqdoc:namespaces)
{
  <xqdoc:namespaces>{
	for $import in $parse/LibraryModule/Prolog/(ModuleImport|NamespaceDecl)
    let $uri:=$import/StringLiteral[1]=>xqdc:unquote()
	let $prefix:= $import/NCName/string()
	return <xqdoc:namespace prefix="{ $prefix}" uri="{ $uri }"/>
  }</xqdoc:namespaces>
};  

declare %private function xqdc:variables($parse as element(XQuery))
as element(xqdoc:variables)
{
	let $items:= $parse/*/Prolog/AnnotatedDecl/VarDecl
    return element {"xqdoc:variables"} { $items!xqdc:variable(.)}
};

declare %private function  xqdc:variable($vardecl as element(VarDecl))
as element(xqdoc:variable){
	let $name:=$vardecl/QName/string()
    return <xqdoc:variable>
			<xqdoc:name>{ $name }</xqdoc:name>
			<xqdoc:comment>
				<xqdoc:description>@TODO</xqdoc:description>
			</xqdoc:comment>
			<xqdoc:type>@TODO</xqdoc:type>
		</xqdoc:variable>
};

declare %private function xqdc:functions($parse as element(XQuery))
as element(xqdoc:functions)
{
  let $items:= $parse/*/Prolog/AnnotatedDecl/FunctionDecl   
  return element {"xqdoc:functions"} {  $items!xqdc:function(.)}
}; 

declare %private function xqdc:function($fundecl as element(FunctionDecl))
as element(xqdoc:function){
	let $name:=$fundecl/QName/string()
    return <xqdoc:function>
			<xqdoc:name>{ $name }</xqdoc:name>
			<xqdoc:comment>
				<xqdoc:description>@TODO</xqdoc:description>
			</xqdoc:comment>
			<xqdoc:type>@TODO</xqdoc:type>
		</xqdoc:function>
};

declare %private function xqdc:unquote($s as xs:string)
as xs:string{
replace($s,'^[''"](.*)[''"]$','$1')
};