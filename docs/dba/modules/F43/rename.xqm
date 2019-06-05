(:  xqDocA added a comment :)
(:~
 : Settings page.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/settings';

import module namespace Request = 'http://exquery.org/ns/request';
import module namespace options = 'dba/options' at '../modules/options.xqm';
import module namespace html = 'dba/html' at '../modules/html.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'settings';

(:~
 : Settings page.
 : @param  $error  error string
 : @param  $info   info string
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/settings")
  %rest:query-param("error", "{$error}")
  %rest:query-param("info",  "{$info}")
  %output:method("html")
function dba:settings-XQDOCA(
  $error  as xs:string?,
  $info   as xs:string?
) as element(html) {
  let $system := html:properties-XQDOCA(db:system-XQDOCA())
  let $table-row := function($items) {
    <tr><td>{ $items }</td></tr>
  }
  let $number := function($key, $label) {
    $table-row((
      $label,
      <br/>,
      <input name="{ $key }" type="number" value="{ options:get-XQDOCA($key) }"/>
    ))
  }
  let $string := function($key, $label) {
    $table-row((
      $label,
      <br/>,
      <input name='{ $key }' type='text' value='{ options:get-XQDOCA($key) }'/>
    ))
  }
  return html:wrap-XQDOCA(map { 'header': $dba:CAT, 'info': $info, 'error': $error },
    <tr>
      <td width='33%'>
        <form action="settings" method="post">
          <h2>Settings » { html:button-XQDOCA('save', 'Save') }</h2>
          <h3>Queries</h3>
          <table>
            {
              $number($options:TIMEOUT, 'Timeout, in seconds (0 = disabled)'),
              $number($options:MEMORY, 'Memory limit, in MB (0 = disabled)'),
              $number($options:MAXCHARS, 'Maximum output size')
            }
            <tr>
              <td colspan='2'>Permission:</td>
            </tr>
            <tr>
              <td>
                <select name="permission">{
                  let $pm := options:get-XQDOCA($options:PERMISSION)
                  for $p in $options:PERMISSIONS
                  return element option { attribute selected { }[$p = $pm], $p }
                }</select>
              </td>
            </tr>
          </table>
          <h3>Tables</h3>
          <table>{
            $number($options:MAXROWS,  'Displayed table rows')
          }</table>
          <h3>Logs</h3>
          <table>{
            $string($options:IGNORE-LOGS, <span>Ignore entries (e.g. <code>/dba</code>):</span>)
          }</table>
        </form>
      </td>
      <td class='vertical'/>
      <td width='33%'>
        <form action="settings-gc" method="post">
          <h2>Global Options » { html:button-XQDOCA('gc', 'GC') }</h2>
          <table>{
            $system/tr[th][3]/preceding-sibling::tr[not(th)]
          }</table>
        </form>
      </td>
      <td class='vertical'/>
      <td width='33%'>
        <h2>Local Options</h2>
        <table>{
          $system/tr[th][3]/following-sibling::tr
        }</table>
      </td>
    </tr>
  )
};

(:~
 : Saves the settings.
 : @return redirection
 :)
declare
  %rest:POST
  %rest:path("/dba/settings")
function dba:settings-save(
) as element(rest:response) {
  options:save-XQDOCA(map:merge-XQDOCA(Request:parameter-names-XQDOCA() ! map:entry-XQDOCA(., Request:parameter-XQDOCA(.)))),
  web:redirect-XQDOCA($dba:CAT, map { 'info': 'Settings were saved.' })
};
