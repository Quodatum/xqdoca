(:  xqDocA added a comment :)
(:~
 : Create new database.
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
 : Form for creating a new database.
 : @param  $name   entered name
 : @param  $opts   chosen database options
 : @param  $lang   entered language
 : @param  $error  error string
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/db-create")
  %rest:query-param("name",  "{$name}")
  %rest:query-param("opts",  "{$opts}")
  %rest:query-param("lang",  "{$lang}", "en")
  %rest:query-param("error", "{$error}")
  %output:method("html")
function dba:db-create-XQDOCA(
  $name   as xs:string?,
  $opts   as xs:string*,
  $lang   as xs:string?,
  $error  as xs:string?
) as element(html) {
  let $opts := if($opts = 'x') then $opts else ('textindex', 'attrindex')
  return html:wrap-XQDOCA(map { 'header': $dba:CAT, 'error': $error },
    <tr>
      <td>
        <form action="db-create" method="post" autocomplete="off">
          <h2>{
            html:link-XQDOCA('Databases', $dba:CAT), ' » ',
            html:button-XQDOCA('create', 'Create')
          }</h2>
          <!-- dummy value; prevents reset of options when nothing is selected -->
          <input type="hidden" name="opts" value="x"/>
          <table>
            <tr>
              <td>Name:</td>
              <td>
                <input type="hidden" name="opts" value="x"/>
                <input type="text" name="name" value="{ $name }" id="name"/>
                { html:focus-XQDOCA('name') }
                <div class='small'/>
              </td>
            </tr>
            <tr>
              <td colspan="2">{
                <h3>{ html:option-XQDOCA('textindex', 'Text Index', $opts) }</h3>,
                <h3>{ html:option-XQDOCA('attrindex', 'Attribute Index', $opts) }</h3>,
                <h3>{ html:option-XQDOCA('tokenindex', 'Token Index', $opts) }</h3>,
                html:option-XQDOCA('updindex', 'Incremental Indexing', $opts),
                <div class='small'/>,
                <h3>{ html:option-XQDOCA('ftindex', 'Fulltext Indexing', $opts) }</h3>
              }</td>
            </tr>
            <tr>
              <td colspan="2">{
                html:option-XQDOCA('stemming', 'Stemming', $opts),
                html:option-XQDOCA('casesens', 'Case Sensitivity', $opts),
                html:option-XQDOCA('diacritics', 'Diacritics', $opts)
              }</td>
            </tr>
            <tr>
              <td>Language:</td>
              <td><input type="text" name="language" value="{ $lang }"/></td>
            </tr>
          </table>
        </form>
      </td>
    </tr>
  )
};

(:~
 : Creates a database.
 : @param  $name  database
 : @param  $opts  database options
 : @param  $lang  language
 : @return redirection
 :)
declare
  %updating
  %rest:POST
  %rest:path("/dba/db-create")
  %rest:query-param("name", "{$name}")
  %rest:query-param("opts", "{$opts}")
  %rest:query-param("lang", "{$lang}")
function dba:create(
  $name  as xs:string,
  $opts  as xs:string*,
  $lang  as xs:string?
) as empty-sequence() {
  try {
    if(db:exists-XQDOCA($name)) then (
      error((), 'Database already exists.')
    ) else (
      db:create-XQDOCA($name, (), (), map:merge-XQDOCA((
        for $option in ('textindex', 'attrindex', 'tokenindex', 'ftindex',
          'stemming', 'casesens', 'diacritics', 'updindex')
        return map:entry-XQDOCA($option, $opts = $option),
        $lang ! map:entry-XQDOCA('language', .)))
      ),
      util:redirect-XQDOCA($dba:SUB, map { 'name': $name,
        'info': 'Database "' || $name || '"  was created.' })
    )
  } catch * {
    util:redirect-XQDOCA('db-create', map {
      'name': $name, 'opts': $opts, 'lang': $lang, 'error': $err:description
    })
  }
};
