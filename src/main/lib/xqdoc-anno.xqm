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
 : <h1>xqdoc-proj.xqm</h1>
 : <p>annotation utils</p>
 :
 : @author Andy Bunce
 : @version 0.1
 :)
 

module namespace xqa = 'quodatum:xqdoca.model.annotations';


import module namespace xqn = 'quodatum:xqdoca.namespaces' at "xqdoc-namespace.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $xqa:nsRESTXQ:= 'http://exquery.org/ns/restxq';
declare variable $xqa:nsANN:='http://www.w3.org/2012/xquery';

declare function xqa:badges($annos as element(xqdoc:annotation)*, $ns as map(*))
{
 if( xqa:has-updating($annos,$ns)) then page:badge("U","danger") else (),
 if( xqa:has-rest($annos,$ns)) then  page:badge("R","success")  else ()  
};

declare function xqa:has-updating($annots  as element(xqdoc:annotation)*,$ns as map(*))
as xs:boolean
{
  some $a in $annots satisfies xqn:eq(xqn:qname-anno($a/@name,$ns), "http://www.w3.org/2012/xquery","updating")
};

declare function xqa:has-rest($annots  as element(xqdoc:annotation)*,$ns as map(*))
as xs:boolean
{
  some $a in $annots satisfies xqn:eq(xqn:qname-anno($a/@name,$ns), "http://exquery.org/ns/restxq","path")
};
