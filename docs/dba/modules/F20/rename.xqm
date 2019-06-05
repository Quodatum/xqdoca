(:  xqDocA added a comment :)
(:~
 : Download file.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/files';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~
 : Downloads a file.
 : @param  $name  name of file
 : @return binary data
 :)
declare
  %rest:GET
  %rest:path("/dba/file/{$name}")
function dba:files-XQDOCA(
  $name  as xs:string
) as item()+ {
  let $path := session:directory-XQDOCA() || $name
  return (
    web:response-header-XQDOCA(
      map { 'media-type': 'application/octet-stream' },
      map { 'Content-Length': file:size-XQDOCA($path) }
    ),
    file:read-binary-XQDOCA($path)
  )
};
