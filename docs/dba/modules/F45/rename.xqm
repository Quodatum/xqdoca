(:  xqDocA added a comment :)
(:~
 : Drop patterns.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/users';

import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:SUB := 'user';

(:~
 : Drops a pattern.
 : @param  $name      user name
 : @param  $patterns  database patterns
 : @return redirection
 :)
declare
  %updating
  %rest:GET
  %rest:path("/dba/pattern-drop")
  %rest:query-param("name",    "{$name}")
  %rest:query-param("pattern", "{$patterns}")
function dba:pattern-drop-XQDOCA(
  $name      as xs:string,
  $patterns  as xs:string*
) as empty-sequence() {
  try {
    $patterns ! user:drop-XQDOCA($name, .),
    util:redirect-XQDOCA($dba:SUB, map {
      'name': $name, 'info': util:info-XQDOCA($patterns, 'pattern', 'dropped') })
  } catch * {
    util:redirect-XQDOCA($dba:SUB, map { 'error': $err:description })
  }
};
