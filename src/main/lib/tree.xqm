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
 : <h1>tree.xqm</h1>
 : <p>convert sequence of paths to sequence of xml trees </p>
 :
 : @author Andy Bunce
 : @version 0.2
 :)
module namespace tree = 'quodatum:data.tree';


(:~
 : convert path(s) to tree
 :)
declare function tree:build($a as xs:string*)
as element(directory)?
{
 tree:build($a,"/")
};

(:~
 : @return sequence of nested <directory name=".."> and <file name=".." elements representing source
 :)
declare function tree:build($a as xs:string*,$delimiter as xs:string)
as element(*)*
{
fn:fold-right($a,
             (),
             function($this,$acc){ tree:merge($acc,tree:nest($this,$delimiter)) }
            )
}; 
(:~  convert a path to xml :)
declare %private 
function tree:nest($path as xs:string,$delimiter as xs:string)
as element(*)
{
  let $path:=if(starts-with($path,$delimiter)) then $path else $delimiter || $path
  let $parts:=fn:tokenize(($path),$delimiter)
  return fn:fold-right(subsequence($parts,1,count($parts)-1),
    <file name="{$parts[last()]}" target="{$path}"/>,
    tree:wrap#2 
   )
};

declare %private 
function tree:wrap($this as xs:string,$acc)
as element(*)
{
  <directory name="{$this}">{$acc}</directory>
};


declare %private
function tree:merge($a1 as element(*)?,$a2 as element(*)?)
as element(*)*
{
 if($a1/@name=$a2/@name) then
      let $n1:=$a1/*
      let $n2:=$a2/*
         
      let $t:=(
        for $x in fn:distinct-values($n1/@name[.=$n2/@name]) (:both:)
        return tree:merge($a1/*[@name=$x],$a2/*[@name=$x]),
        
        for $x in fn:distinct-values($n1/@name[fn:not(.=$n2/@name)]) (:only $a1 :)
        return $a1/*[@name=$x],
        
        for $x in fn:distinct-values($n2/@name[fn:not(.=$n1/@name)]) (:only $a2 :)
        return $a2/*[@name=$x]
      )
      let $name:=$a1/@name
      let $target:=($a1/@target,$a2/@target)[1]
      return <directory >{
        $name,$target,
        for $x in $t order by $x/@name return $x
      }</directory>
 else 
     ($a1,$a2)                        
};

(:~ extract any shared common path :)
declare function tree:base($tree)
as xs:string{
  let $c:= $tree/directory
  let $ok:= count($c)=1 and count($tree/*)=1
  let $tail:= if ($ok) then  tree:base($c) else ()
  return ($tree/@name/string() ,$tail)=>string-join("/")
};