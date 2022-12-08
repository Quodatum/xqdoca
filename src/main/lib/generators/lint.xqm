xquery version "3.1";
(:~
 : <p>XQuery Lint report</p>
 : @Copyright (c) 2022-2022 Quodatum Ltd
 : @author Andy Bunce, Quodatum, License: Apache-2.0
 :)

module namespace _ = 'quodatum:xqdoca.generator.ilintmports';

import module namespace xqd = 'quodatum:xqdoca.model' at "../model.xqm";
import module namespace page = 'quodatum:xqdoca.page'  at "../xqdoc-page.xqm";
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace xqdoca="https://github.com/Quodatum/xqdoca";


(:~ import page :)
declare 
%xqdoca:global("lint","Summary of issues")
%xqdoca:output("lint.html","html5") 
function _:lint($model,$opts)
{
let $body:=<div>TODO</div>
return page:wrap($body,$opts)
};