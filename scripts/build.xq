(:~ create dist zip 
:)
declare variable $PKG:= doc("../src/main/expath-pkg.xml")/*;
declare function local:absolute($path as xs:string){
 file:resolve-path($path,file:base-dir())
};
declare function local:list($path){
   let $absolute:=local:absolute($path)=>trace("ab")
   return file:list($absolute, true())
   [not(ends-with(.,file:dir-separator()))]
   [not(contains(.,"/dist/"))]
  [not(contains(.,".git/"))]
};

let $files:=local:list("../")
let $zip  := archive:create($files,
                            $files
                            !local:absolute(.)
                            !file:read-binary(.)
                            )
let $dest:= ``[../dist/`{ $PKG/@abbrev }`-`{ $PKG/@version }`.zip]`` 
            =>local:absolute()
return $dest!local:absolute(.)=> file:write-binary($zip) 