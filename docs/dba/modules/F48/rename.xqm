(:  xqDocA added a comment :)
(:~
 : Edit user.
 :
 : @author Christian Grün, BaseX Team 2005-19, BSD License
 :)
module namespace dba = 'dba/users';

import module namespace util = 'dba/util' at '../modules/util.xqm';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ Sub category :)
declare variable $dba:SUB := 'user';

(:~
 : Edits a user.
 : @param  $name     user name
 : @param  $newname  new name
 : @param  $pw       password
 : @param  $perm     permission
 : @return redirection
 :)
declare
  %updating
  %rest:POST
  %rest:path("/dba/user-edit")
  %rest:query-param("name",    "{$name}")
  %rest:query-param("newname", "{$newname}")
  %rest:query-param("pw",      "{$pw}")
  %rest:query-param("perm",    "{$perm}")
function dba:user-edit-XQDOCA(
  $name     as xs:string,
  $newname  as xs:string,
  $pw       as xs:string,
  $perm     as xs:string
) as empty-sequence() {
  try {
    let $old := user:list-details-XQDOCA($name) return (
      if($name = $newname) then () else if(user:exists-XQDOCA($newname)) then (
         error((), 'User already exists.')
       ) else (
         user:alter-XQDOCA($name, $newname)
      ),
      if($pw = '') then () else user:password-XQDOCA($name, $pw),
      if($perm = $old/@permission) then () else user:grant-XQDOCA($name, $perm)
    ),
    util:redirect-XQDOCA($dba:SUB, map { 'name': $newname, 'info': 'User was saved.' })
  } catch * {
    util:redirect-XQDOCA($dba:SUB, map {
      'name': $name, 'newname': $newname, 'pw': $pw, 'perm': $perm, 'error': $err:description
    })
  }
};
