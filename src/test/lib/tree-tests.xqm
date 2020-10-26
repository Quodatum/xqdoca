xquery version "3.1";
(:~ 
 : tree.xqm unit tests 
 :)
import module namespace tree = 'quodatum:data.tree' at "../../main/lib/tree.xqm";

declare variable $TEST1:=(

    "/api/environment",
    "/api/execute",
    "/api/library",
    "/api/library/{$id}"
);


(:~
 : smoke test
 :)
declare %unit:test
function tree:build(){
    let $t:=tree:build($TEST1) 
    return unit:assert($t!self::directory[@name=""],"Root should be <directory name=''>" )
};

(:~
 : target test
 :)
declare %unit:test
function tree:target(){
    let $t:=tree:build($TEST1) 
    return unit:assert-equals(count($t//@target),count($TEST1) )
};
declare %unit:test
function tree:build-file(){
    let $t:=unparsed-text-lines("tree-data/paths.txt")
    let $t:=tree:build($t)  
    return unit:assert($t!self::directory[@name=""],"Root should be <directory name=''>")
};

declare %unit:test
function tree:empty(){
 unit:assert(tree:build(())=>empty())
};

declare %unit:test
function tree:empty-string(){
  unit:assert(tree:build('')!self::directory[@name=""])
};

tree:build($TEST1)/directory[@name="api"]
