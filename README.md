# XQdocA

Generates documentation from XQuery sources with a focus on use of annotations.
The xqDoc schema.

## Status

Work in progress - not currently usable.

## Requirements

* `Basex` 9.2+ http://basex.org/
* `ex-parse` 0.6.8+ installed in repository https://github.com/expkg-zone58/ex-xparse/releases/tag/0.6.8

## Usage

### Command line

```
basex  -befolder=/Users/andy/git/xqdoca  -btarget=file:///c:/tmp/test/ xqdoca.xq
```



## License

XQdocA is released under the Apache License, Version 2.0

## Credit, Acknowledgements

* Thanks to Darin McBeath for creating the original xqDoc http://xqdoc.org/.
* XQdocA has much in common with https://github.com/xquery/xquerydoc

* XQuery parsers were generated from EBNF using Gunther Rademacher's excellent http://www.bottlecaps.de/rex/