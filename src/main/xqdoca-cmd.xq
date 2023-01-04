xquery version "3.1";
(:~  
 Process xqdoca command line options and execution
 @see xqdoc.xq 
 @author Andy Bunce (Quodatum)
 :)

import module namespace cmd = 'quodatum:tools:commandline' at "lib/commandline.xqm";
declare namespace pkg="http://expath.org/ns/pkg";

(:~ command line args :)
declare variable $args as xs:string  external;

(:~ expath metadata from expath-pkg.xml :)
declare variable $expkg as element(pkg:package):= doc("expath-pkg.xml")/*;

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
    case "-h" return 
              update:output(unparsed-text("xqdoca.txt"))

    case "-v" return
              let $xqd:= $expkg/@version/string()
              let $java:= proc:property('java.runtime.version')
              let $basex:= db:system()/generalinformation/version/string()
              return update:output(``[xqdoca=`{$xqd}`, basex=`{$basex}`, java=`{$java}`]``)

    case "-install" 
    case "-update" return (cmd:install($expkg)
                          ,update:output("All dependancies installed."))

    case "-init" return
                let $file:=local:resolve(".xqdoca") 
                return if(not(file:exists($file)))
                       then
                        let $xml:=<xqdoca xmlns="urn:quodatum:xqdoca" version="1.0">
                              <source>.</source>
                              <target>xqdoca/</target>
                              </xqdoca>
                        return (file:write($file,$xml),update:output("file created"))     
                       else update:output("xqdoca file already exists")

    default return 
            let $src:=(cmd:check-dependancies($expkg),
                        local:resolve($action)=>trace("Processing: "))
            return xquery:eval-update(xs:anyURI("xqdoca.xq"),
                                      map{"src": $src, 
                                          "pass":true()}
                                    )


