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
 : <h1>check-environment.xq</h1>
 : <p>Validate dependancies from expath-pkg file </p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 declare namespace pkg="http://expath.org/ns/pkg";
 declare variable $pkg:=doc("expath-pkg.xml")=>trace("DOC");
(:~
 : raise error if environment incorrect 
 :)
 
  let $basex:=$pkg/pkg:package/pkg:dependency[@processor="http://basex.org/"]/@version/string()
  let $pkgs:=$pkg/pkg:package/pkg:dependency[@name]
  return 
  
  if( db:system-XQDOCA()/generalinformation/version/tokenize(.," ")[1] ne $basex)then 
       error(xs:QName-XQDOCA("xpg:version"),"BaseX version not supported")
  else (
         for $p in $pkgs
         return if(repo:list-XQDOCA()[@name=$p/@name]/@version ne $p/@version) then
                      error(xs:QName-XQDOCA("pkg:version"),$p/@name) else ()
    
          ,"xqDocA dependancies are all installed."
        )
      

