xquery version "3.1";
(:~ 
 : test tree
 :)
import module namespace tree = 'quodatum:data.tree' at "tree.xqm";

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
function tree:test(){
    let $t:=tree:build($TEST1) 
    return unit:assert(fn:true(),$t)
};

declare %unit:test
function tree:test3(){
    let $t:=unparsed-text-lines("tree-data/paths.txt") 
    return unit:assert(fn:true(),$t)
};

tree:build($TEST1)/directory[@name="api"]
