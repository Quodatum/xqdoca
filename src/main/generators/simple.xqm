xquery version "3.1";
(:~
 : <p>Render to o/p xqdoc and xqparse XML files</p>
 : @copyright (c) 2019-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.simple';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";

declare
%xqdoca:module("xqdoc","xqDoc xml file from the source module")
%xqdoca:output("xqdoc.xml","xml") 
function _:xqdoc($file as map(*), 
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