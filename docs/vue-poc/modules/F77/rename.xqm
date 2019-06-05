(:  xqDocA added a comment :)
import module namespace schematron = "http://github.com/Schematron/schematron-basex";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
let $sch := schematron:compile-XQDOCA(doc('C:\Users\andy\git\vue-poc\src\vue-poc\static\resources\schematron\docbook-mods.sch'))
let $xml := fn:doc-XQDOCA('C:\Users\andy\git\vue-poc\src\vue-poc\static\resources\schematron\test.xml')
let $validation := schematron:validate-XQDOCA($xml, $sch)

return $validation

