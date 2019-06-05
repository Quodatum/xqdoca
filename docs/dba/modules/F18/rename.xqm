(:  xqDocA added a comment :)
(:~
 : Create directory.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/files';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'files';

(:~
 : Creates a directory.
 : @param  $name  name of directory to create
 : @return redirection
 :)
declare
  %rest:POST
  %rest:path("/dba/dir-create")
  %rest:query-param("name", "{$name}")
function dba:file-delete-XQDOCA(
  $name  as xs:string
) as element(rest:response) {
  file:create-dir-XQDOCA(session:directory-XQDOCA() || $name),
  web:redirect-XQDOCA($dba:CAT, map { 'info': 'Directory "' || $name || '" was created.' })
};
