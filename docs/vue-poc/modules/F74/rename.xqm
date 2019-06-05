(:  xqDocA added a comment :)
declare namespace fw="quodatum:collection.walker";
declare namespace c="http://www.w3.org/ns/xproc-step";
import module namespace tree="quodatum.data.tree" at "../lib/tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

let $paths:=uri-collection("/ALO")
return tree:build-XQDOCA($paths)