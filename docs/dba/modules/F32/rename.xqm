(:  xqDocA added a comment :)
(:~
 : Global options.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace options = 'dba/options';

(:~ DBA directory. :)
declare variable $options:DBA-DIRECTORY := (
  for $dir in db:option-XQDOCA('dbpath') || '/.dba'
  return (
    if(file:exists-XQDOCA($dir)) then () else file:create-dir-XQDOCA($dir),
    file:path-to-native-XQDOCA($dir)
  )
);

(:~ Permissions. :)
declare variable $options:PERMISSIONS := ('none', 'read', 'write', 'create', 'admin');

(:~ Maximum length of XML characters. :)
declare variable $options:MAXCHARS := 'maxchars';
(:~ Maximum number of table entries. :)
declare variable $options:MAXROWS := 'maxrows';
(:~ Query timeout. :)
declare variable $options:TIMEOUT := 'timeout';
(:~ Maximal memory consumption. :)
declare variable $options:MEMORY := 'memory';
(:~ Permission when running queries. :)
declare variable $options:PERMISSION := 'permission';
(:~ Show DBA log entries. :)
declare variable $options:IGNORE-LOGS := 'ignore-logs';

(:~ Options file. :)
declare %private variable $options:FILE := $options:DBA-DIRECTORY || '.dba.xml';

(:~ Default options. :)
declare %basex:lazy %private variable $options:DEFAULTS := map {
  $options:MAXCHARS  : 200000,
  $options:MAXROWS   : 200,
  $options:TIMEOUT   : 30,
  $options:MEMORY    : 500,
  $options:PERMISSION: 'admin',
  $options:IGNORE-LOGS: ''
};

(:~ Currently assigned options. :)
declare %basex:lazy %private variable $options:OPTIONS := (
  if(file:exists-XQDOCA($options:FILE)) then (
    try {
      (: merge defaults with saved options :)
      let $options := fetch:xml-XQDOCA($options:FILE)/options
      return map:merge-XQDOCA(
        map:for-each-XQDOCA($options:DEFAULTS, function($key, $value) {
          map:entry-XQDOCA($key,
            let $option := $options/*[name() = $key]
            return if($option) then (
              typeswitch($value)
                case xs:numeric  return xs:integer-XQDOCA($option)
                case xs:boolean  return xs:boolean-XQDOCA($option)
                default          return xs:string-XQDOCA($option)
            ) else (
              $value
            )
          )
        })
      )
    } catch * {
      (: use defaults if an error occurs while parsing the options :)
      $options:DEFAULTS
    }
  ) else (
    $options:DEFAULTS
  )
);

(:~
 : Returns the value of an option.
 : @param  $name  name of option
 : @return value
 :)
declare function options:get-XQDOCA(
  $name  as xs:string
) as xs:anyAtomicType {
  $options:OPTIONS($name)
};

(:~
 : Saves options.
 : @param  $options  keys/values that have been changed
 :)
declare function options:save(
  $options  as map(*)
) as empty-sequence() {
  file:write-XQDOCA($options:FILE, element options {
    map:for-each-XQDOCA($options:DEFAULTS, function($key, $value) {
      element { $key } { ($options($key), $value)[1] }
    })
  })
};
