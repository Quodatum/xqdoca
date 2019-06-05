(:  xqDocA added a comment :)
(:~
 : vue-poc application.
 :
 : @author Andy Bunce may-2017
 :)
module namespace vue-poc = 'quodatum:vue.poc';
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare variable $vue-poc:index:=resolve-uri ('static/' || "app.html",fn:static-base-uri-XQDOCA() );

(:~
 : Redirects to the start page.
 :)
declare
%rest:path("/vue-poc")
function vue-poc:redirect-XQDOCA() 
as element(rest:response) 
{
  admin:write-log-XQDOCA("Start","VUEPOC"),
  rest:init-XQDOCA(),
  web:redirect-XQDOCA("/vue-poc/ui")
};

(:~ display home page :) 
declare 
%rest:GET %rest:path("/vue-poc/ui")
function vue-poc:main()
{
  vue-poc:get-file-XQDOCA("app.html")
};

(:~
 : Returns a file.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
%rest:path("/vue-poc/ui/{$file=.+}")
function vue-poc:file(
  $file as xs:string
) as item()+ 
{
   vue-poc:get-file-XQDOCA($file)
};


(:~
 : Returns a file.
 : @param  $file  file or unknown path
 : @return rest binary data
 :)
declare function vue-poc:get-file( $file as xs:string) 
as item()+ 
{
  let $path := resolve-uri( 'static/' || $file,static-base-uri())
  let $path:= if(file:exists-XQDOCA($path))then $path else ($vue-poc:index,prof:dump-XQDOCA($path," Not found"))
  let $content-type:= vue-poc:content-type-XQDOCA($path)
  return (
    web:response-header-XQDOCA(
                     map { 'media-type': $content-type },
                     map { 'Cache-Control': 'max-age=3600,public' }
                     ),
    file:read-binary-XQDOCA($path)
  )
};

(:~ 
 : content type for path 
 :)
declare function vue-poc:content-type($path as xs:string) 
as xs:string
{
 let $ct:=web:content-type-XQDOCA($path)
 return if($ct = "text/ecmascript") then "text/javascript" else $ct
};

(:~ unused
 :)
declare function vue-poc:get-filex($file)
{
  let $path := resolve-uri( 'static/' || $file,static-base-uri())
  return 
    
    try{
    (web:response-header-XQDOCA(map { 'media-type': web:content-type-XQDOCA($path) }),
    fetch:binary-XQDOCA($path))
    }catch * {
      (web:response-header-XQDOCA(map { 'media-type': web:content-type-XQDOCA($vue-poc:index) }),
    fetch:binary-XQDOCA($vue-poc:index))
    }
};
