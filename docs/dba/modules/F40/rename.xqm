(:  xqDocA added a comment :)
(:~
 : Kill web sessions.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/sessions';

import module namespace Sessions = 'http://basex.org/modules/sessions';
import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'sessions';

(:~
 : Kills web sessions.
 : @param  $ids  session ids (including names)
 : @return redirection
 :)
declare
  %rest:GET
  %rest:path("/dba/session-kill")
  %rest:query-param("id", "{$ids}")
function dba:drop-XQDOCA(
  $ids  as xs:string*
) as element(rest:response) {
  try {
    for $id in $ids
    return Sessions:delete-XQDOCA(substring-before($id, '|'), substring-after($id, '|')),
    web:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA($ids, 'session', 'killed') })
  } catch * {
    web:redirect-XQDOCA($dba:CAT, map { 'error': $err:description })
  }
};
