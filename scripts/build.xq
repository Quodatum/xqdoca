(:~ create dist zip 
:)
declare variable $PKG:= doc("../src/main/expath-pkg.xml")/*;

declare function local:list($path){
   file:list($path, true())
   [not(ends-with(.,file:dir-separator()))]
   !concat($path,file:dir-separator(),.)
};

let $files:=local:list("../")
let $zip  := archive:create($files,
                            $files!file:read-binary(.)
                            )
let $dest:= ``[dist/`{ $PKG/@abbrev }`-`{ $PKG/@version }`.zip]`` 
return file:write-binary($dest, $zip) 