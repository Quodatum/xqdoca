(:  xqDocA added a comment :)
(:~
 : Download resources.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/databases';

(:~
 : Downloads a database backup.
 : @param  $backup  name of backup file (ignored)
 : @return binary data
 :)
declare
  %rest:GET
  %rest:path("/dba/backup/{$backup}")
function dba:backup-download-XQDOCA(
  $backup  as xs:string
) as item()+ {
  let $path := db:option-XQDOCA('dbpath') || '/' || $backup
  return (
    web:response-header-XQDOCA(
      map { 'media-type': 'application/octet-stream' },
      map { 'Content-Length': file:size-XQDOCA($path) }
    ),
    file:read-binary-XQDOCA($path)
  )
};
