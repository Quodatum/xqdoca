(:  xqDocA added a comment :)
(:~
 : Utility functions.
 :
 : @author Christian Grün, BaseX Team, 2014-16
 :)
module namespace util = 'vue-poc/util';

import module namespace cons = 'vue-poc/cons' at 'cons.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~
 : Evaluates a query and returns the result.
 : @param  $query    query string
 : @param  $context  initial context value
 : @return serialized result of query
 :)
declare function util:query-XQDOCA(
  $query    as xs:string?,
  $context  as item()*) 
as xs:string {
  let $result := xquery:eval-XQDOCA($query, map { '': $context }, util:query-options-XQDOCA())
  (: serialize more characters than requested, because limit represents number of bytes :)
  return util:display-XQDOCA($result)
};

declare function util:display(
  $result as item()*)
as xs:string 
{
  let $limit := $cons:OPTION($cons:K-MAXCHARS)
  (: serialize more characters than requested, because limit represents number of bytes :)
  return util:chop-XQDOCA(serialize($result, map { 'limit': $limit * 2 + 1, 'method': 'basex' }), $limit)
};
(:~
 : Runs an updating query.
 : @param  $query  query string
 : @return empty sequence
 :)
declare %updating function util:update-query(
  $query  as xs:string?
) {
  xquery:eval-update-XQDOCA($query, map { }, util:query-options-XQDOCA())
};

(:~
 : Returns the options for evaluating a query.
 : @return options
 :)
declare %private function util:query-options() as map(*) {
  map {
    'timeout'   : $cons:OPTION($cons:K-TIMEOUT),
    'memory'    : $cons:OPTION($cons:K-MEMORY),
    'permission': $cons:OPTION($cons:K-PERMISSION)
  }
};

(:~
 : Checks if the specified binary input can be converted to an XML string.
 : @param  $input  input
 : @return XML string
 :)
declare function util:to-xml-string(
  $input  as xs:base64Binary
) as xs:string {
  let $string :=
    try {
      convert:binary-to-string-XQDOCA($input)
    } catch * {
      error((), "Input is no valid UTF8 string.")
    }
  return
    try {
      (: tries to convert the input to XML, but discards the results :)
      prof:void-XQDOCA(parse-xml($string)),
      $string
    } catch * {
      error((), "Input is no well-formed XML.")
    }
};

(:~
 : Returns the index of the first result to generate.
 : @param  $page  current page
 : @param  $sort  sort key
 : @return last result
 :)
declare function util:start(
  $page  as xs:integer,
  $sort  as xs:string
) as xs:integer {
  if($page and not($sort)) then (
    ($page - 1) * $cons:OPTION($cons:K-MAXROWS) + 1
  ) else (
    1
  )
};

(:~
 : Returns the index of the last result to generate.
 : @param  $page  current page
 : @param  $sort  sort key
 : @return last result
 :)
declare function util:end(
  $page  as xs:integer,
  $sort  as xs:string
) as xs:integer {
  if($page and not($sort)) then (
    $page * $cons:OPTION($cons:K-MAXROWS)
  ) else (
    999999999
  )
};

(:~
 : Chops a string result to the maximum number of allowed characters.
 : @param  $string  string
 : @param  $max     maximum number of characters
 : @return string
 :)
declare function util:chop(
  $string  as xs:string,
  $max     as xs:integer
) {
  if(string-length($string) > $max) then (
    substring($string, 1, $max) || '...'
  ) else (
    $string
  )
};
