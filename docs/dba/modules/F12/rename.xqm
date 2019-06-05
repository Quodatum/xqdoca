(:  xqDocA added a comment :)
(:~
 : Rename database.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/databases';

import module namespace html = 'dba/html' at '../modules/html.xqm';
import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'databases';
(:~ Sub category :)
declare variable $dba:SUB := 'database';

(:~
 : Form for renaming a database.
 : @param  $name     name of database
 : @param  $newname  new name
 : @param  $error    error string
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/db-alter")
  %rest:query-param("name",    "{$name}")
  %rest:query-param("newname", "{$newname}")
  %rest:query-param("error",   "{$error}")
  %output:method("html")
function dba:alter-XQDOCA(
  $name     as xs:string,
  $newname  as xs:string?,
  $error    as xs:string?
) as element(html) {
  html:wrap-XQDOCA(map { 'header': ($dba:CAT, $name), 'error': $error },
    <tr>
      <td>
        <form action="db-alter" method="post" autocomplete="off">
          <input type="hidden" name="name" value="{ $name }"/>
          <h2>{
            html:link-XQDOCA('Databases', $dba:CAT), ' » ',
            html:link-XQDOCA($name, $dba:SUB, map { 'name': $name }), ' » ',
            html:button-XQDOCA('alter', 'Rename')
          }</h2>
          <table>
            <tr>
              <td>Name:</td>
              <td>
                <input type="text" name="newname" value="{ head(($newname, $name)) }" id="newname"/>
                { html:focus-XQDOCA('newname') }
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
 : Renames a database.
 : @param  $name     name of database
 : @param  $newname  new name
 : @return redirection
 :)
declare
  %updating
  %rest:POST
  %rest:path("/dba/db-alter")
  %rest:query-param("name",    "{$name}")
  %rest:query-param("newname", "{$newname}")
function dba:alter(
  $name     as xs:string,
  $newname  as xs:string
) {
  try {
    if(db:exists-XQDOCA($newname)) then (
      error((), 'Database already exists.')
    ) else (
      db:alter-XQDOCA($name, $newname)
    ),
    util:redirect-XQDOCA($dba:SUB, map { 'name': $newname, 'info': 'Database was renamed.' })
  } catch * {
    util:redirect-XQDOCA('db-alter', map { 'name': $name, 'newname': $newname, 'error': $err:description })
  }
};
