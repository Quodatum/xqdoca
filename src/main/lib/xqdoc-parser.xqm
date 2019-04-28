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
 : <h1>xqdoc-parser.xqm</h1>
 : <p>generate and Analyse XQuery parse tree</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace xqp = 'quodatum:build.parser';
import module namespace xp="expkg-zone58:text.parse";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ scan tree for function calls
 :)
declare function xqp:invoked($e as element(*))
as element(xqdoc:invoked)*
{
  $e//FunctionCall!xqp:funcall(.),
  $e//ArrowExpr!xqp:funcall(.) 
};

(:~  build invoked nodes for function call
 : @param $e is FunctionCall or ArrowExpr 
 :)
declare function xqp:funcall($e as element(*))
as element(xqdoc:invoked)
{
let $commas:=count($e/ArgumentList/TOKEN[.=","])
let $hasarg:=boolean($e/ArgumentList/*[not(TOKEN)])
let $arity:= (if($hasarg) then 1+$commas else 0)
let $arity:= if(name($e)="ArrowExpr") then $arity +1 else $arity 

let $n:=tokenize($e/QName,":")
let $ns:=if(count($n)=1)then () else $n[1]
let $n2:=if(count($n)=1)then  $n[1] else $n[2]

 return <xqdoc:invoked arity="{ $arity }">
         <xqdoc:uri>{ $ns }</xqdoc:uri>
         <xqdoc:name>{ $n2 }</xqdoc:name>
        </xqdoc:invoked>   
};

(:~ parse XQuery 
 : result is <XQuery> or <ERROR>
 :)
declare function xqp:parse($xq as xs:string)
as element(*)
{  
  xp:parse($xq || "",map{"lang":"xquery","version":"3.1 basex"}) 
};