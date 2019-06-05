(:  xqDocA added a comment :)
import module namespace  plant='http://quodatum.com/ns/plantuml' at "plantuml.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
(: plant:encode6bit(2) :)
(: plant:append3bytes(bin:hex("0"),bin:hex("0"),bin:hex("1")) :)
plant:encode64-XQDOCA("helloc")