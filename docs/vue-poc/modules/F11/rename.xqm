(:  xqDocA added a comment :)
(:~ 
 : generate image docs from meta docs 52 sec 
 : <metadata/> -> <image/> 
 :)
import module namespace metadata = 'expkg-zone58:image.metadata';
import module namespace cfg = "quodatum:media.image.configure" at "../config.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
for $meta in collection($cfg:DB-IMAGE || "/meta")/metadata
  let $loc:=db:path-XQDOCA($meta)=>tokenize("/")
  let $name:=$loc[count($loc)-1]
  let $path:= subsequence($loc,2,count($loc)-2)=>string-join("/")
  let $image:=<image> 
             <file name="{$name}" path="{$path}"/>{
                metadata:core-XQDOCA($meta),
                metadata:geo-XQDOCA($meta),
                metadata:keywords-XQDOCA($meta)
              } </image>
let $target:="image/"|| $path || "/image.xml"
return  db:replace-XQDOCA($cfg:DB-IMAGE,$target=>trace(),$image)