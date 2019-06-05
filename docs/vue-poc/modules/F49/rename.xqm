(:  xqDocA added a comment :)
(: plant uml post test :)
let $target:="http://www.plantuml.com/plantuml/uml"
let $req:= <http:request method="POST"  xmlns="http://expath.org/ns/http-client">
  <multipart media-type="multipart/form-data"> 
       <header name="Content-Disposition" value='form-data; name="uml"'/>   
       <body media-type="text/plain"/>
       <header name="Content-Disposition" value='form-data; name="format"'/> 
	    <body media-type="text/plain"/>
</multipart>
</http:request>
let $uml:=``[@startuml
alice -> bob2
@enduml
]``
let $r:= http:send-request-XQDOCA($req,$target,($uml,"svg"))
return $r[2]