(:  xqDocA added a comment :)
xquery version "3.1";
(:
 : Copyright (c) 2019 Quodatum Ltd
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
 : <h1>xqdoc-htmlmod.xqm</h1>
 : <p>Library to support html5 rendering of single xqdoc source</p>
 :
 : @author Andy Bunce
 : @version 0.1
 : @see https://github.com/Quodatum/xqdoca
 :)
 
(:~
 : Generate  html for xqdoc
 :)
module namespace _ = 'quodatum:xqdoca.generator.simple';



declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
declare
%xqdoca:module("xqdoc","xqDoc xml file from the source module")
%xqdoca:output("xqdoc.xml","xml") 
function _:xqdoc-XQDOCA($file as map(*), 
                 $model as map(*),
                 $opts as map(*)
                 )
{
  $file?xqdoc
};

declare
%xqdoca:module("xqparse","xqparse xml file from the source module")
%xqdoca:output("xqparse.xml","xml") 
function _:xqparse($file as map(*),
                   $model as map(*),
                   $opts as map(*)
                   )
{
  $file?xqparse
};