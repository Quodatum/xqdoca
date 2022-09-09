xquery version "3.1";
(:
 : Copyright (c) 2019-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
 :)
 
 (:~
 : <h1>store.xqm</h1>
 : <p>Save documents to file system or database. Data is supplied as a map which 
 : includes serialization options</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
module namespace store = 'quodatum:xqdoca:store';


(:~
 : store a set of  o/ps below $base
 : @param $docs sequence of maps 
 : @param $base a uri "file://..", "xmldb:.."
 :)
declare %updating 
function store:store($docs as map(*)*,$base as xs:string)
{
for $doc in $docs
let $uri:=resolve-uri($doc?uri,$base)
let $opts:=if(map:contains($doc,"output")) then $doc?output else map{}
return switch (substring-before($uri,":"))
          case "file" return store:file($doc?document,store:file-to-native($uri),$opts)
          case "xmldb" return store:xmldb($doc?document,$uri,$opts)
          default return error("unknown protocol:" || $uri)
};

declare %private 
function store:file-to-native($uri as xs:string)
{
  (: file:path-to-native errors if not exists :)
substring-after($uri,"file:///")
};
(:~ 
 :save $data to file system $url , create folder tree if required
 :)
declare %updating 
function store:file($data,$uri as xs:string,$params as map(*))
{  
   let $p:=file:parent($uri)
   return (
           if(file:is-dir($p)) then () else file:create-dir($p),
           file:write($uri,$data,$params)
           )
};

(:~ 
 :save $data to $uri  Xml database
 :)
declare %updating 
function store:xmldb($data,$uri as xs:string,$params as map(*))
{  
  let $a:=analyze-string(substring-after($uri,":"),"/([^/]*)/(.*)")
  let $db:=$a//*[@nr="1"]
  let $path:=$a//*[@nr="2"]
  return db:replace($db,$path,$data)
};

