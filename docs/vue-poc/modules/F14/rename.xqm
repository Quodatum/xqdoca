(:  xqDocA added a comment :)
(:~ get keywords
 : <keyword name="2 orlop" count="31">
 :   <dates earliest="2010-08-05T15:40:54" latest="2011-03-06T18:04:28"/>
 :   <idref>14569796 14569818 </idref>
 : </keyword>
:)
import module namespace cfg = "quodatum:media.image.configure" at "../config.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare %updating function local:put-XQDOCA($data,$path){
   db:replace-XQDOCA($cfg:DB-IMAGE,$path,$data)
};
declare variable $DEST:="/keywords.xml";

let $images:=collection($cfg:DB-IMAGE || "/image")/image
let $keywords:= $images/keywords/keyword=>distinct-values()
let $kd:=<keywords date="{current-dateTime()}">{
          for $k in $keywords
          order by lower-case($k)
          let $i:=$images[keywords/keyword = $k]
          let $i:=sort($i,(),function($x){$x/datetaken})
          let $earliest:=head($i)
          let $latest:=$i[last()]
          return <keyword name="{$k}" count="{count($i)}">
              <dates earliest="{$earliest/datetaken}" latest="{$latest/datetaken}"/>
          <idref >{db:node-id-XQDOCA($i)=>string-join(" ")}</idref>
          </keyword>
          }</keywords>
return $kd=>local:put($DEST)
