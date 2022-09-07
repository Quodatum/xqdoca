xquery version "3.1";
(:~  
 : Generate documentation for for XQuery sources
 : @author Andy Bunce (Quodatum)
 :)

import module namespace cmd = 'quodatum:command:tools' at "lib/command.xqm";

declare variable $args as xs:string  external;
(:~ expath metadata :)
declare variable $expkg:=doc("expath-pkg.xml")/*;

declare function local:resolve($path) as xs:string{
  file:resolve-path($path,file:current-dir())
};

let $args:=cmd:parse-args($args)
let $args:=if(exists($args)) 
           then $args 
           else local:resolve(".xqdoca")!util:if(doc-available(.),.,"-h")
for  $action in  $args

return  
    switch($action)
    case "-h" return update:output(unparsed-text("xqdoca.txt"))
    case "-v" return update:output($expkg/@version/string())
    case "-install" return (cmd:install($expkg),update:output("All dependancies installed."))
    case "-init" return
                let $file:=local:resolve(".xqdoca") 
                return if(not(file:exists($file)))
                       then
                        let $xml:=<xqdoca xmlns="urn:quodatum:xqdoca" version="0.5">
                              <source>.</source>
                              <target>xqdoca/</target>
                              </xqdoca>
                        return (file:write($file,$xml),update:output("file created"))     
                       else update:output("file already exists")

    default return let $src:=(cmd:check-dependancies($expkg),
                              local:resolve($action)=>trace("Processing: "))
                   return xquery:eval-update(xs:anyURI("xqdoca.xq"),
                                      map{"src": $src, 
                                          "pass":true()}
                                    )


