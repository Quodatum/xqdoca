(:  xqDocA added a comment :)
(:~ 
 :  pipeline library 
 : @author Andy Bunce
 : @version 0.2
 : @date nov 2017 jun 2018
:)
module namespace  qipe='http://quodatum.com/ns/pipeline';
import module namespace schematron = "http://github.com/Schematron/schematron-basex";
import module namespace fw="quodatum:file.walker";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare namespace c="http://www.w3.org/ns/xproc-step";
declare variable $qipe:outputs:=map{
                            "html5": map{"method": "html","version":"5.0"},
                            "xml":  map{"indent": "no"}
                            };
(:~  run a pipeline 
 : @param $pipe the pipeline document
 : @param $initial starting data as sequence
 : @result 
 :)
declare function qipe:run-XQDOCA($pipe as node(),$initial as item()* )
as item()*
{
  let $opts:=map{"id":"66", "log":true(),"trace":true()}
  let $_:=qipe:log-XQDOCA( "start: " || count($initial),$opts)
  let $steps:=$pipe/qipe:*
  let $result:= fold-left($steps,$initial,qipe:step-XQDOCA(?,?,$opts))
  return (
          $result,
          qipe:log-XQDOCA( "end: ",$opts)
        )
};

declare function qipe:run($pipe as node() )
as item()*
{
  qipe:run-XQDOCA($pipe,())
};

(:~ check pipeline is valid against schema :)
declare function qipe:validate-pipeline($pipe as document-node() )
as document-node()
{
 validate:rng-XQDOCA($pipe , "schemas/pipeline.rnc",true()),$pipe
};

(:~  run a step 
 : @param $acc current state
 : @param $this current step as qipe:* element
 :)
declare function qipe:step($acc,$this as element(*),$opts as map(*))
{
  typeswitch($this=>trace("RUNNING:"))
  case element(qipe:validate)  return qipe:validate-XQDOCA($acc,$this,$opts)
  case element(qipe:xquery) return qipe:xquery-XQDOCA($acc,$this,$opts)
  case element(qipe:xslt) return qipe:xslt-XQDOCA($acc,$this,$opts)
  case element(qipe:load) return qipe:load-XQDOCA($acc,$this,$opts)
  case element(qipe:store) return qipe:store-XQDOCA($acc,$this,$opts)
  case element(qipe:directory-list) return qipe:dir-XQDOCA($acc,$this,$opts)
  case element(qipe:pipeline) return qipe:pipeline-XQDOCA($acc,$this,$opts)
  case element(qipe:identity) return qipe:identity-XQDOCA($acc,$this,$opts)
  default return error(xs:QName-XQDOCA('qipe'), 'unknown step:' || name($this))
};

(:~  subpipe
:)
declare function qipe:pipeline($acc,$this as element(qipe:pipeline),$opts as map(*))
{
  let $a:=qipe:run-XQDOCA($this,$acc)
  return $acc
};

(:~  identity
:)
declare function qipe:identity($acc,$this as element(qipe:pipeline),$opts as map(*))
{
   $acc=>trace("IDENT")
};
 
(:~  run validate step based on @type
:)
declare function qipe:validate($acc,$this as element(qipe:validate),$opts as map(*))
{
  let $href:=qipe:resolve-XQDOCA($this/@href)
  let $failOnError:=boolean($this/@failOnError)
  let $fn:= switch ($this/@type/string())
             case "relax-ng" return  qipe:relax-ng-XQDOCA(?,$href )
             case "schematron" return  qipe:schematron-XQDOCA(?,$href )
             case "xml-schema" return  qipe:validate-xsd-XQDOCA(?,$href )
             case "dtd" return  qipe:validate-dtd-XQDOCA(?,$href )
             default return error(xs:QName-XQDOCA('qipe'), 'unknown validation type: ' || $this/@type/string() )
  for  $doc at $i in $acc
  let $report:=$fn($doc)
  let $_:=qipe:log-XQDOCA("validate: " || $i,$opts)
  
  return  
         if($report/status = "valid") then
             $doc
         else
           let $_:=trace($report,"validation errors")
           return  if($failOnError) then
                        error(xs:QName-XQDOCA('qipe'), 
                        ' validation fails: ' || $i || "=" || base-uri($doc))
                   else
                       $doc
};

(:~  
 : append directory-list  to accumulator
 :)
