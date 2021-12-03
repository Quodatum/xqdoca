xquery version "3.1";
(:~
 : import diagrams using svg, requires   access to a graphxq server
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.calls';

import module namespace xqd = 'quodatum:xqdoca.model' at "../../model.xqm";
import module namespace gxq = 'quodatum:serice.graphxq' at "../../graphxq.xqm";


declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare  namespace svg = 'quodatum:xqdoca.generator.svg';
declare  namespace dotml = 'http://www.martin-loetzsch.de/DOTML';
declare namespace xqdoc="http://www.xqdoc.org/1.0";


declare 
%xqdoca:global("imports.svg","Project all module imports as svg")
%xqdoca:output("imports.svg","xml") 
function _:calls(        
                 $model as map(*),
                 $opts as map(*)
                 )                         
{
	  _:build( $model?files, $model, map{"base":""})
};

declare 
%xqdoca:module("imports.svg","imports for this module as svg")
%xqdoca:output("imports.svg","xml") 
function _:module($file as map(*),         
               $model as map(*),
               $opts as map(*)
              )
{
   _:build( $file, $model, map{"base":"../../"})      
};
 
 (:~ import svg for set of files :)
 declare function _:build($files as map(*)*,         
                         $model as map(*),
                         $opts as map(*) )
 {                   
   let $nodes:=$files!_:node(.,$opts) 
                
	let $edges := for $f at $pos in  $files 
                return _:edge($f,$f)
	let $dot:=_:graph(($nodes,$edges),$opts)
           
	let $svg:=gxq:dotml2($dot)
	return $svg
};

(:~ import svg for set of files :)
 declare function _:build-old($files as map(*)*,         
                         $model as map(*),
                         $opts as map(*) )
 {
    let $imports:= xqd:imports($model)
  let $defs:=xqd:defs($model)                        
    let $op:=for $f in  ($files[ ?xqdoc//xqdoc:import[@type="library"]]
                        ,$model?files[map:contains($imports,?namespace)]
                      )
	          let $n:= _:node($f,$opts) 
	          let $ins:=$f?xqdoc//xqdoc:import[@type="library"]/xqdoc:uri/string()        
	          let $e:=$ins! $defs(.)!_:edge(.,$f)
	          return ($n,$e)
	 
	let $dot:=<dotml:graph rankdir = "LR">	
             <dotml:node 	id="a" label="Home" URL="{ $opts?base}."  color="#FFFFDD" style="filled" shape="house"/>{ $op }
            </dotml:graph>
	(: let $svg:=_:dotml2($dot) :)
	return $dot
};
	                 


(:~ create node
 :)
 declare function _:node($f as map(*), $opts as map(*))
as element(dotml:record)
{
  <dotml:record  URL="{ $opts?base }{ $f?href }imports.svg">
    <dotml:node id="N{ $f?index}" label="{ $f?namespace }"  URL="{ $f?href }"  fillcolor="#FFFFFF"/>
    <dotml:node id="X{ $f?index}" label="{ $f?path }" URL="http://nowhere.com" />
  </dotml:record>
};

(:~ create edge :)
declare function _:edge($to as map(*),$from as map(*)){
  <dotml:edge from="N{ $from?index}"  to="N{ $to?index}"/>
};

(:~ create dotml graph :)
declare function _:graph($nodes,$opts){
 <dotml:graph  rankdir="LR" bgcolor="silver">	
             <dotml:node 	id="a" label="Home" URL="{ $opts?base}."  color="#FFFFDD" style="filled" shape="house"/>{  
             $nodes
}</dotml:graph>  
};