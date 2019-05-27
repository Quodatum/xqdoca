(: find annotated funcs :)

import module namespace xqo = 'quodatum:xqdoca.outputs' at "../main/lib/xqdoc-outputs.xqm";
let $path:="generators/"
let $f:=xqo:load-generators($path)
return ( xqo:renderers($f,$xqo:global),xqo:renderers($f,$xqo:module))
!xqo:render-map(.)

