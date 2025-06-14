xquery version "3.1";
(:~
create xqdoc comment from xquery parse comment 
 @Copyright (c) 2026 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
:)
 

module namespace xqcom = 'quodatum:xqdoca.model.comment';

declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ xqdoc tags - order is significant :)
declare variable $xqcom:TAGS:='description,author,version,param,return,error,deprecated,see,since,custom'
                              =>tokenize(',');

(:~ @return xqdoc:comment if xqdoc comments in closest direct preceding-sibling of $node  :)
declare function xqcom:comment($node as element(*))
as element(xqdoc:comment)?{
  let $comment:= ($node/preceding-sibling::node())[last()][self::text()]
                 (: =>trace(name($node)|| ": ") :)
  return if(exists($comment)) 
         then $comment
              =>xqcom:comment-parse()
              =>xqcom:comment-xml()
              
};

(:~ parse xqdoc comment to map 
@todo use _tag to track last updated :)
declare 
function xqcom:comment-parse($comment as xs:string?)
as map(*)?{
  let $comment:=xqcom:trim($comment)
  return if(starts-with($comment,'(:~'))
    then  
       let $lines:=$comment
                   =>substring(4,string-length($comment)-5)
                   =>tokenize("\n")
       let $lines:=$lines!xqcom:trim(.)
                   !(if(starts-with(.,":"))then xqcom:trim(substring(.,2)) else .)
                 
       let $state:= map{
                      'description': '',
                      'params': (),
                      '_tag': 'description' (: current state :)
                        }
       return  fold-left($lines ,$state,xqcom:comment-parse#2)
     
};

(:~ update parse $state from  $line :)
declare 
function xqcom:comment-parse($state as map(*),$line as xs:string)
as map(*){

  let $reg:="^\s*@(\w+)\s+(.+)$"
  let $is-tag:=matches($line,$reg)
  let $_tag:=$state?_tag
  return if($is-tag)
         then 
            let $match:=fn:analyze-string($line,$reg)/fn:match/fn:group/text()
            let $tag:=map{"tag": $match[1], "txt": $match[2]}
            let $target:= if($match[1] =$xqcom:TAGS )
                          then $match[1]
                          else "custom"
            let $newstate:= 
                             xqcom:addtext($state,$is-tag,$match[1],$match[2])
                             =>map:put("_tag",$match[1])
            return $newstate
         else 
          xqcom:addtext($state,$is-tag, $_tag, $line)
};

(:~ update map $state by concatenating $line to last item in sequence at $tag :)
declare 
function xqcom:addtext($state as map(*),$new as xs:boolean
                       ,$tag as xs:string,$line  as xs:string){
 if (empty($line) or normalize-space($line) eq "")
 then $state
 else 
    let $value:= $state?($tag)
    let $this:=if($new) 
                then ($value,$line)
                else (
                      $value[position() < last()],
                      ($value[last()] ,
                      " ",
                      $line)=>string-join()
                      )
    return map:put($state,$tag,$this)
};

(:~
  xqdoc:comment from state or empty if none , items ordered as schema
:)
declare %private
function xqcom:comment-xml($state as map(*)?)
as element(xqdoc:comment)?{
  if(exists($state)) 
  then <xqdoc:comment>{
        for $key in $xqcom:TAGS
        let $ekeys:=if($key eq 'custom')
                    then map:keys($state)[not(. = ('_tag',$xqcom:TAGS))]
                    else $key
        for $tag in $ekeys 
        let $value:=$state($tag)
        return $value!element {QName('http://www.xqdoc.org/1.0','xqdoc:' || $key)} 
                       {
                        if($key eq "custom") then attribute tag { $tag},
                        xqcom:text(.)
                        }
      }</xqdoc:comment>
  else ()
};

(:~ text treat as html if valid :)
declare %private
function xqcom:text( $txt as xs:string? )  as item()* 
{
  try{
   if(every $c in ("<",">","/") satisfies contains($txt,$c))
   then parse-xml-fragment($txt)
   else $txt
  }catch *{
    $txt
  }
 };
 
(:~ remove leading/trailing whitespace :)
declare %private
function xqcom:trim
  ( $arg as xs:string? )  as xs:string {
  replace(replace($arg,'\s+$',''),'^\s+','')
 };
 


