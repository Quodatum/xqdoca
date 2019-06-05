(:  xqDocA added a comment :)
(:~
 : Rename resource.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/databases';

import module namespace html = 'dba/html' at '../../modules/html.xqm';
import module namespace util = 'dba/util' at '../../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'databases';
(:~ Sub category :)
declare variable $dba:SUB := 'database';

(:~
 : Form for renaming a resource.
 : @param  $name      database
 : @param  $resource  resource
 : @param  $target    target path
 : @param  $error     error string
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/db-rename")
  %rest:query-param("name",     "{$name}")
  %rest:query-param("resource", "{$resource}")
  %rest:query-param("target",   "{$target}")
  %rest:query-param("error",    "{$error}")
  %output:method("html")
function dba:db-rename-XQDOCA(
  $name      as xs:string,
  $resource  as xs:string,
  $target    as xs:string?,
  $error     as xs:string?
) as element(html) {
  html:wrap-XQDOCA(map { 'header': ($dba:CAT, $name), 'error': $error },
    <tr>
      <td>
        <form action="db-rename" method="post" autocomplete="off">
          <input type="hidden" name="name" value="{ $name }"/>
          <input type="hidden" name="resource" value="{ $resource }"/>
          <h2>{
            html:link-XQDOCA('Databases', $dba:CAT), ' » ',
            html:link-XQDOCA($name, $dba:SUB, map { 'name': $name }), ' » ',
            html:link-XQDOCA($resource, $dba:SUB, map { 'name': $name, 'resource': $resource }), ' » ',
            html:button-XQDOCA('db-rename', 'Rename')
          }</h2>
          <table>
            <tr>
              <td>New path:</td>
              <td>
                <input type="text" name="target" id="target"
                       value="{ head(($target, $resource)) }"/>
                { html:focus-XQDOCA('target') }
                <div class='small'/>
              </td>
            </tr>
          </table>
        </form>
      </td>
    </tr>
  )
};

(:~
 : Renames a database resource.
 : @param  $name      database
 : @param  $resource  resource
 : @param  $target    new name of resource
 : @return redirection
 :)
declare
  %updating
  %rest:POST
  %rest:path("/dba/db-rename")
  %rest:query-param("name",     "{$name}")
  %rest:query-param("resource", "{$resource}")
  %rest:query-param("target",   "{$target}")
function dba:db-rename(
  $name      as xs:string,
  $resource  as xs:string,
  $target    as xs:string
) as empty-sequence() {
  try {
    if(db:exists-XQDOCA($name, $target)) then (
      error((), 'Resource already exists.')
    ) else (
      db:rename-XQDOCA($name, $resource, $target),
      util:redirect-XQDOCA($dba:SUB, map {
        'name': $name, 'resource': $target, 'info': 'Resource was renamed.'
      })
    )
  } catch * {
    util:redirect-XQDOCA('db-rename', map {
      'name': $name, 'resource': $resource, 'target': $target, 'error': $err:description
    })
  }
};
