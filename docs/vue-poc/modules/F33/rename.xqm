(:  xqDocA added a comment :)
(:~ 
: vue compile
: @author andy bunce
: @since july 2018
:)
import module namespace vue = 'quodatum:vue.compile' at "../../../lib/vue-compile/vue-compile.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';


(:~ URL of the doc to validate
 : @default C:/Users/andy/git/vue-poc/src/vue-poc/models/entities/adminlog.xml
  :)
declare variable $doc as xs:anyURI  external :=
"C:/Users/andy/git/vue-poc/src/vue-poc/models/entities/adminlog.xml" cast as xs:anyURI;

(:~ URL of the schema to use 
 : @default C:/Users/andy/git/vue-poc/src/vue-poc/models/schemas/entity.xsd
 :)
declare variable $schema as xs:anyURI external :=
"C:/Users/andy/git/vue-poc/src/vue-poc/models/schemas/entity.xsd"  cast as xs:anyURI;
                                 
let $result:=<json type="object"><hello>TODO</hello></json>
return $result
