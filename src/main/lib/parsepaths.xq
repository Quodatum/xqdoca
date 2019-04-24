declare variable $xp:=doc("C:\tmp\xqdoc\classify.xqm\xparse.xml")/*;

declare function local:imports($xp as element(XQuery)) as xs:string*
{
  $xp/LibraryModule/Prolog/ModuleImport
};
declare function local:variables($xp as element(XQuery)){
  $xp/LibraryModule/Prolog/AnnotatedDecl/VarDecl
};
declare function local:functions($xp as element(XQuery)){
  $xp/LibraryModule/Prolog/AnnotatedDecl/FunctionDecl
};
local:functions( $xp)/string()