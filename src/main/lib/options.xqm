xquery version "3.1";
(:
 : Copyright (c) 2019-2022 Quodatum Ltd
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
 : <h1>options.xqm</h1>
 : <p>converting XML config to maps.</p>
 :
 : @author Andy Bunce
 : @version 0.3
 :)
module namespace opts = 'quodatum:xqdoca:options';

(:~  convert xml  options to  a  map :)
declare function opts:as-map($a as element(*))
as map(*){
 $a/* ! map:entry(name(.), util:if (*,  opts:as-map(.),string(.)))
=>map:merge()
};

(: add defaults to opts :)
declare function opts:merge($opts as map(*),$defaults as map(*))
as map(*){
distinct-values ((map:keys($opts), map:keys($defaults)))
! map:entry(.,
      if(map:contains($opts,.) and map:contains($defaults,.))
      then if (map:get($opts,.) instance of map(*))
           then opts:merge(map:get($opts,.),map:get($defaults,.))
           else map:get($opts,.)
      else (map:get($opts,.),map:get($defaults,.))
)=>map:merge()
};