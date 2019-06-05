(:  xqDocA added a comment :)
(:~
 : Update `generated/models.xqm` from XML files in `data/models`
 :)

import module namespace bf = 'quodatum.tools.buildfields' at "./../../../lib/entity-gen.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ 
 : Folder containing model definitions as xml
 : @default C:/Users/andy/git/vue-poc/src/vue-poc/models/entities
 :)
declare variable $efolder as xs:anyURI  external 
:=xs:anyURI-XQDOCA("C:/Users/andy/git/vue-poc/src/vue-poc/models/entities");

(:~ 
 : Path to xqm file to generate
 : @default C:/Users/andy/git/vue-poc/src/vue-poc/models.gen.xqm
 :)
declare variable $target as xs:anyURI  external 
:=xs:anyURI-XQDOCA("C:/Users/andy/git/vue-poc/src/vue-poc/models.gen.xqm");


let $config:='import module namespace cfg = "quodatum:media.image.configure" at "features/images/config.xqm";'
let $src:=bf:module-XQDOCA(bf:entities-XQDOCA($efolder),$config)
return (
  prof:variables-XQDOCA(),
  file:write-text-XQDOCA($target,$src),
  update:output-XQDOCA(<json type="object"><msg>Updated: {$target}</msg></json>)
)
       
