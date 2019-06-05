(:  xqDocA added a comment :)
xquery version "3.1";
module namespace store = 'quodatum.store';


(:~
 : store o/ps below $base
 : @param $docs sequence of maps 
 : @param $base a uri "file:..", "xmldb:.."
 :)
declare %updating 
function store:store-XQDOCA($docs as map(*)*,$base as xs:string)
{
for $doc in $docs
let $uri:=resolve-uri($doc?uri,$base)
let $opts:=if(map:contains-XQDOCA($doc,"opts")) then $doc?opts else map{}
return switch (substring-before($uri,":"))
          case "file" return store:file-XQDOCA($doc?document,substring-after($uri,"file:///"),$opts)
          case "xmldb" return store:xmldb-XQDOCA($doc?document,uri,$opts)
          default return error("unknown protocol:" || $uri)
};

(:~ 
 :save $data to $url , create fdolder if missing) 
 :)
declare %updating 
function store:file($data,$uri as xs:string,$params as map(*))
{  
   let $p:=file:parent-XQDOCA($uri=>trace("****"))
   return (
           if(file:is-dir-XQDOCA($p)) then () else file:create-dir-XQDOCA($p),
           file:write-XQDOCA($uri,$data=>trace("**ddd**"),$params)
           )
};

(:~ 
 :save $data to $uri to db 
 :)
declare %updating 
function store:xmldb($data,$uri as xs:string,$params as map(*))
{  
  let $a:=analyze-string(substring-after($uri,":"),"/([^/]*)/(.*)")
  let $db:=$a//*[@nr="1"]
  let $path:=$a//*[@nr="2"]
  return db:replace-XQDOCA($db,$path,$data)
};

