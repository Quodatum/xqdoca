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
## License

XQdocA is released under the Apache License, Version 2.0

## Credit, Acknowledgements

* Thanks to Darin McBeath for creating the original xqDoc http://xqdoc.org/.
* XQdocA has much in common with https://github.com/xquery/xquerydoc

* XQuery parsers were generated from EBNF using Gunther Rademacher's excellent http://www.bottlecaps.de/rex/