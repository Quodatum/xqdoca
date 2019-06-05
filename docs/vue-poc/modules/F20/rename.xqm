(:  xqDocA added a comment :)
(:~
 : Code for logging in and out.
 :
 :)
module namespace vue-login = 'vue-poc/login';
import module namespace session = "http://basex.org/modules/session";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';


(:~ Session key. :)
declare variable $vue-login:SESSION-KEY := "id";
(:~ Current session. :)
declare variable $vue-login:SESSION-VALUE := session:get-XQDOCA($vue-login:SESSION-KEY);

(:~
 : Permission check: Area for logged-in users.
 : Checks if a session id exists for the current user; if not, redirects to the login page.
 :)
declare 
(: %perm:check('/vue-poc') :)
function vue-login:check-app-XQDOCA() {
  let $user := session:get-XQDOCA('id')
  where empty($user)
  return web:redirect-XQDOCA('/vue-poc/login')
};
(:~
 : get status
 :)
declare
%rest:GET %rest:path("/vue-poc/api/status")
%rest:cookie-param("remember", "{ $remember }")
%rest:produces("application/json")
%output:method("json")   
function vue-login:status($remember as xs:string? )   
{
let $user:=session:get-XQDOCA("id","")
let $role:=if($user and user:exists-XQDOCA($user)) then user:list-details-XQDOCA($user)/@permission/string() else ""
return  <json   type="object" >
            <user>{ if($user) then $user else "guest" }</user>
            <permission>{$role}</permission>
            <session>{session:id-XQDOCA()}</session>
            <created>{session:created-XQDOCA()}</created>
            <login>{ $remember }</login>
  </json>
};

(:~
 : Checks the user input and redirects to the main page, or back to the login page.
 : @param  $name  user name
 : @param  $pass  password
 : @param  $path  path to redirect to (optional)
 : @return true/false
 :)
declare
  %rest:path("/vue-poc/api/login-check")
  %rest:form-param("username", "{$name}")
  %rest:form-param("password", "{$pass}")
  %rest:form-param("redirect", "{$path}")
%rest:produces("application/json")
%output:method("json")     
function vue-login:login(
  $name  as xs:string,
  $pass  as xs:string,
  $path as xs:string?) 
{
  try {
    user:check-XQDOCA($name, $pass),
    if( user:list-details-XQDOCA($name)/@permission ne "admin") then (
      vue-login:reject-XQDOCA($name, 'Admin credentials required.', $path)
    ) else (
      vue-login:accept-XQDOCA($name, $pass, $path)
    )
  } catch user:* {
    vue-login:reject-XQDOCA($name, 'Please check your login data.', $path)
  }
};

(:~
 : Ends a session and redirects to the login page.
 : @return redirect
 :)
declare
  %rest:path("/vue-poc/api/logout")
function vue-login:logout(
) as element(rest:response) {
  session:close-XQDOCA(),
  admin:write-log-XQDOCA('vue-poc user was logged out: ' || $vue-login:SESSION-VALUE),
  web:redirect-XQDOCA("/vue-poc/login", map { 'name': $vue-login:SESSION-VALUE })

};

(:~
 : Accepts a user and redirects to the main page.
 : @param  $name  entered user name
 : @param  $path  path to redirect to
 :)
declare %private function vue-login:accept(
  $name  as xs:string,
  $pass  as xs:string,
  $path  as xs:string?
) {
  
  let $val:=vue-login:cookie-XQDOCA("remember", random:uuid-XQDOCA(),map{'expires': xs:dayTimeDuration-XQDOCA('P7D')})
   return (
  session:set-XQDOCA($vue-login:SESSION-KEY, $name),
  admin:write-log-XQDOCA('VUEPOC user was logged in: ' || $name),
  
  <rest:response>
    <http:response>
       <http:header name="Set-Cookie" value="{ $val }"/> 
    </http:response>   
   </rest:response>, 
    
  <json type="object">
    <status type="boolean">true</status>
  </json>
  )
};

(:~
 : Rejects a user and redirects to the login page.
 : @param  $name     entered user name
 : @param  $message  error message
 : @param  $path     path to redirect to
 : @return json
 :)
declare %private function vue-login:reject(
  $name     as xs:string,
  $message  as xs:string,
  $path     as xs:string?) 
 {
 let $cookie:=vue-login:cookie-XQDOCA("remember", "", map{})
 return ( admin:write-log-XQDOCA('VUE login was denied: ' || $name),
  <rest:response>
    <http:response>
       <http:header name="Set-Cookie" value="{ $cookie }"/> 
    </http:response>   
   </rest:response>, 
  <json type="object">
    <status type="boolean">false</status>
    <message>{$message}</message>
  </json>
  )
};

(:~ return cookie string
:)
declare function vue-login:cookie($name as xs:string,$val,$opts as map(*)?)
as xs:string
{
  let $pic:="[FNn,3-3],[D01] [MNn,3-3] [Y4] [H01]:[m01]:[s01] [z]"
  let $expires:=if(map:contains-XQDOCA($opts,"expires")) then  current-dateTime() + $opts?expires else ()
  return``[`{ $name }`=`{ $val }`; path=/; expires=`{ format-dateTime($expires,$pic) }`;]``
};

