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
 : <h1>check-environment.xq</h1>
 : <p>Validate dependancies </p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
(:~
 : raise error if environment incorrect 
 :)
  let $ex-parse:="0.6.12"
  let $basex:="9.2.2"
  return 
  
  if( db:system()/generalinformation/version/tokenize(.," ")[1] ne $basex)then 
       error(xs:QName("xqd:version"),"BaseX version")
  else if(repo:list()[@name="http://expkg-zone58.github.io/ex-xparse"]/@version ne $ex-parse) then
       error(xs:QName("xqd:version"),"http://expkg-zone58.github.io/ex-xparse version")
  else
      "xqdoca dependancies are all installed."
      

