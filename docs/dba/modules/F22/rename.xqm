(:  xqDocA added a comment :)
(:~
 : Stop jobs.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/files';

import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'files';

(:~
 : Stops jobs.
 : @param  $ids  session ids
 : @return redirection
 :)
declare
  %rest:GET
  %rest:path("/dba/file-stop")
  %rest:query-param("id",  "{$id}")
function dba:file-stop-XQDOCA(
  $id  as xs:string
) as element(rest:response) {
  let $params := try {
    jobs:stop-XQDOCA($id),
    map { 'info': util:info-XQDOCA($id, 'job', 'stopped') }
  } catch * {
    map { 'error': $err:description }
  }
  return web:redirect-XQDOCA($dba:CAT, $params)
};
