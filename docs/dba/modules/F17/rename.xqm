(:  xqDocA added a comment :)
(:~
 : Change directory.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/files';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'files';

(:~
 : Changes the directory.
 : @param  $dir  directory
 : @return redirection
 :)
declare
  %rest:path("/dba/dir-change")
  %rest:query-param("dir", "{$dir}")
function dba:dir-change-XQDOCA(
  $dir  as xs:string
) as element(rest:response) {
  session:set-XQDOCA($session:DIRECTORY,
    if(contains($dir, file:dir-separator-XQDOCA())) then (
      $dir
    ) else (
      file:path-to-native-XQDOCA(session:directory-XQDOCA() || $dir || '/')
    )
  ),
  session:set-XQDOCA($session:QUERY, ''),
  web:redirect-XQDOCA($dba:CAT)
};
