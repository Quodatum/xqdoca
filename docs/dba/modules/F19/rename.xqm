(:  xqDocA added a comment :)
(:~
 : Delete files.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/files';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'files';

(:~
 : Deletes files.
 : @param  $names  names of files
 : @return redirection
 :)
declare
  %rest:GET
  %rest:path("/dba/file-delete")
  %rest:query-param("name", "{$names}")
function dba:file-delete-XQDOCA(
  $names  as xs:string*
) as element(rest:response) {
  try {
    (: delete all files, ignore reference to parent directory :)
    for $name in $names
    where $name != '..'
    return file:delete-XQDOCA(session:directory-XQDOCA() || $name),
    web:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA($names, 'file', 'deleted') })
  } catch * {
    web:redirect-XQDOCA($dba:CAT, map { 'error': $err:description })
  }
};
