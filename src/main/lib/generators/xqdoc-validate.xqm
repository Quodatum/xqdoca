xquery version "3.1";

 
 (:~
 : simple swagger generation 
 : NOTE this is just shell no detail provided
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 
(:~
 : Generate XQuery  documentation in html
 : using file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models
 : $efolder:="file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models"
 : $target:="file:///C:/Users/andy/workspace/app-doc/src/doc/generated/models.xqm"
 :)
module namespace _ = 'quodatum:xqdoca.generator.validate-xqdoc';

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


declare 
%xqdoca:global("xqdoc-validate","validate generated xqdoc files")
%xqdoca:output("validation-report.xml","xml") 
function _:validate($model as map(*),
                            $opts as map(*)
                            )                           
{
let $schema:=resolve-uri("../../etc/xqdoc-1.0.01132014.xsd",static-base-uri())=>trace("xqdoc schema: ")
let $reports:=for $f in $model?files
              return $f?xqdoc!validate:xsd-report($schema) 
                      transform with {insert node attribute source { $f?path } into .}

return <errors>{ $reports }</errors>
};

