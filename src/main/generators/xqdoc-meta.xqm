xquery version "3.1";
(:~
   <p>Generate meta data about the <code>xqDocA</code> run</p>
   @copyright (c) 2019-2026 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
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
