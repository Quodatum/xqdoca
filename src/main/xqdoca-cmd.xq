xquery version "3.1";
(:~  
 : Generate documentation for for XQuery sources
 : @author Andy Bunce (Quodatum)
 :)

import module namespace cmd = 'quodatum:command:tools' at "lib/command.xqm";

declare variable $args as xs:string  external;
(:~ expath metadata :)
declare variable $expkg:=doc("expath-pkg.xml")/*;

declare function local:resolve($path)
as xs:string{
file:resolve-path($path,file:current-dir())
};

cmd:check-dependancies($expkg),    
let $args:=cmd:parse-args($args)
let $args:=if(exists($args)) 
           then $args 
           else local:resolve(".xqdoca")!util:if(doc-available(.),.,"-h")
for  $action in  $args
let $src:=local:resolve($action)=>trace("Processing: ")
return  
    switch($action)
    case "-h" return update:output(unparsed-text("xqdoca.txt"))
    case "-v" return update:output($expkg/@version/string())
    case "-install" return update:output("install")               
    default return xquery:eval-update(xs:anyURI("xqdoca.xq"),
                                      map{"src": $src, "pass":true()}
                                    )


