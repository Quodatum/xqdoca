(:  xqDocA added a comment :)
(:~
 : Open query.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/queries';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~
 : Returns the contents of a query file.
 : @param  $name  name of query file
 : @return query string
 :)
declare
  %rest:path("/dba/query-open")
  %rest:query-param("name", "{$name}")
  %output:method("text")
function dba:query-open-XQDOCA(
  $name  as xs:string
) as xs:string {
  session:set-XQDOCA($session:QUERY, $name),
  file:read-text-XQDOCA(session:directory-XQDOCA() || $name)
};
