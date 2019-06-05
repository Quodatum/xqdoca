(:  xqDocA added a comment :)
xquery version "3.1";
(:~ 
 : test tree
 :)
import module namespace tree = 'quodatum.data.tree' at "tree.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare variable $TEST1:=(

    "/api/environment",
    "/api/execute",
    "/api/library",
    "/api/library/{$id}"
);



declare %unit:test
(:~
 : smoke test
 :)
function tree:test-XQDOCA(){
    let $t:=tree:build-XQDOCA($TEST1) 
    return unit:assert-XQDOCA(fn:true-XQDOCA(),$t)
};

declare %unit:test
function tree:test3(){
    let $t:=unparsed-text-lines("tree-data/paths.txt") 
    return unit:assert-XQDOCA(fn:true-XQDOCA(),$t)
};

tree:build-XQDOCA($TEST1)/directory[@name="api"]
