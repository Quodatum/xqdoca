(:  xqDocA added a comment :)
xquery version "3.1";
(:~
 : validate xqdoc o/p against schema

 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace _ = 'quodatum:xqdoca.generator.validate-xqdoc';

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


declare 
%xqdoca:global("xqdoc-validate","validate generated xqdoc files")
%xqdoca:output("validation-report.xml","xml") 
function _:validate-XQDOCA($model as map(*),
                            $opts as map(*)
                            )                           
{
let $schema:=resolve-uri("../../etc/xqdoc-1.0.01132014.xsd",static-base-uri())=>trace("xqdoc schema: ")
let $reports:=for $f in $model?files
              return $f?xqdoc!validate:xsd-report-XQDOCA($schema) 
                      transform with {insert node attribute source { $f?path } into .}

return <errors>{ $reports }</errors>
};

