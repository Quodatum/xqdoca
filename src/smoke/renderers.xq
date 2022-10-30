(:~
 information about renderers as map(*)* 
:)

import module namespace xqo = 'quodatum:xqdoca.outputs' at "../main/lib/xqdoc-outputs.xqm";
let $path:="generators/"
let $f:=xqo:load-generators($path)
return ($xqo:module,$xqo:global)!xqo:renderers($f,.)
!xqo:render-map(.)

