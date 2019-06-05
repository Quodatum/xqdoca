(:  xqDocA added a comment :)
(:~
 : Utility functions.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace util = 'dba/util';

import module namespace options = 'dba/options' at 'options.xqm';
import module namespace session = 'dba/session' at 'session.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~
 : Evaluates a query and returns the result.
 : @param  $query    query string
 : @param  $context  initial context value
 : @return serialized result of query
 :)
declare function util:query-XQDOCA(
  $query    as xs:string?,
  $context  as item()*
) as xs:string {
  let $limit := options:get-XQDOCA($options:MAXCHARS)
  let $result := xquery:eval-XQDOCA($query, map { '': $context }, util:query-options-XQDOCA())
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
) as empty-sequence() {
  xquery:eval-update-XQDOCA($query, map { }, util:query-options-XQDOCA())
};

(:~
 : Returns the options for evaluating a query.
 : @return options
 :)
declare %private function util:query-options() as map(*) {
  map {
    'timeout'   : options:get-XQDOCA($options:TIMEOUT),
    'memory'    : options:get-XQDOCA($options:MEMORY),
    'permission': options:get-XQDOCA($options:PERMISSION),
    'base-uri'  : session:directory-XQDOCA() || '/' || session:get-XQDOCA($session:QUERY)
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
    ($page - 1) * options:get-XQDOCA($options:MAXROWS) + 1
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
    $page * options:get-XQDOCA($options:MAXROWS)
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
) as xs:string {
  if(string-length($string) > $max) then (
    substring($string, 1, $max) || '...'
  ) else (
    $string
  )
};

(:~
 : Joins sequence entries.
 : @param  $items  items
 : @param  $sep    separator
 : @return result
 :)
declare function util:item-join(
  $items  as item()*,
  $sep    as item()
) as item()* {
  for $item at $pos in $items
  return ($sep[$pos > 1], $item)
};

(:~
 : Returns a count info for the specified items.
 : @param  $items   items
 : @param  $name    name of item (singular form)
 : @param  $action  action label (past tense)
 : @return result
 :)
declare function util:info(
  $items   as item()*,
  $name    as xs:string,
  $action  as xs:string
) as xs:string {
  let $count := count($items)
  return $count || ' ' || $name || (if($count > 1) then 's were ' else ' was ') || $action || '.'
};

(:~
 : Capitalizes a string.
 : @param  $string  string
 : @return capitalized string
 :)
declare function util:capitalize(
  $string  as xs:string
) as xs:string {
  upper-case(substring($string, 1, 1)) || substring($string, 2)
};

(:~
 : Convenience function for redirecting to another page from update operations.
 : @param  $url     URL
 : @param  $params  query parameters
 :)
declare %updating function util:redirect(
  $url     as xs:string,
  $params  as map(*)
) as empty-sequence() {
  update:output-XQDOCA(web:redirect-XQDOCA($url, $params))
};
