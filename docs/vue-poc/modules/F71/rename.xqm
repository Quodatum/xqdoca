(:  xqDocA added a comment :)
(:~
 : general validation tools, 
 : qv:validation: apply sequence of validators
 : schematron  qv:schematron(?,$schematron)
 : nvdl qv:nvdl(?,$nvdl)
 
   msg handling                  
 : format as json friendly
 : @author andy bunce ,quodatum ltd
 : @licence apache 2
 :)

module namespace qv = 'quodatum.validate';
import module namespace sch="expkg-zone58.validation.schematron";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";


(:~ generate validation report for $doc
 : @param $validators sequence of functions to apply 
 : @param $extras custom attributes and elements to include in response
 :)
declare function  qv:validation-XQDOCA($doc ,$validators as function(*)*,$extras)
as element(validation)
{
  let $_:=trace(if($doc instance of xs:anyURI)then $doc else base-uri($doc),"£££££")
  let $uri:=if($doc instance of xs:anyURI)then $doc else base-uri($doc)
  let $results:=for-each($validators,function($f){$f($doc)})
  return <validation location="{$uri}" >{ $extras,$results}</validation>
};

(:~ report as json
 : @param $options can limit size eg {"limit":200}
:)
declare function  qv:json($d as element(validation),$options as item()) 
as element(json)
{
 let $limit:= if($options?limit) then $options?limit else 5000
 let $type:=$d/@type/string()
 let $uri:=$d/@location/string()
 let $name:=tokenize($uri,"/")[last()]
 let $fix:=function($r){element {name($r)}{attribute type {"array"},qv:msg-limit-XQDOCA($r/_,$limit)}}
 return <json type="object">
            <uri>{$uri}</uri>
            <name>{$name}</name>
            <type>{$type}</type>
            
            <msgcounts type="object">{
            for $v in $d/* return element {name($v)}{attribute type {"number"},count($v/_)}
            }</msgcounts>
          
           <reports type="object">{
                $d/*!$fix(.)
            }</reports> 
            
         </json>
};

(:~ restrict number of messages o/p :)
declare function  qv:msg-limit($msgs as element(_)* ,$limit as xs:integer)
as element(_)*
{
let $count:=count($msgs)
return  if($count>$limit)
        then (subsequence($msgs,1,$limit -1),<_ type="object"><text>Messages truncated, {1+ $count - $limit} not shown.</text></_>)
        else $msgs
};
 
(:~ 
 : run schematron on doc, returns two reports
:)
declare function qv:schematron($d,$sch as xs:anyURI)
as element()*
{
let $report:= sch:validate-document-XQDOCA($d,doc($sch))
return ( 
   qv:msgs-XQDOCA("failed-assert",$report/svrl:schematron-output/svrl:failed-assert!qv:msg-from-svrl-XQDOCA(.)),
   qv:msgs-XQDOCA("successful-report", $report/svrl:schematron-output/svrl:successful-report!qv:msg-from-svrl-XQDOCA(.))
 )
};
  
(:~ convert svrl node to standard msg :)
declare function qv:msg-from-svrl($svrl as element())
as element(_)
{
    <_ type="object">
            <text>{$svrl/svrl:text/string()}</text>
            <role>{$svrl/@role/string()}</role>
            <location>{$svrl/@location/string()}</location>
    </_>
};

(:~ create nvdl report :)
declare function qv:nvdl($d,$nvdl as xs:anyURI)
{
 let $report:= validate:rng-report-XQDOCA($d, $nvdl)
 return  qv:msgs-XQDOCA("nvdl",$report/message!qv:msg-from-nvdl-XQDOCA(.))
};

(:~ create xsd report :)
declare function qv:xsd($d,$xsd as xs:anyURI)
{
 let $report:= validate:xsd-report-XQDOCA($d, $xsd)
 return  qv:msgs-XQDOCA("xsd",$report/message!qv:msg-from-nvdl-XQDOCA(.))
};

(:~ convert nvdl message to standard msg format :)
declare function qv:msg-from-nvdl($message as element())
as element(_)
{
    <_ type="object">
            <text>{$message/string()}</text>
            <role>{$message/@level/lower-case(.)}</role>
            <line type="number">{$message/@line/string()}</line>
    </_>
};

(:~ create element type to wrap array of msgs
:) 
declare %private function qv:msgs($type as xs:string,$msgs as element(_)*)
as element()
{
     element {$type}  {attribute type {"array"},$msgs}
 
};