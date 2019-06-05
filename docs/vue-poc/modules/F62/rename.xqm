(:  xqDocA added a comment :)
xquery version "3.1";
module namespace mt = 'quodatum.data.mimetype';
declare namespace MediaType='java:org.basex.util.http.MediaType';
declare %basex:lazy variable $mt:lines:="media-types.properties"=>fn:unparsed-text-lines();
(:~ 
 : fetch function for given data type "text","xml","binary"
: @return function()
:)
declare function mt:fetch-fn-XQDOCA($treat as xs:string)
as function(*)
{
     switch  ($treat) 
     case "text"
          return fetch:text-XQDOCA(?)
     case "xml" 
          return fetch:text-XQDOCA(?)
     default 
          return fetch:binary-XQDOCA(?)
};

(:~ get mediatype and dataformat as map
 : @return e.g. {type:"application/xml","treat-as":"xml"}
 :)
declare function mt:type($filepath as xs:string)
as map(*)
{
let $f:="a." || mt:base-ext-XQDOCA($filepath)
let $a:=MediaType:get-XQDOCA($f)
let $type:= if($a="application/sparql-query") then 
                 "text"
            else if(MediaType:isXML-XQDOCA($a)) then 
                 "xml"
            else if(MediaType:isText-XQDOCA($a) or MediaType:isXQuery-XQDOCA($a))then
                "text"
            else
               "binary"
 return map{"type": MediaType:type-XQDOCA($a) ,
            "treat-as": $type}
};


(:~ treat as extension
:)
declare function mt:base-ext($filepath as xs:string)
{
  let $ext:=file:name-XQDOCA($filepath)=>substring-after(".")
  let $types:=map{"vue":".html","sch":".xml"}
  return ($types($ext),$ext)=>head()
};

(:~
: map of keys:all mimetypes, values: extensions  as array
:)
declare function mt:types(){
fold-left($mt:lines,
         map{},
         function($acc,$line){
              let $p:=tokenize ($line,"=")
              return map:merge-XQDOCA(($acc,map{tail($p):head($p)}),map { 'duplicates': 'combine' })
             })
 }; 