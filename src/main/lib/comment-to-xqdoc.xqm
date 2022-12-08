xquery version "3.1";
(:~
create xqdoc comment from xquery comment 
 @Copyright (c) 2022 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
:)
 

module namespace xqcom = 'quodatum:xqdoca.model.comment';

declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ xqdoc tags :)
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

(:~ parse xqdoc comment to map :)
declare function xqcom:comment-parse($comment as xs:string?)
as map(*)?{
  let $comment:=xqcom:trim($comment)
  return if(starts-with($comment,'(:~'))
    then  
       let $lines:=$comment
                   =>substring(4,string-length($comment)-5)
                   =>tokenize("\n")
       let $lines:=$lines!xqcom:trim(.)
                   !util:if(starts-with(.,":"), xqcom:trim(substring(.,2)), .)
       let $state:= map{
                      'description': '',
                      'params': ()
                        }
       return  fold-left($lines,$state,xqcom:comment-parse#2)
     
};

(:~ update parse $state from  $line :)
declare function xqcom:comment-parse($state as map(*),$line as xs:string)
as map(*){

  let $reg:="^\s*@(\w+)\s+(.+)$"
  let $is-tag:=matches($line,$reg)
  return if($is-tag)
         then 
         let $match:=fn:analyze-string($line,$reg)/fn:match/fn:group/text()
         return 
              if($match[1]=$xqcom:TAGS )
              then  map:put($state,$match[1],($state?($match) ,$match[2]))
              else  map:put($state,'custom',($state?custom ,$match[2]))                 
         else 
         map:put($state,'description',$state?description || " " || $line)
};

declare function xqcom:comment-xml($state as map(*)?)
as element(xqdoc:comment)?{
  if(exists($state)) 
  then <xqdoc:comment>{
        for $key in ($xqcom:TAGS,'custom')
        where map:contains($state,$key)
        return for $tag in $state?($key)
               return element {QName('http://www.xqdoc.org/1.0','xqdoc:' || $key)} {$tag}
      }</xqdoc:comment>
  else ()
};

(:~ remove leading/trailing whitespace :)
declare function xqcom:trim
  ( $arg as xs:string? )  as xs:string {
  replace(replace($arg,'\s+$',''),'^\s+','')
 };
 


