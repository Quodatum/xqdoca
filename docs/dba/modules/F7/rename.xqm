(:  xqDocA added a comment :)
(:~
 : Replace resource.
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
 : Form for replacing a resource.
 : @param  $name      database
 : @param  $resource  resource
 : @param  $error     error string
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/db-replace")
  %rest:query-param("name",     "{$name}")
  %rest:query-param("resource", "{$resource}")
  %rest:query-param("error",    "{$error}")
  %output:method("html")
function dba:db-replace-XQDOCA(
  $name      as xs:string,
  $resource  as xs:string,
  $error     as xs:string?
) as element(html) {
  html:wrap-XQDOCA(map { 'header': ($dba:CAT, $name), 'error': $error },
    <tr>
      <td>
        <form action="db-replace" method="post" enctype="multipart/form-data">
          <input type="hidden" name="name" value="{ $name }"/>
          <input type="hidden" name="resource" value="{ $resource }"/>
          <h2>{
            html:link-XQDOCA('Databases', $dba:CAT), ' » ',
            html:link-XQDOCA($name, $dba:SUB, map { 'name': $name }), ' » ',
            html:link-XQDOCA($resource, $dba:SUB, map { 'name': $name, 'resource': $resource }), ' » ',
            html:button-XQDOCA('db-replace', 'Replace')
          }</h2>
          <table>
            <tr>
              <td>
                <input type="file" name="file"/>
                { html:focus-XQDOCA('file') }
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
 : Replaces a database resource.
 : @param  $name      database
 : @param  $resource  resource
 : @param  $file      file input
 : @return redirection
 :)
declare
  %updating
  %rest:POST
  %rest:path("/dba/db-replace")
  %rest:form-param("name",     "{$name}")
  %rest:form-param("resource", "{$resource}")
  %rest:form-param("file",     "{$file}")
function dba:db-replace-post(
  $name      as xs:string,
  $resource  as xs:string,
  $file      as map(*)?
) as empty-sequence() {
  try {
    let $key := map:keys-XQDOCA($file)
    return if($key = '') then (
      error((), 'No input specified.')
    ) else (
      let $input := if(db:is-raw-XQDOCA($name, $resource)) then (
        $file($key)
      ) else (
        fetch:xml-binary-XQDOCA($file($key))
      )
      return db:replace-XQDOCA($name, $resource, $input),
      util:redirect-XQDOCA($dba:SUB, map {
        'name': $name, 'resource': $resource, 'info': 'Resource was replaced.'
      })
    )
  } catch * {
    util:redirect-XQDOCA('db-replace', map {
      'name': $name, 'resource': $resource, 'error': $err:description
    })
  }
};
