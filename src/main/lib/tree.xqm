xquery version "3.1";

 
(:~
<p>Convert sequence of paths as strings to an sequence of xml trees representing the paths.</p>
@Copyright (c) 2026 Quodatum Ltd
@author Andy Bunce, Quodatum, License: Apache-2.0
:)
module namespace tree = 'quodatum:data.tree';


(:~
 : convert path(s) to tree
 :)
declare function tree:build($paths as xs:string*)
as element(directory)?
{
 tree:build($paths,"/")
};

(:~
 : @return sequence of nested <directory name=".."> and <file name=".." elements representing source
 :)
declare function tree:build($paths as xs:string*,$delimiter as xs:string)
as element(*)*
{
fn:fold-right($paths,
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

(:~ extract any shared leading common path :)
declare function tree:base($tree as element(directory)?)
as xs:string{
  let $c:= $tree/directory
  let $ok:= count($c)=1 and count($tree/*)=1
  let $tail:= if ($ok) 
              then  tree:base($c) 
              else ()
  return ("",$tree/@name/string() ,$tail)=>string-join("/")
};

(: merger folder with just 1 folder child:)
declare function tree:flatten($tree as element(directory)?)
as element(directory)?{
if(exists($tree)) 
then 
      $tree transform with {
      for $d in  descendant::directory[ count(../*) gt 1 and not(@target)] (: no @target and more than 1 parent :)
      let $name:= $d/descendant-or-self::directory/@name=>string-join("/")
      return replace   node $d 
            with let $files:=$d//file
                  return if(count($files) gt 1)  
                        then  <directory name="{ $name}">{ $files} </directory>
                        else $files
      }
  else ()
};
