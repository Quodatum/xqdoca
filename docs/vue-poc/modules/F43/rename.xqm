(:  xqDocA added a comment :)
module namespace d = 'quodatum.api.data';

(:~
 :  users
 :)
declare
%rest:GET %rest:path("/vue-poc/api/data/users")
%output:method("json")   
function d:list-XQDOCA()
as element(json)
{
 let $jlist:=()
 return <json type="array">
 {for $j in $jlist
 return <_ type="object">
  {()}
 </_>
 }</json>
};

