(:  xqDocA added a comment :)
(:~
 : Drop users.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/users';

import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'users';

(:~
 : Drops users.
 : @param  $names  names of users
 : @return redirection
 :)
declare
  %updating
  %rest:GET
  %rest:path("/dba/user-drop")
  %rest:query-param("name", "{$names}")
function dba:user-drop-XQDOCA(
  $names  as xs:string*
) as empty-sequence() {
  try {
    $names ! user:drop-XQDOCA(.),
    util:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA($names, 'user', 'dropped') })
  } catch * {
    util:redirect-XQDOCA($dba:CAT, map { 'error': $err:description })
  }
};
