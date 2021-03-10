xquery version "3.1";
(:~
 : simple svg generation 
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.calls';

import module namespace xqd = 'quodatum:xqdoca.model' at "../../model.xqm";
import module namespace http="http://expath.org/ns/http-client";

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare  namespace svg = 'quodatum:xqdoca.generator.svg';
declare  namespace dotml = 'http://www.martin-loetzsch.de/DOTML';
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $_:graphxq-server:= "http://localhost:8984/graphxq/";



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
	let $svg:=_:dotml2($dot)
	return $svg
};
	                 
(:~ 
 : data is dotml as XML
  :)
declare function _:dotml2($data as element(*)) 
as document-node()
{
let $form:= <multipart  xmlns="http://expath.org/ns/http-client" media-type="multipart/form-data"> 
                   <header name="Content-Disposition" value='form-data; name="data"'/>   
                   <body media-type="text/xml"/>
            </multipart>
return _:post('/api/dotml', $form, $data)
};

declare function _:dot($data as xs:string) 
as document-node()
{
 let $form:= <multipart  xmlns="http://expath.org/ns/http-client" media-type="multipart/form-data"> 
                     <header name="Content-Disposition" value='form-data; name="data"'/>   
                     <body media-type="text/plain"/>
              </multipart>
return _:post('/api/dotml', $form, $data)
};

declare function _:post($url as xs:string, $form as element(http:multipart),$data ){
  let $req:= <http:request method="POST"  xmlns="http://expath.org/ns/http-client">
              { $form}
            </http:request>
  let $res:= http:send-request($req,$_:graphxq-server || $url ,($data))=>trace("£££££")
return if($res[1]/@status="200") then $res[2] else error()
};
declare function _:node($f as map(*), $opts as map(*)){
  <dotml:record  URL="{ $opts?base }{ $f?href }imports.svg">
    <dotml:node id="{ $f?index}" label="{ $f?namespace }"  URL="{ $f?href }"/>
    <dotml:node id="X{ $f?index}" label="{ $f?path }" URL="http://nowhere.com" />
  </dotml:record>
};

declare function _:edge($from as map(*),$to as map(*)){
  <dotml:edge from="{ $from?index}"  to="{ $to?index}"/>
};