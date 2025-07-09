xquery version "3.1";
(:~
<p>generate and Analyse XQuery parse tree</p>
@copyright (c) 2019-2026 Quodatum Ltd
@author Andy Bunce, Quodatum, License: Apache-2.0
:)

module namespace xqp = 'quodatum:xqdoca.parser';

import module namespace xp="expkg-zone58:text.parse";
import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";

declare namespace xqdoc="http://www.xqdoc.org/1.0";



(:~ xparser defaults :)
declare variable $xqp:xparse_opts:=map{
    "basex9":  map{ "lang": "xquery", "version": "3.1 basex",  "flatten": false() }
  , "basex10":  map{ "lang": "xquery", "version": "3.1 basex",  "flatten": false() }

};

declare variable $xqp:trace as xs:boolean:=false();

 

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
