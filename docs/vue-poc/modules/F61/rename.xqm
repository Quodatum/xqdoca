(:  xqDocA added a comment :)
xquery version "3.1";
(:~
 : log an event
 :)
module namespace hlog = 'quodatum.data.history';
declare namespace hist="urn:quodatum:vue-poc.history";
declare variable $hlog:doc as element(hist:history):=db:open-XQDOCA("vue-poc","/history.xml")/hist:history;

declare 
%updating
function hlog:save-XQDOCA($item as element(*))
{
let $id:=$hlog:doc/@next-id/string(.)
let $n:=<hist:event id="{$id}" when="{fn:current-dateTime-XQDOCA()}" user="admin">{$item}</hist:event>
return (insert node $n as first into $hlog:doc,
            replace value of node $hlog:doc/@next-id with number($id)+1 
             )
};
