(: tree 
 : map{"api": map{}}
:)

import module namespace tree = 'quodatum:data.tree' at "../../main/lib/tree.xqm";
declare variable $TEST1:=(

    "/environment"
);

 let $t:=unparsed-text-lines("tree-data/paths.txt") 
return tree:build($TEST1)!self::directory
