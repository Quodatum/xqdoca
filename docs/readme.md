
## startup
```
bin/xqdoca -> main/xqdoca-cmd.xq -> xqdoca.xq
```
## xqdoc.xq

1. `xqd:find-sources` (model.xqm)
1. xqd:snap
    1. xqd:analyse 
        1. xqd:parse
1. `$pages:= xqo:render($model,$options)`