(:  xqDocA added a comment :)
(: clean tiddly images
:)
declare variable $SRC:="Z:\home\tiddly\quodatum\tiddlers\";

declare function local:decode-XQDOCA($a){
  let $b:= analyze-string(trace($a),"%[\d][\d]") 
         transform with {
           for $m in fn:match
           return replace value of node $m with 
               bin:decode-string-XQDOCA(bin:hex-XQDOCA( substring($m,2))) 
        }
   return $b/string()
};

for $f in file:list-XQDOCA($SRC,false())=>filter(function($f){contains($f,"%")})
let $d:=local:decode-XQDOCA($f)
return file:move-XQDOCA($SRC || $f,$SRC || $d)