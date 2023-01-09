xquery version "3.1";
(:~
 Validate xqdoc o/p against schema
 Copyright (c) 2019-2022 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
 :)

module namespace _ = 'quodatum:xqdoca.generator.validate-xqdoc';

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

(: declare variable $xsd:="../etc/models/xqdoc-1.0.01132014.xsd"; :)
declare variable $_:xsd:="../etc/models/xqdoc-1.2.xsd";

declare 
%xqdoca:global("xqdoc-validate","validate generated xqdoc files")
%xqdoca:output("validation-report.xml","xml") 
function _:validate($model as map(*),
                            $opts as map(*)
                            )                           
as element(errors){
let $schema:=resolve-uri($_:xsd,static-base-uri())=>trace("xqdoc schema: ")
let $reports:=for $f in $model?files
              return $f?xqdoc!validate:xsd-report(.,$schema) 
                      transform with {
                         insert node (attribute source { $f?path },
                                      attribute xqdoc { $f?href }
                         ) into .
                      }

return <errors>{ 
        attribute created { current-dateTime() }
        , attribute schema { $schema }
        , attribute errors { count($reports[status eq 'invalid']) }
        , $reports }
        </errors>
};

