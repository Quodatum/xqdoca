xquery version "3.1";

 
 (:~
 : simple swagger generation
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 
(:~
 : Generate XQuery  documentation in html
 : using file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models
 : $efolder:="file:///C:/Users/andy/workspace/app-doc/src/doc/data/doc/models"
 : $target:="file:///C:/Users/andy/workspace/app-doc/src/doc/generated/models.xqm"
 :)
module namespace openapi = 'quodatum:xqdoca.swagger';

declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


declare 
%xqdoca:global("swagger1","Generate swagger from restxq ")
%xqdoca:output("swagger.json","json") 
function openapi:swagger($state as map(*),
                            $opts as map(*)
                            )                           
{
<json type="object">
   <swagger>2.0</swagger>
   <info type="object">
    <version>1.0.0</version>
    <title>Generated from { $state?project } at { current-dateTime() }</title>
    <description>Example generation from RESTXQ xquery sources</description>
    <termsOfService>http://swagger.io/terms/</termsOfService>
    <contact type="object">
     <name>Andy Bunce</name>
    </contact>
    <license type="object">
      <name>MIT</name>
    </license>
  </info>
  <host>github.com/Quodatum/xqdoca</host>
  <basePath>/api</basePath>
</json>
};

