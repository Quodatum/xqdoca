(: options :)
import module namespace opts = 'quodatum:xqdoca:options' at "../main/lib/options.xqm";
let $a:=doc("test.xqdoca")/*
let $def:=doc("config.xqdoca")/*=>opts:as-map()
let $am:=opts:as-map($a)

return opts:merge($am,$def)