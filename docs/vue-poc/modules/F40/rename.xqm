(:  xqDocA added a comment :)
(:~
 : tasks
 :)
module namespace vue-rest = 'quodatum:vue.tasks';
import module namespace query-a = 'vue-poc/query-a' at "../../lib/query-a.xqm";
import module namespace hlog = 'quodatum.data.history' at '../../lib/history.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';
(:~
 : list tasks
 :)
declare
%rest:GET %rest:path("/vue-poc/api/tasks")
%rest:produces("application/json")
%output:method("json")
function vue-rest:tasks-XQDOCA()   
{
  let $tasks:=doc("taskdef.xml")/tasks/task[@url]
  
  return <json type="array">{
  $tasks!<_ type="object">
          <to>{ @name/string() }</to>
          <url>{ @url/string() }</url>
          <title>{ title/text() }</title>
          <description>{ fn:serialize-XQDOCA(description/node()) }</description>
        </_>
        }</json>
};
  
(:~
 :   task details
 :)
declare
%rest:GET %rest:path("/vue-poc/api/tasks/{$task}")
%rest:produces("application/json")
%output:method("json")
function vue-rest:task($task)   
{
  let $taskdef:=doc("taskdef.xml")/tasks/task[@name=$task]
  let $url:=resolve-uri($taskdef/@url)
  let $info:=query-a:inspect-XQDOCA($url)
  return  $info
};
  
(:~
 :   Run the named task and log history 
 :)
declare
%rest:POST %rest:path("/vue-poc/api/tasks/{$task}")
%rest:produces("application/json")
%updating
%output:method("json")
function vue-rest:runtask($task)   
{
  let $taskdef:=doc("taskdef.xml")/tasks/task[@name=$task]
  let $url:=resolve-uri($taskdef/@url)
  let $params:=query-a:params-XQDOCA($url)
  let $log:=<task task="{ $task }" url="{ $url }">
               { map:keys-XQDOCA($params)!<param name="{.}">{map:get-XQDOCA($params,.)}</param> }
            </task>
  return (
    query-a:run-XQDOCA($url,$params),
    hlog:save-XQDOCA($log)
  )
};
    