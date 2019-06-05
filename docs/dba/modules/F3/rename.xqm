(:  xqDocA added a comment :)
(:~
 : Delete resources.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/databases';

import module namespace util = 'dba/util' at '../../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Sub category :)
declare variable $dba:SUB := 'database';

(:~
 : Deletes resources.
 : @param  $names     database
 : @param  $resource  resources
 : @return redirection
 :)
declare
  %updating
  %rest:GET
  %rest:path("/dba/db-delete")
  %rest:query-param("name",     "{$name}")
  %rest:query-param("resource", "{$resources}")
function dba:db-delete-XQDOCA(
  $name       as xs:string,
  $resources  as xs:string*
) as empty-sequence() {
  try {
    $resources ! db:delete-XQDOCA($name, .),
    util:redirect-XQDOCA($dba:SUB,
      map { 'name': $name, 'info': util:info-XQDOCA($resources, 'resource', 'deleted') }
    )
  } catch * {
    util:redirect-XQDOCA($dba:SUB, map { 'name': $name, 'error': $err:description })
  }
};
