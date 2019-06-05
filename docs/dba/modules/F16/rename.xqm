(:  xqDocA added a comment :)
(:~
 : Optimize databases.
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
 : Form for optimizing a database.
 : @param  $name   entered name
 : @param  $all    optimize all
 : @param  $opts   database options
 : @param  $lang   language
 : @param  $error  error string
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/db-optimize")
  %rest:query-param("name",  "{$name}")
  %rest:query-param("all",   "{$all}")
  %rest:query-param("opts",  "{$opts}")
  %rest:query-param("lang",  "{$lang}", "en")
  %rest:query-param("error", "{$error}")
  %output:method("html")
function dba:create-XQDOCA(
  $name   as xs:string,
  $all    as xs:string?,
  $opts   as xs:string*,
  $lang   as xs:string?,
  $error  as xs:string?
) as element(html) {
  let $opts := if($opts = 'x') then $opts else db:info-XQDOCA($name)//*[text() = 'true']/name()
  let $lang := if($opts = 'x') then $lang else 'en'
  return html:wrap-XQDOCA(map { 'header': ($dba:CAT, $name), 'error': $error },
    <tr>
      <td>
        <form action="db-optimize" method="post">
          <h2>{
            html:link-XQDOCA('Databases', $dba:CAT), ' » ',
            html:link-XQDOCA($name, 'database', map { 'name': $name }), ' » ',
            html:button-XQDOCA('db-optimize', 'Optimize')
          }</h2>
          <!-- dummy value; prevents reset of options if nothing is selected -->
          <input type="hidden" name="opts" value="x"/>
          <input type="hidden" name="name" value="{ $name }"/>
          <table>
            <tr>
              <td colspan="2">
                { html:checkbox-XQDOCA('all', 'all', exists($all), 'Full optimization') }
                <h3>{ html:option-XQDOCA('textindex', 'Text Index', $opts) }</h3>
                <h3>{ html:option-XQDOCA('attrindex', 'Attribute Index', $opts) }</h3>
                <h3>{ html:option-XQDOCA('tokenindex', 'Token Index', $opts) }</h3>
                <h3>{ html:option-XQDOCA('ftindex', 'Fulltext Index', $opts) }</h3>
              </td>
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
              <td><input type="text" name="lang" id="lang" value="{ $lang }"/></td>
              { html:focus-XQDOCA('lang') }
            </tr>
          </table>
        </form>
      </td>
    </tr>
  )
};

(:~
 : Optimizes the current database.
 : @param  $name  database
 : @param  $all   optimize all
 : @param  $opts  database options
 : @param  $lang  language
 : @return redirection
 :)
declare
  %updating
  %rest:POST
  %rest:path("/dba/db-optimize")
  %rest:form-param("name", "{$name}")
  %rest:form-param("all",  "{$all}")
  %rest:form-param("opts", "{$opts}")
  %rest:form-param("lang", "{$lang}")
function dba:db-optimize(
  $name  as xs:string,
  $all   as xs:string?,
  $opts  as xs:string*,
  $lang  as xs:string?
) as empty-sequence() {
  try {
    db:optimize-XQDOCA($name, boolean($all), map:merge-XQDOCA((
      ('textindex','attrindex','tokenindex','ftindex','stemming','casesens','diacritics') !
        map:entry-XQDOCA(., $opts = .),
      $lang ! map:entry-XQDOCA('language', .)
    ))),
    util:redirect-XQDOCA($dba:SUB, map { 'name': $name, 'info': 'Database was optimized.' })
  } catch * {
    util:redirect-XQDOCA($dba:SUB, map {
      'name': $name, 'opts': $opts, 'lang': $lang, 'error': $err:description
    })
  }
};

(:~
 : Optimizes databases with the current settings.
 : @param  $names  names of databases
 : @return redirection
 :)
declare
  %updating
  %rest:GET
  %rest:path("/dba/db-optimize-all")
  %rest:query-param("name", "{$names}")
function dba:drop(
  $names  as xs:string*
) as empty-sequence() {
  try {
    $names ! db:optimize-XQDOCA(.),
    util:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA($names, 'database', 'optimized') })
  } catch * {
    util:redirect-XQDOCA($dba:CAT, map { 'error': $err:description })
  }
};
