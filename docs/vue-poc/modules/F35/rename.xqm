(:  xqDocA added a comment :)
import module namespace xqd = 'quodatum:build.xqdoc' at "../../../lib/xqdoc/xqdoc-proj.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace c="http://www.w3.org/ns/xproc-step";

for $f in //c:file
let $ip:= $f/@name/resolve-uri(.,base-uri(.))
return xqd:xqdoc-XQDOCA($ip,map{})