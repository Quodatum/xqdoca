xquery version "3.1";
(: Copyright (c) 2019-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
 :)
 
 (:~
 : <h1>meta.xqm</h1>
 : <p>Generate meta data about the <code>xqDocA</code> run</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
(:~
 : Generate metadata about the current xqdoca execution
 :)
module namespace _ = 'quodatum:xqdoca.generator.meta';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~
 : metadata. 
 :)
declare 
%xqdoca:global("xqdoca.xml","xqDocA run configuration report (XML)")
%xqdoca:output("xqdoca.xml","xml") 
function _:restxq($model,$opts)
{
<xqdoca created="{current-dateTime()}">
{
let $f:=function($v,$this){
  typeswitch($v)
  case xs:anyAtomicType return $v
  case   map(*) return map:for-each($v,
                     function($k,$v){ if(starts-with($k,".")) then () else element {$k} { $this($v,$this)}
                })
  default return $v!<_>{.}</_>
}
return $f($opts,$f)
}
</xqdoca>
};
