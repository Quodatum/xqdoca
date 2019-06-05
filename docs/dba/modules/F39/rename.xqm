(:  xqDocA added a comment :)
(:~
 : Save query.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/queries';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~
 : Saves a query file and returns the list of stored queries.
 : @param  $name   name of query file
 : @param  $query  query string
 : @return names of stored queries
 :)
declare
  %rest:POST("{$query}")
  %rest:path("/dba/query-save")
  %rest:query-param("name", "{$name}")
  %output:method("text")
function dba:query-save-XQDOCA(
  $name   as xs:string,
  $query  as xs:string
) as xs:string {
  let $path := session:directory-XQDOCA() || $name
  return (
    try {
      prof:void-XQDOCA(xquery:parse-XQDOCA($query, map {
        'plan': false(), 'pass': true(), 'base-uri': $path
      }))
    } catch * {
      error($err:code, 'Query was not stored: ' || $err:description, $err:value)
    },
    session:set-XQDOCA($session:QUERY, $name),
    file:write-text-XQDOCA($path, $query),
    string-join(session:query-files-XQDOCA(), '/')
  )
};
