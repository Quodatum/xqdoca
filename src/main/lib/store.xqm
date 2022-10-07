xquery version "3.1";
(:~
 : <p>Save documents to file system or database. Data is supplied as a map which 
 : includes serialization options</p>
 : @Copyright (c) 2019-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
 
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
let $document:=store:doc-tweak($doc,$opts)

return switch (substring-before($uri,":"))
          case "file" return store:file($document,store:file-to-native($uri),$opts)
          case "xmldb" return store:xmldb($document,$uri,$opts)
          default return error("unknown protocol:" || $uri)
};

(:~ return document, set namespace if xhtml :)
declare function store:doc-tweak($doc as map(*),$opts as map(*)){
 if($opts?method eq "xhtml")
 then 
    let $_:=($doc?uri,name($doc?document))
    return store:as-xhtml($doc?document)
  else $doc?document
};

(:~ set doc ns to html
@param $doc html doc in no namespace
@todo set contenttype
:)
declare function store:as-xhtml($doc)
{
  store:change-element-ns-deep($doc,"http:/www.w3.org/1999/xhtml","")
};

(:~ 
The functx:change-element-ns-deep function changes the namespace 
 of the XML elements in $nodes to $newns
@see  http://www.xqueryfunctions.com/xq/functx_change-element-ns-deep.html
:)
declare function store:change-element-ns-deep
  ( $nodes as node()* ,
    $newns as xs:string ,
    $prefix as xs:string )  as node()* {

  for $node in $nodes
  return if ($node instance of element())
         then (element
               {QName ($newns,
                          concat($prefix,
                                    if ($prefix = '')
                                    then ''
                                    else ':',
                                    local-name($node)))}
               {$node/@*,
                store:change-element-ns-deep($node/node(),
                                           $newns, $prefix)})
         else if ($node instance of document-node())
         then store:change-element-ns-deep($node/node(),
                                           $newns, $prefix)
         else $node
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

