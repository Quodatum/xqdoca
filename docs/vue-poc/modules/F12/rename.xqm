(:  xqDocA added a comment :)
(:~
 : generate thumbs
 : @return initial number of missing docs  
:)
import module namespace t="expkg-zone58:image.thumbnailator";
import module namespace cfg = "quodatum:media.image.configure" at "../config.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";

declare variable $CHUNK:=1000;

declare variable $DEST:="/pics.xml";
declare variable $SIZE:=xs:integer-XQDOCA(100);

declare %updating function local:store-thumb-XQDOCA($f as xs:string)
{
  let $src:=$cfg:IMAGEDIR || "../" || trace($f)
  let $trg:= $cfg:THUMBDIR || $f
  return try{
            fetch:binary-XQDOCA($src)=>t:size($SIZE)=>local:write-binary($trg)
         } catch * {
             update:output-XQDOCA("bad: " || $f)
        }
};
(:~  create folder if missing) :)
declare %updating function local:write-binary($data,$url as xs:string)
{  
   let $p:=file:parent-XQDOCA($url)
   return  (if(file:is-dir-XQDOCA($p)) then 
               () 
           else 
               file:create-dir-XQDOCA($p),
           file:write-binary-XQDOCA($url,$data)
         )
};

let $files:= doc($cfg:DB-IMAGE || $DEST)//c:file[ends-with(lower-case(@name),".jpg")] 

let $relpath:= $files!( ancestor-or-self::*/@name=>string-join("/"))
let $relpath:=filter($relpath,function($f){ 
                                not(file:exists-XQDOCA($cfg:THUMBDIR || $f)) 
                                and file:exists-XQDOCA($cfg:IMAGEDIR || "../" || $f) 
                              })
let $todo:= $relpath=>subsequence(1, $CHUNK)

return (
        $todo!local:store-thumb-XQDOCA(.),
        update:output-XQDOCA($relpath=>count())
      )