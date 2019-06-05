(:  xqDocA added a comment :)
(:~
 : Download resources.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/databases';

(:~
 : Downloads a resource.
 : @param  $name      database
 : @param  $resource  resource
 : @param  $file      file name (ignored)
 : @return rest response and file content
 :)
declare
  %rest:path("/dba/db-download")
  %rest:query-param("name",     "{$name}")
  %rest:query-param("resource", "{$resource}")
function dba:db-download-XQDOCA(
  $name      as xs:string,
  $resource  as xs:string
) as item()+ {
  try {
    web:response-header-XQDOCA(
      map { 'media-type': db:content-type-XQDOCA($name, $resource) },
      map { 'Content-Disposition': 'attachment; filename=' || $resource }
    ),
    if(db:is-raw-XQDOCA($name, $resource)) then (
      db:retrieve-XQDOCA($name, $resource)
    ) else (
      db:open-XQDOCA($name, $resource)
    )
  } catch * {
    <rest:response>
      <http:response status="400" message="{ $err:description }"/>
    </rest:response>
  }
};
