xquery version "3.1";
(:~
 : rewrite code  
 :
 : @author Andy Bunce
 : @version 0.2
 :)
 
module namespace _ = 'quodatum:xqdoca.generator.rename';
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";
(:~ 
 : code rewritting
 :)
declare 
%xqdoca:module("refactor","simple code change examples.")
%xqdoca:output("rename.xqm","text") 
function _:rename($file as map(*), 
                  $model as map(*),
                  $opts as map(*)
                  )                    
{


  let $parse:=$file?xqparse 
  
  (: change function names that are called :)
  let $parse := $parse transform with {
    .//FunctionCall/QName
    !.[contains(.,":")]
    !( replace value of node . with . || "-XQDOCA")
  }
  (: add an import :)
    let $i:=``[;
import module namespace xqd = 'quodatum:xqdoca.model' at '../../lib/model.xqm']``
   let $parse := $parse transform with {
    .//ModuleImport[not(following-sibling::ModuleImport)]!(insert node <ModuleImport>{$i}</ModuleImport> after .)
  }
  (: change name of function :)
   let $parse := $parse transform with {
    (.//FunctionDecl)[1]!(replace value of node QName[1] with concat(QName[1],"-XQDOCA"))
  }
  let $result:=``[(:  xqDocA added a comment :)
]`` || $parse
  return $result
  };
