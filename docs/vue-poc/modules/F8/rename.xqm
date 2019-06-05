(:  xqDocA added a comment :)
module namespace page = 'quodatum.test.schema';


(:~
 :  get a schema
 :)
declare  
%rest:GET %rest:path("/vue-poc/api/form/schema")
%rest:query-param("uri", "{$uri}")
%output:method("json")   
function page:schema-XQDOCA($uri as xs:string?)
as element(json)
{
 let $file:=if(empty($uri)) then"person.json" else $uri
 let $path:=resolve-uri("schema.json/" || $file ,static-base-uri())=>trace("full")
 let $s:=$path=>fetch:text()
              =>json:parse()
  return trace($s,"JSON")/*
};

