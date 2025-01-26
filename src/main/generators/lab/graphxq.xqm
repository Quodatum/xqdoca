xquery version "3.1";
(:~
talk to graphxq server.
@copyright Copyright (c) 2019-2022 Quodatum Ltd
@author Andy Bunce, Quodatum, License: Apache-2.0
:)
module namespace gxq = 'quodatum:service.graphxq';
import module namespace http="http://expath.org/ns/http-client";

(:~ graphxq server url :)
declare variable $gxq:server:= "http://localhost:8984/graphxq/";

(:~ test server available :)
declare variable $gxq:server-ok as xs:boolean:= 200=http:send-request(<http:request method='get' status-only='true'/>, $gxq:server)/@status;

(:~
 : convert dotml to svg 
 : @parm $data is dotml as XML
 :)
declare function gxq:dotml2($data as element(*)) 
as document-node()
{
let $form:= <multipart  xmlns="http://expath.org/ns/http-client" media-type="multipart/form-data"> 
                   <header name="Content-Disposition" value='form-data; name="data"'/>   
                   <body media-type="text/xml"/>
            </multipart>
return gxq:post('/api/dotml', $form, $data)
};

(:~
 : convert dot to svg 
 : @parm $data is dot as text
 :)
declare function gxq:dot($data as xs:string) 
as document-node()
{
 let $form:= <multipart  xmlns="http://expath.org/ns/http-client" media-type="multipart/form-data"> 
                     <header name="Content-Disposition" value='form-data; name="data"'/>   
                     <body media-type="text/plain"/>
              </multipart>
return gxq:post('/api/dotml', $form, $data)
};

(:~ graphxq request :)
declare function gxq:post($url as xs:string, $form as element(http:multipart),$data )
{
  let $req:= <http:request method="POST"  xmlns="http://expath.org/ns/http-client">
              { $form}
            </http:request>
  let $res:= http:send-request($req,$gxq:server || $url ,($data))
return if($res[1]/@status="200") then $res[2] else error()
};
