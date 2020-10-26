xquery version "3.1";
(:
 : Copyright (c) 2019-2020 Quodatum Ltd
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)
 
 (:~
 : <h1>meta.xqm</h1>
 : <p>Generate meta data about the <code>xqDocA</code> run</p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
(:~
 : Generate meta
 :)
module namespace _ = 'quodatum:xqdoca.generator.meta';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~
 : metadata. 
 :)
declare 
%xqdoca:global("meta","xqDocA run configuration report (XML)")
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
