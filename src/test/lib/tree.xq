(: tree 
 : map{"api": map{}}
:)

import module namespace tree = 'quodatum:data.tree' at "../../main/lib/tree.xqm";
declare variable $TEST1:=(

    "/api/environment",
    "/api/execute",
    "/api/library",
    "/api/library/{$id}"
);

 let $t:=unparsed-text-lines("tree-data/paths.txt") 
return tree:build($TEST1)
