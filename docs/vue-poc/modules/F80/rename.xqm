(:  xqDocA added a comment :)
xquery version "3.1";
(:~
 : vue-poc api.
 :
 : @author Andy Bunce may-2017
 :)
module namespace vue-api = 'quodatum:vue.api';
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace session = "http://basex.org/modules/session";
import module namespace entity = 'quodatum.models.generated' at "models.gen.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';



declare namespace c="http://www.w3.org/ns/xproc-step";

declare namespace wadl="http://wadl.dev.java.net/2009/02";

(:~
 : get status
 :)
declare
%rest:GET %rest:path("/vue-poc/api/start")
 function vue-api:start-XQDOCA( )   
{
  if(db:exists-XQDOCA("vue-poc")) then
   ()
  else 
  ()
};



(:~
 : Returns test list for select.
 :)
declare
%rest:path("/vue-poc/api/test-select")
%rest:query-param("q", "{$q}")
%rest:produces("application/json")
%output:method("json")   
function vue-api:test-select($q )   
{
  <json   type="object" >
            <items type="array">
            {(1 to 100)!(<_ type="object">
             <name>A{ . }</name>
             <value>V{ . }</value>
            </_>)}              
            </items>
  </json>
};

(:~
 : generate html report for test
 :)
declare
%rest:GET %rest:path("/vue-poc/api/test/html")
%output:method("html")  %output:version("5.0") 
function vue-api:test-html()   
{
<div id="A0">
something
<ol>
<li><a href="#A30" >A30</a></li>
<li><a href="#A50">A50</a></li>
</ol>
{for $i in 1 to 50 return <p>{$i}: 
<a id="A{$i}" name="A{$i}">Lorem ipsum</a> dolor sit amet, consectetur adipiscing elit. Morbi aliquam sodales justo, aliquet eleifend ex bibendum eget. Nullam vitae maximus ipsum. Sed maximus felis in interdum maximus. Vestibulum quis urna vel dolor placerat iaculis non at metus. Curabitur nec dictum mauris. Duis placerat magna non pellentesque pulvinar. Nam a eleifend sapien. Suspendisse potenti. Vestibulum nunc massa, eleifend a dolor quis, feugiat condimentum est. Integer diam eros, blandit in purus in, euismod ultrices felis. Donec ipsum magna, elementum non lacus vel, rutrum ornare ante. Integer egestas sapien quam, ut posuere nisi rhoncus nec. Etiam ornare enim eu tellus laoreet, in laoreet urna sodales. Donec interdum, augue non lobortis sodales, leo elit tincidunt mi, vitae varius augue libero vel lectus. Cras imperdiet quis dolor nec gravida. 
<a href="#A0">top</a></p>
}
</div>
};
(:~
 : Returns wadl.
 :)
declare
%rest:path("/vue-poc/api")
function vue-api:wadl()   
{
 rest:wadl-XQDOCA()
};

(:~
 :  user list
 :)
declare  
%rest:GET %rest:path("/vue-poc/api/user")
%output:method("json")   
function vue-api:user()
as element(json)
{
 let $jlist:=user:list
 return <json type="array">
 {for $j in $jlist
 return <_ type="object">
  <name>{$j}</name>
 </_>
 }</json>
};

(:~
 :  repo list
 :)
declare  
%rest:GET %rest:path("/vue-poc/api/repo")
%output:method("json")   
function vue-api:repo()
as element(json)
{
 let $jlist:=repo:list-XQDOCA()
 return <json type="array">
 {for $j in $jlist
 return <_ type="object">
  <name>{$j}</name>
 </_>
 }</json>
};

declare
  %rest:POST
  %rest:path("/vue-poc/api/upload")
  %rest:form-param("files", "{$files}")
function vue-api:upload($files) {
  for $name    in map:keys-XQDOCA($files)
  let $content := $files($name)
  let $path    := file:temp-dir-XQDOCA() || $name
  return (
    file:write-binary-XQDOCA($path, $content),
    <file name="{ $name }" size="{ file:size-XQDOCA($path) }"/>
  )
};