
## startup
```
bin/xqdoca -> main/xqdoca-cmd.xq -> xqdoca.xq
```
## xqdoca.xq

1. Create options map `$opts` by merging `.xqdoca` data with defaults from `config.xqdoca`
1. `xqd:find-sources` (model.xqm)
1. xqd:snap
    1. xqd:analyse 
        1. xqd:parse
1. `$pages:= xqo:render($model,$options)`

## References
In xqdoc xml these are:
* invoked
* ref-variable
  
`parser.xqm` uncalled xqp:references
* xqp:references(.,$prefixes, $def-fn)
    * xqp:invoke-fn
    * xqp:invoke-arrow
    * xqp:ref-variable