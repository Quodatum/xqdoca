(:  xqDocA added a comment :)
(:~
 : compile
 :)
module namespace vue-rest = 'quodatum:vue.rest';
import module namespace vue = 'quodatum:vue.compile' at "../../../lib/vue-compile/vue-compile.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';



(:~
 : run compile task.
 :)
declare
%rest:POST %rest:path("/vue-poc/api/tasks/vue-compile")
%rest:form-param("proj", "{$proj}")
%rest:produces("application/json")
%output:method("json")
%updating   
function vue-rest:vue-XQDOCA($proj )   
{
  let $op:=vue:compile-XQDOCA($proj)
  return update:output-XQDOCA(<json type="object"><msg> { $proj }.</msg></json>)
};
