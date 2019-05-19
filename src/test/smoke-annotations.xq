(: find annotated funcs :)
import module namespace xqd = 'quodatum:xqdoca.xqdoc' at "../main/lib/xqdoc-proj.xqm";
import module namespace xqp = 'quodatum:xqdoca.parser' at "../main/lib/xqdoc-parser.xqm";
import module namespace xqo = 'quodatum:xqdoca.outputs' at "../main/lib/xqdoc-outputs.xqm";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

 xqo:renderers( xqo:load-generators(),$xqo:global)

