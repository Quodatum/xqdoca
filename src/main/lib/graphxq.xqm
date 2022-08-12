xquery version "3.1";
(:
 : Copyright (c) 2019-2022 Quodatum Ltd
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)
 
 (:~
 : <h1>graphxq.xqm</h1>
 : <p>talk to graphxq server.</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
module namespace gxq = 'quodatum:serice.graphxq';
import module namespace http="http://expath.org/ns/http-client";

declare variable $gxq:server:= "http://localhost:8984/graphxq/";

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
declare function gxq:post($url as xs:string, $form as element(http:multipart),$data ){
  let $req:= <http:request method="POST"  xmlns="http://expath.org/ns/http-client">
              { $form}
            </http:request>
  let $res:= http:send-request($req,$gxq:server || $url ,($data))
return if($res[1]/@status="200") then $res[2] else error()
};
