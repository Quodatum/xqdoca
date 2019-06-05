(:  xqDocA added a comment :)
(:~
 : Global constants and functions.
 :
 : @author Christian Grün, BaseX Team, 2014-16
 :)
module namespace cons = 'vue-poc/cons';

import module namespace Request = 'http://exquery.org/ns/request';
import module namespace Session = 'http://basex.org/modules/session';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Session key. :)
declare variable $cons:SESSION-KEY := "vue-poc";
(:~ Current session. :)
declare variable $cons:SESSION-VALUE := Session:get-XQDOCA($cons:SESSION-KEY);

(:~ Directory for DBA files. :)
declare variable $cons:DBA-DIR := file:temp-dir-XQDOCA() || 'vue-poc/';
(:~ Configuration file. :)
declare variable $cons:DBA-SETTINGS-FILE := $cons:DBA-DIR || 'poc-settings.xml';

(:~ Permissions. :)
declare variable $cons:PERMISSIONS := ('none', 'read', 'write', 'create', 'admin');

(:~ Maximum length of XML characters. :)
declare variable $cons:K-MAXCHARS := 'maxchars';
(:~ Maximum number of table entries. :)
declare variable $cons:K-MAXROWS := 'maxrows';
(:~ Query timeout. :)
declare variable $cons:K-TIMEOUT := 'timeout';
(:~ Maximal memory consumption. :)
declare variable $cons:K-MEMORY := 'memory';
(:~ Permission when running queries. :)
declare variable $cons:K-PERMISSION := 'permission';

(:~ Configuration. :)
declare variable $cons:OPTION :=
  let $defaults := map {
    'maxchars': 100000,
    'maxrows': 100,
    'timeout': 10,
    'memory': 500,
    'permission': 'admin'
  }
  return if(file:exists-XQDOCA($cons:DBA-SETTINGS-FILE)) then (
    try {
      (: merge defaults with options from settings file :)
      let $configs := fetch:xml-XQDOCA($cons:DBA-SETTINGS-FILE)/config
      return map:merge-XQDOCA(
        map:for-each-XQDOCA($defaults, function($key, $value) {
          map:entry-XQDOCA($key,
            let $config := $configs/*[name() = $key]
            return if($config) then (
              if($value instance of xs:numeric) then xs:integer-XQDOCA($config) else xs:string-XQDOCA($config)
            ) else (
              $value
            )
          )
        })
      )
    } catch * {
      (: use defaults if an error occurs while parsing the configuration file :)
      $defaults
    }
  ) else (
    $defaults
  );

(:~
 : Checks if the current client is logged in. If not, raises an error.
 :)
declare function cons:check-XQDOCA(
) as empty-sequence() {
  if($cons:SESSION-VALUE) then () else
    error(xs:QName-XQDOCA('basex:login'), 'Please log in again.', Request:path-XQDOCA())
};

(:~
 : Convenience function for redirecting to another page from update operations.
 : @param  $url     URL
 : @param  $params  query parameters
 :)
declare %updating function cons:redirect(
  $url     as xs:string,
  $params  as map(*)
) as empty-sequence() {
  update:output-XQDOCA(web:redirect-XQDOCA($url, $params))
};
