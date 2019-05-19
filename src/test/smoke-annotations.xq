(: find annotated funcs :)

import module namespace xqo = 'quodatum:xqdoca.outputs' at "../main/lib/xqdoc-outputs.xqm";

let $f:=xqo:load-generators()
return ( xqo:renderers($f,$xqo:global),xqo:renderers($f,$xqo:module))
!xqo:render-map(.)