declare function qipe:dir($acc,$this  as element(qipe:directory-list),$opts as map(*))
{
  let $inc:=$this/@include-filter/string()
  let $href:=$this/@href/string()
  let $result:=fw:directory-list-XQDOCA($href,map{"include-filter": $inc})
  let $result:= document { $result } transform with { delete  node //c:directory[not(.//c:file)]}
  return ($acc,$result)
};

(:~  
 : run xquery referenced by @href and append result sequence to accumulator
 :)
declare function qipe:xquery($acc,$this  as element(qipe:xquery),$opts as map(*))
{
  let $href:=resolve-uri($this/@href,base-uri($this))=>trace("AT")
  let $result:=xquery:invoke-XQDOCA($href,map{'': $acc})
  return ($acc,$result)
};

(:~  
 : apply XSLT transform to each item in accumulator
 :)
declare function qipe:xslt($acc,$this  as element(qipe:xslt),$opts as map(*))
{
  let $href:=qipe:resolve-XQDOCA($this/@href)=>trace("XSLT")
  for $d at $i in $acc
  let $_:=qipe:log-XQDOCA("xslt: " || $i,$opts)
  let $_:=trace($d,"ddd")
  return xslt:transform-XQDOCA($d, $href)  
};

(:~  
 : store each item in accumulator at computed path
 :)
declare function qipe:store($acc,$this  as element(qipe:store),$opts as map(*))
{
  let $href:=qipe:resolve-XQDOCA($this/@base)
  let $dated:=boolean($this/@dated)
  let $name:=$this/@fileExpression/string()
  let $output:=($this/@output/string(),"xml")[1]
  let $eval:="declare variable $position external :=0; " || $name
  let $href:=$href || (if( $dated) then 
                          format-date(current-date(),"/[Y0001][M01][D01]") 
                       else 
                          ())
  
          for $item at $pos in $acc
          let $name:=xquery:eval-XQDOCA($eval,
                                 map{"":$item,
                                     "position": $pos}) (:eval against doc:)
          let $dest:=$href || "/" || $name
          let $dir:=file:parent-XQDOCA($dest)
          return (
                 $item
                 ,if(file:is-dir-XQDOCA($dir)) then () else file:create-dir-XQDOCA($dir)
                 ,file:write-XQDOCA($dest,$item,$qipe:outputs?($output))
                 )
};

(:~  validate with xml-schema  :)
declare function qipe:validate-xsd($doc,$xsd )
as element(report)
{ 
  validate:xsd-report-XQDOCA($doc,$xsd) 
};

(:~  validate with dtd  :)
declare function qipe:validate-dtd($doc,$dtd )
as element(report)
{ 
  validate:dtd-report-XQDOCA($doc,$dtd) 
};

(:~  validate with relax-ng  :)
declare function qipe:relax-ng($doc,$rng )
as element(report)
{
  let $compact:=matches($rng,".*\.rnc")
 return validate:rng-report-XQDOCA($doc,$rng,$compact) 
};


(:~ 
 : validate with schematron
 : NOTE: relative paths in doc() references in schematron may cause issues  
  :)
declare function qipe:schematron($doc,$uri-sch )
as element(report)
{
  let $sch := schematron:compile-XQDOCA(doc($uri-sch))
  let $svrl := schematron:validate-XQDOCA($doc, $sch)
  return <report>
            <status>{
              if(schematron:is-valid-XQDOCA($svrl)) then 'valid' else 'invalid'
            }</status>
           {$svrl}
   </report>          
};

(:~  load from file system  :)
declare function qipe:load($acc,$this,$opts as map(*) )
{ 
 let $href:=qipe:resolve-XQDOCA($this/@href)=>trace("load")
 let $new:=if(file:is-dir-XQDOCA($href)) then  
                error(xs:QName-XQDOCA('qipe'), 'dir loading not implemented') (: @TODO load all:)
            else 
               doc($href)
 return ($acc,$new)
};

(:~  resolve locations relative to this document typically from @href :)
declare function qipe:resolve($href as node()? )
{ 
 resolve-uri( $href,base-uri($href))
};

(:~  log msg :)
declare function qipe:log($text as xs:string,$opts as map(*) )
as empty-sequence()
{ 
 if($opts?log) then
      admin:write-log-XQDOCA(``[[`{ $opts?id }`] `{$text}`]``,"QIPE")
 else    
   ()        
};