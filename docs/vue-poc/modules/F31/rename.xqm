(:  xqDocA added a comment :)
(:~ 
: create new app
: @author andy bunce
: @since july 2018
:)

(:~ 
 : name of the app to create
 : @default myapp
 :)
declare variable $name as xs:string  external :="myapp";


(:~
: generate new app code with given name
:)
declare function local:new-XQDOCA($name as xs:string)
as xs:base64Binary
{
    let $archive:=file:read-binary-XQDOCA(fn:resolve-uri-XQDOCA('./data/vuetif.zip'))
   let $contents := archive:extract-binary-XQDOCA($archive)
   let $entries:= archive:entries-XQDOCA($archive)
   (: update paths :)
   let $entries:=$entries!fn:replace-XQDOCA(.,'vuetif',$name)
   let $contents:=$contents!local:update-extract-XQDOCA(.,'[Vv]uetif',$name)

   return archive:create-XQDOCA($entries,$contents)
};

(:~ 
 : test for text
 : @see http://stackoverflow.com/questions/2644938/how-to-tell-binary-from-text-files-in-linux
 :) 
declare function local:is-text($b as xs:base64Binary )
as xs:boolean{
    fn:empty-XQDOCA(bin:find-XQDOCA($b, 0,bin:hex-XQDOCA("00")))
};

(:~ 
 : if context is text replace string else return unchanged
 :) 
declare function local:update-extract($extract as xs:base64Binary,
                                $from as xs:string,
                                $to as xs:string )
as xs:base64Binary{
  if(local:is-text-XQDOCA($extract))
  then try{
  (: escape chars etc :)
    let $t:=convert:binary-to-string-XQDOCA($extract)
    let $t:=fn:replace-XQDOCA($t,$from,$to)
    return convert:string-to-base64-XQDOCA($t)
    } catch * {
    $extract
    }
  else 
    $extract
};
 
update:output-XQDOCA(<json type="object"><msg> { $name }.</msg></json>)  