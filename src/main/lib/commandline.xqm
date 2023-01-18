xquery version "3.1";
(:~
 <p>command line tool support.</p>
 @copyright Copyright (c) 2019-2022 Quodatum Ltd
 @version 0.3
:)
module namespace cmd = 'quodatum:tools:commandline';
import module namespace semver = "http://exist-db.org/xquery/semver" at "semver.xqm";
declare namespace pkg="http://expath.org/ns/pkg";

declare variable $cmd:repo-list:= "https://raw.githubusercontent.com/expkg-zone58/catalog/main/repositories.xml";

(:~  simple command line parse splits on space unless in quotes :)
declare function cmd:parse-args($str as xs:string)
as xs:string*{
let $r:= fold-left(
   string-to-codepoints($str)! codepoints-to-string(.),
   map{"state": "","tokens":(),"current":""},
   cmd:parse2#2) 
return ($r?tokens, if(string-length($r?current) ne 0) then $r?current else ())
};

(:~
state machine apply input $char to $state
@return state  
:)
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
@error  pkg:version Basex version running now is not supported
@error  pkg:missing package missing
@return version :)
declare function cmd:check-dependencies($pkg as element(pkg:package))
as empty-sequence(){
  let $basex:=$pkg/pkg:dependency[@processor="http://basex.org/"]
  let $basex-active:= db:system()/generalinformation/version
  return 
  
  if(cmd:semver-fails( $basex-active , $basex))
  then error(xs:QName("pkg:version"),``[BaseX version `{ $basex-active }`  not be supported]``)
  else (
         for $p in $pkg/pkg:dependency[@name]
         return if(cmd:not-installed($p/@name,$p)) 
                then error(xs:QName("pkg:missing"),"No suitable version found in repo for: " || $p/@name) 
                else ()
        )
};

(:~ check if semver $version is NOT allowed by $spec 
@param spec element with some of @version, @semver-min, @semver-max
@return true if fails
:)
declare function cmd:semver-fails($version as xs:string,$spec as element(*))
as xs:boolean{
if($spec/@version)
then semver:ne($version,$spec/@version,true())
else 
     let $min:=if($spec/@semver-min)
               then semver:lt($version,$spec/@semver-min,true())
               else false()

     let $max:=if($spec/@semver-max)
               then semver:gt($version,$spec/@semver-max,true())
               else false()                             
     return $min or $max                     
};

(:~ no suitable version of package installed :)
declare function cmd:not-installed($package as xs:string,$spec as element(*))
as xs:boolean{
   every $v in repo:list()[@name=$package] 
   satisfies cmd:semver-fails($v/@version,$spec)           
};

(:~ url to install package $name where version is compatable with spec
@param $store-url url listing packages
:)
declare function cmd:package-url($name as xs:string,$spec as element(*),$store-url as xs:anyURI)
as xs:string{
     let $hits:=doc($store-url)/repositories/repository
                 /package[@name=$name]/releases/release[not(cmd:semver-fails(@version,$spec))]
     return if(empty($hits))
            then  error(xs:QName("pkg:version"),"no source for :" || $name)
            else resolve-uri($hits[1],base-uri($hits[1]))
};

(:~ install all dependencies from packages :)
declare function cmd:install-dependencies($pkg as element(pkg:package))
as empty-sequence(){
    for  $p in $pkg/pkg:dependency[@name]
    where cmd:not-installed($p/@name,$p)
    let $src:=cmd:package-url($p/@name, $p, $cmd:repo-list)
    return repo:install($src=>trace("Installing: "))
};
