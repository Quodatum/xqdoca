xquery version "3.1";
(:~
 : simple swagger generation 
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.swagger';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
(:~ 
 :  This is just shell NO detail provided!!
 :)
declare 
%xqdoca:global("swagger1","Swagger file (JSON format) from restxq annotations.")
%xqdoca:output("swagger.json","json") 
function _:swagger($model as map(*),
                            $opts as map(*)
                            )                           
{
<json type="object">
   <swagger>2.0</swagger>
   <info type="object">
    <version>1.0.0</version>
    <title>Generated from { $model?project } at { current-dateTime() }</title>
    <description>Example generation from RESTXQ xquery sources</description>
    <termsOfService>http://swagger.io/terms/</termsOfService>
    <contact type="object">
     <name>Andy Bunce</name>
    </contact>
    <license type="object">
      <name>MIT</name>
    </license>
  </info>
  <host>http://localhost:8984/</host>
  <basePath>/api</basePath>
</json>
};

