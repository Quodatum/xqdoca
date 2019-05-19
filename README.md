# XQdocA

Generates documentation from XQuery sources with a focus on use of annotations.
The xqDoc schema. The outputs can be changed or extended with custom generators that are dynamically 
located and loaded at run time. 

## Status

Work in progress.

## Requirements

* `Basex` 9.2+ http://basex.org/
* `ex-parse` 0.6.10+ installed in repository https://github.com/expkg-zone58/ex-xparse/releases/tag/0.6.8

## Usage

The driving script is `xqdoca.xq`. This defines `$options` to use for the run.
In particular the `outputs` option lists the global and module generators to run.

```
   "outputs":  map{
                    "global": ("index","restxq","imports","annotations","swagger1"),
                    "module": ("xqdoc","xqparse","module")  
                }    
```

### Command line

```
basex  -befolder=/Users/andy/git/xqdoca  -btarget=file:///c:/tmp/test/ xqdoca.xq
```
## builtin generators

```
map {
  "output": "html5",
  "name": "index",
  "uri": "index.html",
  "function": Q{quodatum:build.xqdoc-html}index-html2#2,
  "type": Q{https://github.com/Quodatum/xqdoca}global,
  "description": "Index of sources"
}
map {
  "output": "html5",
  "name": "restxq",
  "uri": "restxq.html",
  "function": Q{quodatum:build.xqdoc-html}restxq#2,
  "type": Q{https://github.com/Quodatum/xqdoca}global,
  "description": "Summary of REST interface"
}
map {
  "output": "html5",
  "name": "import",
  "uri": "imports.html",
  "function": Q{quodatum:build.xqdoc-html}imports#2,
  "type": Q{https://github.com/Quodatum/xqdoca}global,
  "description": "Summary of import usage"
}
map {
  "output": "html5",
  "name": "annoations",
  "uri": "annotation.html",
  "function": Q{quodatum:build.xqdoc-html}annotations#2,
  "type": Q{https://github.com/Quodatum/xqdoca}global,
  "description": "Summary of Annotation use"
}
map {
  "output": "xml",
  "name": "xqdoc",
  "uri": "xqdoc.xml",
  "function": Q{quodatum:build.xqdoc-html}xqdoc#3,
  "type": Q{https://github.com/Quodatum/xqdoca}module,
  "description": "xqDoc file for the source module"
}
map {
  "output": "xml",
  "name": "xqparse",
  "uri": "xqparse.xml",
  "function": Q{quodatum:build.xqdoc-html}xqparse#3,
  "type": Q{https://github.com/Quodatum/xqdoca}module,
  "description": "xqparse file for the source module"
}
map {
  "output": "html5",
  "name": "module",
  "uri": "index.html",
  "function": Q{quodatum:xqdoca.mod-html}xqdoc-html2#3,
  "type": Q{https://github.com/Quodatum/xqdoca}module,
  "description": "Html5 page created from the XQuery source"
}
```
## Customization
The available output generators are determined by scanning the `generators` folder for functions
containing annotations in the `https://github.com/Quodatum/xqdoca` namespace, usually bound to the 
prefix `xqdoca`

 Two kinds of generator are currently defined: `global` and `module`. 
 
### Global generators
These functions generate one output file derived from the entire source.
They have the `xqdoca:global` annotation.
The first parameter is an arbitary name used to reference the generator in the run `options`
The second is a simple text description.
The function must be of arity 2 and is called with the state and options as arguments.
Example:
```
declare 
%xqdoca:global("index","Index of sources")
%xqdoca:output("index.html","html5") 
function xqhtml:index-html2($state as map(*),
                            $opts as map(*)
                            )
as document-node()          
```

### Module generators
These functions generate one file per XQuery source file.
The function must be of arity 3 and is called once for each source module 
with the current file state and options and the state as arguments.
Example:
```
declare 
%xqdoca:module("module","Html5 page created from the XQuery source")
%xqdoca:output("index.html","html5")
function xqh:xqdoc-html2($file as map(*),
                            $opts as map(*),
                            $state as map(*)
                            )
as document-node()
```
                  
### Serialization
All generator functions require an output annotation that controls the name and serialization of that output.
The first parameter controls the name of the generated output. The second the serialization required.
Examples:
```
%xqdoca:output("index.html","html5")
%xqdoca:output("swagger.json","json")
%xqdoca:output("xqparse.xml","xml")  
``` 
#### current serialization types
```
map{
 "html5": map{"method": "html", "version":"5.0", "indent": "no"},
 "xml": map{"indent": "no"},
 "json": map{"method": "json"}
}
```
## License

XQdocA is released under the Apache License, Version 2.0

## Credit, Acknowledgements

* Thanks to Darin McBeath for creating the original xqDoc http://xqdoc.org/.
* XQdocA has much in common with https://github.com/xquery/xquerydoc

* XQuery parsers were generated from EBNF using Gunther Rademacher's excellent http://www.bottlecaps.de/rex/