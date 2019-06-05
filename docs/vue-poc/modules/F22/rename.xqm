(:  xqDocA added a comment :)
xquery version "3.1";
(:~
 : job info
 :)
 module namespace j = 'quodatum.test.xqdoc';


(:~
 :  job list (currently dummy list)
 :)
declare  
%rest:GET %rest:path("/vue-poc/api/xqdocjob")
%output:method("json")   
function j:list-XQDOCA()
as element(json)
{
 let $jlist:=file:list-XQDOCA(db:option-XQDOCA("webpath") || "/static/xqdoc/")
 return <json type="array">
 {for $j in reverse($jlist)
 return <_ type="object">
  <id>{ $j }</id>
  <name>todo</name>
  <href>/static/xqdoc/{ $j }index.html</href>
 </_>
 }</json>
};

(:~
 :  job info (currently dummy item)
 :)
declare  
%rest:GET %rest:path("/vue-poc/api/xqdocjob/{$job}")
%output:method("json")   
function j:job($job)
as element(json)
{
 let $j:=$job
 return <json type="object">
        <todo>uuu</todo>
        </json>
};

