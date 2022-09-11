# XQdocA

Generates documentation from XQuery sources with a focus on use of annotations.
The outputs can be changed or extended with custom generators that are dynamically 
located and loaded at run time. 

A paper on this project was presented at [Markup UK](https://markupuk.org/) 2019.

*Generating documents from XQuery annotations* [HTML](https://markupuk.org/2019/webhelp/index.html#ar04.html) 

## Status

Work in progress.

## Requirements

* `Basex` 9.5.1+ http://basex.org/
* `ex-parse` 0.7.8+ (install from https://github.com/expkg-zone58/ex-xparse/releases/)

## Install
1. unzip dist bundle to a folder
1. Add the `/bin` folder to your `PATH`
1. Execute `xqdoca -install`. 

The XQDocA script uses the `basex` script. If the environment variable `BASEX_HOME` is set it will run the basex script in that bin folder otherwise  it will search for basex on the `PATH`
## Usage

XQDocA uses XML files to define the documentation task. These typically use the extension `.xqdoc`

For example the file `samples/dba.xqdoca`
```
<xqdoca xmlns="urn:quodatum:xqdoca" version="1.0">
    <source>C:\Users\andy\basex.home\basex.951\webapp\dba</source>
    <target>file:///tmp/dba/</target>
</xqdoca>
```
Then `xqdoca samples/dba.xqdoca` will generate documentation for XQuery sources below `C:\Users\andy\basex.home\basex.951\webapp\dba` and write it to 
`file:///tmp/dba/`

If  `source` or `target` are relative urls they are resolved relative to the xqdoca file.

`xqdoca -h` will display a summary of the options.



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
### Development notes
`xqdoca` execution scans the source folder to locate XQuery sources. These are then analysed using a 
combination of the `ex-parse` package and the BaseX `inspect:xqdoc` function.

The results are used to create an in-memory map

```mermaid
classDiagram
   direction LR
   class model{
   <<map(*)>>
   +base-uri
   +project
   +files
   }
   class file{
    <<map(*)>>
    +path
    +href
    +namespace
    +xqdoc
    +xparse
    +prefixes
   }
   class xqdoc{
    <<element(xqdoc)>>
    }
   class xqparse {
   <<element(XQUERY)>>
   }
   model "0..n" --|> file : files
   file "1" --|> xqdoc : xqdoc
   file "1" --|> xqparse : xqparse
```
### File
*  "index": $pos,
*  "path": translate($file,"\","/"),
*  "href": ``[modules/`{ $id }`/]``,
*  "parsed": $isParsed,
*  "prefixes": xqd:namespaces( $analysis?xqdoc),
*  "annotations": xqd:anno($analysis?xqdoc), (: sequence map{annotation:, xqdoc: } :)
*  "namespace":$analysis?xqdoc/xqdoc:module/xqdoc:uri/string(), 
*  "default-fn-uri": xqp:default-fn-uri($analysis?xqparse) 

The renderers use this map to build their outputs.

## License

XQdocA is released under the Apache License, Version 2.0

## Third party components

* Semantic versioning uses https://github.com/eXist-db/semver.xq
* XQuery source highlighting uses Prism (https://prismjs.com/)
* The mermaid renderer uses https://github.com/mermaid-js/mermaid

## Credit, Acknowledgements

* Thanks to Darin McBeath for creating the original xqDoc http://xqdoc.org/.
* XQdocA has much in common with https://github.com/xquery/xquerydoc

* XQuery parsers were generated from EBNF using Gunther Rademacher's excellent http://www.bottlecaps.de/rex/


