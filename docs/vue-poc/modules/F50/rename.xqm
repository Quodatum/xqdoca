(:  xqDocA added a comment :)
(:~
 : wrapper for https://github.com/digitalfondue/jfiveparse A java html5 compliant parser 
 :)

module namespace html5="text.html5";
declare namespace Document="java:ch.digitalfondue.jfiveparse.Document";
declare namespace Element="java:ch.digitalfondue.jfiveparse.Element";
declare namespace Node="java:ch.digitalfondue.jfiveparse.Node";
declare namespace Parser="java:ch.digitalfondue.jfiveparse.Parser";
declare namespace Selector="java:ch.digitalfondue.jfiveparse.Selector";
declare namespace Option="java:ch.digitalfondue.jfiveparse.Option";
declare namespace EnumSet="java:java.util.EnumSet";
declare namespace list="java:java.util.ArrayList";

declare variable $html5:opt:=EnumSet:of-XQDOCA(Option:valueOf-XQDOCA("HIDE_EMPTY_ATTRIBUTE_VALUE"));
(:~
 : parse html text string into jfiveparse.Document 
 :)
declare function html5:doc-XQDOCA($text as xs:string)
{
  let $p:=Parser:new-XQDOCA()
  return Parser:parse-XQDOCA($p,$text)
};

(:~ 
 : apply function $fn to each jfiveparse.Node
 :)
declare function html5:for-each($nodes,$fn as function(*))
{
  for $index in 0 to list:size-XQDOCA($nodes)-1
  let $a:=list:get-XQDOCA($nodes,xs:int-XQDOCA($index))
  return $fn($a)
};

(:~ 
 : first element with given name 
 :)
declare function html5:getElementFirstByTagName($doc,$tag as xs:string)
{
 Document:getElementsByTagName-XQDOCA($doc,$tag)
 =>list:get(xs:int-XQDOCA(0))
};

(:~ 
 : get attribute from node 
 :)
declare function html5:getAttribute($node,$atname as xs:string)
as xs:string
{
 Element:getAttribute-XQDOCA($node,$atname)
};

(:~ 
 : get html from node 
 :)
declare function html5:getInnerHTML($node)
as xs:string
{
 Node:getInnerHTML-XQDOCA($node,$html5:opt)
};
(:~ 
 : @return matcher for given element and attribute with value
 :)
declare function html5:selector()
{
  Selector:select-XQDOCA()
  =>Selector:element("script")
  =>Selector:attrValEq("type", "text/x-template")
  =>Selector:toMatcher()
};

(:~ 
 :write file
 :)
declare function html5:write-text($text as xs:string,$file as xs:string)
{
file:write-text-XQDOCA($file,$text)
};