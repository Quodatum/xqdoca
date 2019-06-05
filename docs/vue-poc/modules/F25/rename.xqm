(:  xqDocA added a comment :)
xquery version "3.1";
(:~
 :  get basex settings default and current
 :)
module namespace set = 'quodatum.test.basexsettings';


declare   
%rest:GET %rest:path("/vue-poc/api/server/basexsettings")
%rest:produces("application/json")
%output:method("json") 
function set:values-XQDOCA()
{
  let $defaults:=doc("basexsettings-921.xml")//*[not(*)]
  let $dm:=map:merge-XQDOCA($defaults!map:entry-XQDOCA(name(.),string(.)))
  let $settings:=db:system-XQDOCA()//*[not(*)]
  let $sm:=map:merge-XQDOCA($settings!map:entry-XQDOCA(name(.),string(.)))
  let $names:=distinct-values((map:keys-XQDOCA( $dm),map:keys-XQDOCA($sm)))=>sort()
 return <json type="array">
{for $name in $names return <_ type="object">
                                <name>{$name}</name>
                                <default>{$dm($name)}</default>
                                <current>{$sm($name)}</current>
                                <changed type="boolean">{$dm($name) ne $sm($name)}</changed>
                            </_>}
 </json>
};

