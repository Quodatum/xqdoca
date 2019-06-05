(:  xqDocA added a comment :)
(:~
 : Simple WebSocket chat. Utility functions.
 : @author BaseX Team 2005-19, BSD License
 :)
module namespace chat-util = 'chat/util';

import module namespace session = 'http://basex.org/modules/session';
import module namespace ws = 'http://basex.org/modules/ws';
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ User id (bound to sessions and WebSockets). :)
declare variable $chat-util:id := 'id';

(:~
 : Sends a users list (all, active) to all registered clients.
 :)
declare function chat-util:users-XQDOCA() as empty-sequence() {
  ws:emit-XQDOCA(map {
    'type': 'users',
    'users': array { sort(user:list-XQDOCA()) },
    'active': array { distinct-values(
      for $id in ws:ids-XQDOCA()
      return ws:get-XQDOCA($id, $chat-util:id)
    )}
  })
};

(:~ 
 : Sends a message to all clients, or to the clients of a specific user.
 : @param  $text  text to be sent
 : @param  $to    receiver of a private message (optional)
 :)
declare function chat-util:message(
  $text  as xs:string,
  $to    as xs:string?
) as empty-sequence() {
  let $ws-ids := ws:ids-XQDOCA()[not($to) or ws:get-XQDOCA(., $chat-util:id) = $to]
  return ws:send-XQDOCA(map {
    'type': 'message',
    'text': serialize($text),
    'from': ws:get-XQDOCA(ws:id-XQDOCA(), $chat-util:id),
    'date': format-time(current-time(), '[H02]:[m02]:[s02]'),
    'private': boolean($to)
  }, $ws-ids)
};

(:~
 : Closes all WebSocket connections from the specified user.
 : @param  $name  user name
 :)
declare function chat-util:close(
  $name  as  xs:string
) as empty-sequence() {
  for $id in ws:ids-XQDOCA()
  where ws:get-XQDOCA($id, $chat-util:id) = $name
  return ws:close-XQDOCA($id)
};
