xquery version "3.1";
(:
 : Copyright (c) 2019-2022 Quodatum Ltd
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)
 
 (:~
 : <h1>command.xqm</h1>
 : <p>command line tool support.</p>
 :
 : @author Andy Bunce
 : @version 0.3
 :)
module namespace cmd = 'quodatum:command:tools';
 declare namespace pkg="http://expath.org/ns/pkg";

(:~  simple command line parse splits on space unless in quotes :)
declare function cmd:parse-args($str as xs:string)
as xs:string*{
let $r:= fold-left(
   string-to-codepoints($str)! codepoints-to-string(.),
   map{"state": "","tokens":(),"current":""},
   cmd:parse2#2) 
return ($r?tokens, if(string-length($r?current) ne 0) then $r?current else ())
};

declare %private function cmd:parse2($state as map(*),$char as xs:string)
as map(*){
 let $new:=switch ($char)
 case '"'
 case "'" return map:entry("state",if($state?state eq $char) then "" else $char)               
                   
 case ' ' return if($state?state eq "")
                  then if(string-length($state?current) ne 0)
                       then  map {  "tokens": ($state?tokens,$state?current), "current": ""}
                       else ()
                 else map:entry("current", $state?current || $char)
                 
  default return  map:entry("current", $state?current || $char)
  return map:merge(($new,$state))       
};
(:~ raise error if deps missing 
@return version :)
declare function cmd:check-dependancies($pkg as element(*))
as empty-sequence(){
  let $basex:=$pkg/pkg:package/pkg:dependency[@processor="http://basex.org/"]/@version/string()
  let $pkgs:=$pkg/pkg:package/pkg:dependency[@name]
  let $basex-active:= db:system()/generalinformation/version/tokenize(.," ")[1]
  return 
  
  if( $basex-active ne $basex)then 
       error(xs:QName("pkg:version"),``[BaseX version `{ $basex-active }` may not be supported]``)
  else (
         for $p in $pkgs
         return if(repo:list()[@name=$p/@name]/@version ne $p/@version) then
                      error(xs:QName("pkg:version"),$p/@name) else ()
    
        )
};