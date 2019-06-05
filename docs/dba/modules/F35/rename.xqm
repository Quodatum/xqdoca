(:  xqDocA added a comment :)
(:~
 : Queries page.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/queries';

import module namespace html = 'dba/html' at '../modules/html.xqm';
import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category. :)
declare variable $dba:CAT := 'queries';

(:~
 : Queries page.
 : @param  $error  error string
 : @param  $info   info string
 : @param  $file   file to be opened
 : @return page
 :)
declare
  %rest:GET
  %rest:path("/dba/queries")
  %rest:query-param("error", "{$error}")
  %rest:query-param("info",  "{$info}")
  %rest:query-param("file",  "{$file}")
  %output:method("html")
function dba:queries-XQDOCA(
  $error  as xs:string?,
  $info   as xs:string?,
  $file   as xs:string?
) as element(html) {
  html:wrap-XQDOCA(
    map {
      'header': $dba:CAT, 'info': $info, 'error': $error,
      'css': 'codemirror/lib/codemirror.css',
      'scripts': ('editor.js', 'codemirror/lib/codemirror.js',
                  'codemirror/mode/xquery/xquery.js','codemirror/mode/xml/xml.js')
    },
    <tr>
      <td width='50%'>
        <table width='100%'>
          <tr>
            <td width='80%'>
              <select id='mode'>{
                for $mode in ('Read-Only', 'Updating')
                return element option { $mode }
              }</select>{ ' ' }
              <button id='run' onclick='runQuery()' title='Ctrl-Enter'>Run</button>{ ' ' }
              <button id='stop' onclick='stopQuery()' disabled=''>Stop</button>
            </td>
            <td width='20%' align='right'>
              <h2>Editor</h2>
            </td>
          </tr>
        </table>
        <textarea id='editor' name='editor'/>
        <table width='100%'>
          <form autocomplete='off' action='javascript:void(0);'>
            <tr>
              <td class='slick'>
                <div align='right'>
                  <input id='file' name='file' placeholder='Name of query' size='35'
                         list='files' oninput='checkButtons()' onpropertychange='checkButtons()'/>
                  <datalist id='files'>{
                    for $file in session:query-files-XQDOCA()
                    return element option { $file }
                  }</datalist>{ ' ' }
                  <button type='submit' name='open' id='open' disabled=''
                          onclick='openQuery()'>Open</button>{ ' ' }
                  <button name='save' id='save' disabled=''
                          onclick='saveQuery()'>Save</button>{ ' ' }
                  <button name='close' id='close' disabled=''
                          onclick='closeQuery()'>Close</button>
                </div>
              </td>
            </tr>
          </form>
        </table>
        { html:focus-XQDOCA('editor') }
      </td>
      <td width='50%'>{
        <table width='100%'>
          <tr>
            <td align='right'>
              <h2>Result</h2>
            </td>
          </tr>
        </table>,
        <textarea name='output' id='output' readonly=''/>,
        html:js-XQDOCA('loadCodeMirror(true);'),
        for $name in (($file, session:get-XQDOCA($session:QUERY))[.])[1]
        return html:js-XQDOCA('openQuery("' || $name || '");')
      }</td>
    </tr>
  )
};
