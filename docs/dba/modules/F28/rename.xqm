(:  xqDocA added a comment :)
(:~
 : Delete log files.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/logs';

import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'logs';

(:~
 : Deletes database logs.
 : @param  $names  names of log files
 : @return redirection
 :)
declare
  %rest:GET
  %rest:path("/dba/log-delete")
  %rest:query-param("name", "{$names}")
function dba:drop-XQDOCA(
  $names  as xs:string*
) as element(rest:response) {
  try {
    $names ! admin:delete-logs-XQDOCA(.),
    web:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA($names, 'log', 'deleted') })
  } catch * {
    web:redirect-XQDOCA($dba:CAT, map { 'error': $err:description })
  }
};
