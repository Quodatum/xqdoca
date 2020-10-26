xquery version "3.1";
(:~
 : simple wadl generation 
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.wadl';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
(:~ 
 :  This is just shell NO detail provided!!
 :)
declare 
%xqdoca:global("wadl1","wadl from restxq annotations.")
%xqdoca:output("wadl.xml","xml") 
function _:wadl($model as map(*),
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

