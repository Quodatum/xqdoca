(:  xqDocA added a comment :)
(:~
 : Simple WebSocket chat. WebSocket functions.
 : @author BaseX Team 2005-19, BSD License
 :)
module namespace chat-ws = 'chat-ws';

import module namespace chat-util = 'chat/util' at 'chat-util.xqm';
import module namespace request = "http://exquery.org/ns/request";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:~ 
 : Creates a WebSocket connection. Registers the user and notifies all clients.
 :)
declare
  %ws:connect('/chat')
function chat-ws:connect-XQDOCA() as empty-sequence() {
  ws:set-XQDOCA(ws:id-XQDOCA(), $chat-util:id, session:get-XQDOCA($chat-util:id)),
  chat-util:users-XQDOCA()
};

(:~ 
 : Processes a WebSocket message.
 : @param  $message  message
 :)
declare
  %ws:message('/chat', '{$message}')
function chat-ws:message(
  $message  as xs:string
) as empty-sequence() {
  let $json := parse-json($message)
  let $type := $json?type
  return if($type = 'message') then (
    chat-util:message-XQDOCA($json?text, $json?to)
  ) else if($type = 'ping') then(
    (: do nothing :)
  ) else error()
};

(:~ 
 : Closes a WebSocket connection. Unregisters the user and notifies all clients.
 :)
declare
  %ws:close('/chat')
function chat-ws:close() as empty-sequence() {
  ws:delete-XQDOCA(ws:id-XQDOCA(), $chat-util:id),
  chat-util:users-XQDOCA()
};
