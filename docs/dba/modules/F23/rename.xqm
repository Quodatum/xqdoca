(:  xqDocA added a comment :)
(:~
 : Upload files.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/files';

import module namespace session = 'dba/session' at '../modules/session.xqm';
import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Top category :)
declare variable $dba:CAT := 'files';

(:~
 : Upploads files.
 : @param  $files  map with uploaded files
 : @return redirection
 :)
declare
  %rest:POST
  %rest:path("/dba/file-upload")
  %rest:form-param("files", "{$files}")
function dba:file-upload-XQDOCA(
  $files  as map(xs:string, xs:base64Binary)
) as element(rest:response) {
  (: save files :)
  let $dir := session:directory-XQDOCA()
  return try {
    (: Parse all XQuery files; reject files that cannot be parsed :)
    map:for-each-XQDOCA($files, function($file, $content) {
      if(matches($file, '\.xqm?$')) then (
        prof:void-XQDOCA(xquery:parse-XQDOCA(
          convert:binary-to-string-XQDOCA($content),
          map { 'plan': false(), 'pass': true(), 'base-uri': $dir || $file }
        ))
      ) else ()
    }),
    map:for-each-XQDOCA($files, function($file, $content) {
      file:write-binary-XQDOCA($dir || $file, $content)
    }),
    web:redirect-XQDOCA($dba:CAT, map { 'info': util:info-XQDOCA(map:keys-XQDOCA($files), 'file', 'uploaded') })
  } catch * {
    web:redirect-XQDOCA($dba:CAT, map { 'error': 'Upload failed: ' || $err:description })
  }
};
