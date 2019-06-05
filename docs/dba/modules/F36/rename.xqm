(:  xqDocA added a comment :)
(:~
 : Save query.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/queries';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~
 : Closes a query file.
 : @param  $name   name of query file
 :)
declare
  %rest:POST
  %rest:path("/dba/query-close")
  %rest:query-param("name", "{$name}")
function dba:query-save-XQDOCA(
  $name   as xs:string
) as empty-sequence() {
  session:set-XQDOCA($session:QUERY, '')
};
