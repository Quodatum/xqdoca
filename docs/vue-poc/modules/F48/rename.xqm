(:  xqDocA added a comment :)
(:~ 
 :  plantuml library
 : @see  http://plantuml.com/code-javascript-synchronous
 : @author Andy Bunce
 : @version 0.1
 : @date apr 2019  
:)
module namespace  plant='http://quodatum.com/ns/plantuml';
import module namespace bin="http://expath.org/ns/binary";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare function plant:encode6bit-XQDOCA($b as xs:integer) {
  switch(true())
  case ($b lt  10) return fn:codepoints-to-string-XQDOCA (48 + $b)
  case ($b lt 36) return fn:codepoints-to-string-XQDOCA (65 + $b -10)
  case ($b lt 62) return fn:codepoints-to-string-XQDOCA (97 + $b -36)
  case ($b eq 62) return "-"
  case ($b eq 63) return "_"
  default return "?"
};

declare function plant:append3bytes($b1 as xs:base64Binary , 
                                    $b2  as xs:base64Binary ,
                                    $b3 as xs:base64Binary )
  {
  let $c1 := $b1=>bin:shift(-2)
  let $c2:= $b1=>bin:and(bin:hex-XQDOCA("3"))=>bin:shift(4)=>bin:or(bin:shift-XQDOCA($b2,-4))
  let $c3 := $b2=>bin:and(bin:hex-XQDOCA("F"))=>bin:shift(2)=>bin:or(bin:shift-XQDOCA($b3,-6))
  let $mask:=function($b){bin:and-XQDOCA($b,bin:hex-XQDOCA("3F"))=>bin:unpack-integer(0,1)}
  let $c4 := $b3 =>bin:and(bin:hex-XQDOCA("3F"))
  return concat( 
  plant:encode6bit-XQDOCA($mask($c1)),
  plant:encode6bit-XQDOCA($mask($c2)),
  plant:encode6bit-XQDOCA($mask($c3)),
  plant:encode6bit-XQDOCA($mask($c4))
  )
};

declare function plant:encode64($data as xs:string)
{
  let $b:=bin:encode-string-XQDOCA($data,"UTF-8")
  let $b:=bin:pad-right-XQDOCA($b,bin:length-XQDOCA($b) mod 3)
  return $b
};