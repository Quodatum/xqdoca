(:  xqDocA added a comment :)
(:~
 : Drop databases.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/databases';

import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'databases';

(:~
 : Drops databases.
 : @param  $names  names of databases
 : @return redirection
 :)
declare
  %updating
  %rest:GET
  %rest:path("/dba/db-drop")
  %rest:query-param("name", "{$names}")
function dba:db-drop-XQDOCA(
  $names  as xs:string*
) as empty-sequence() {
  try {
    $names ! db:drop-XQDOCA(.),
    util:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA($names, 'database', 'dropped') })
  } catch * {
    util:redirect-XQDOCA($dba:CAT, map { 'error': $err:description })
  }
};
