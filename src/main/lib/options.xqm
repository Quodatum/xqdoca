xquery version "3.1";
(:~
 <p>converting XML config to maps.</p>
 @Copyright (c) 2026 Quodatum Ltd
 @author Andy Bunce, Quodatum, License: Apache-2.0
 :)
module namespace opts = 'quodatum:xqdoca:options';

(:~  convert xml  options to  a  map :)
declare function opts:as-map($a as element(*))
as map(*){
 $a/* ! map:entry(name(.), if (*) 
                           then opts:as-map(.) 
                           else if(.=("true","false")) then xs:boolean(.) else string(.))
=>map:merge()
(: =>trace("AS_MAP: ") :)
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