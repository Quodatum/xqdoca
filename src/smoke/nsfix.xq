(: parse with namespace change :)
import module namespace xp="expkg-zone58:text.parse";
declare %updating function local:decl($tree as element(XQuery),
                                      $ns as xs:string)
{
  replace value of node 
  $tree/LibraryModule/ModuleDecl/StringLiteral 
  with ``[ "`{ $ns }`"]``
};

let $t:="C:\Users\andy\basex.home\basex.945\etc\xqdoc\admin.xqm"
let $w as xs:string := unparsed-text($t)  
let $a:= xp:parse($w  ,map{ "lang":"xquery", "version":"3.1 basex",  "flatten":true() })
let $out:= $a transform with {
  local:decl(.,"ff")
}
return $out/string()