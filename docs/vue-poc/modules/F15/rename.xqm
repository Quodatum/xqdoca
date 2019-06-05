(:  xqDocA added a comment :)
(:~ get datetaken
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
declare variable $DEST:="/datetaken.xml";

let $dates:=<dates   date="{current-dateTime()}">{
for $image in collection($cfg:DB-IMAGE || "/image")/image[not(@original)]
let $year:=substring($image/datetaken,1,4)

group by $year
order by $year descending

return <year value="{$year}" count="{count($image)}">
{for $image in $image
let $month:=substring($image/datetaken,6,2)
group by $month
order by $month
return <month value="{$month}" count="{count($image)}"/>
}
</year>
}</dates>
return $dates =>local:put($DEST) 