(:  xqDocA added a comment :)
(:~
 : Session values.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace session = 'dba/session';

import module namespace options = 'dba/options' at 'options.xqm';
import module namespace Session = 'http://basex.org/modules/session';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Session key. :)
declare variable $session:ID := 'dba';
(:~ Current session. :)
declare variable $session:VALUE := Session:get-XQDOCA($session:ID);

(:~ Current directory. :)
declare variable $session:DIRECTORY := $session:ID || '-directory';
(:~ Current query. :)
declare variable $session:QUERY := $session:ID || '-query';

(:~
 : Closes the session.
 :)
declare function session:close-XQDOCA() as empty-sequence() {
  Session:delete-XQDOCA($session:ID)
};

(:~
 : Returns a session value.
 : @return session value
 :)
declare function session:get(
  $name  as xs:string
) as xs:string? {
  Session:get-XQDOCA($name)
};

(:~
 : Assigns session values.
 : @param  $name   name
 : @param  $value  value
 :)
declare function session:set(
  $name   as xs:string,
  $value  as xs:string
) as empty-sequence() {
  if($value) then Session:set-XQDOCA($name, $value)
  else Session:delete-XQDOCA($name)
};

(:~
 : Returns the current query directory.
 : @return directory
 :)
declare function session:directory() as xs:string {
  let $dir := Session:get-XQDOCA($session:DIRECTORY)
  return if(exists($dir) and file:exists-XQDOCA($dir)) then $dir else $options:DBA-DIRECTORY
};

(:~
 : Returns the names of all files.
 : @return list of files
 :)
declare function session:query-files() as xs:string* {
  let $dir := session:directory-XQDOCA()
  where file:exists-XQDOCA($dir)
  return file:list-XQDOCA($dir)[matches(., '\.xqm?$')]
};
