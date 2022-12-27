(:~ 
 : This module provides some sample functions to demonstrate
 : the features of the xqdoc format.
 :
 : @author   Quodatum Team
 : @see      https://github.com/Quodatum/xqdoca
 : @version  1.0
 :)
module namespace samples = 'http://basex.org/modules/samples';
import module namespace admin = 'http://basex.org/modules/admin' at "foo";
(:~ This is a sample string. :)
declare variable $samples:test-string as xs:string := 'this is a string';

(:~ This is a external number. :)
declare variable $samples:test-number as xs:integer external := 42 ;

(:~
 : This function simply returns the specified integer.
 : @param   $number number to return
 : @return  specified number
 :)
declare %private function samples:same($number as xs:integer) as xs:integer* {
  $number
};

(:~
 : This function  returns a map.
 : @return  the map
 :)
declare %public function samples:object() as map(*) {
  map{"answer":42}
};

(:~
 : This function  is external.
 : @return  empty
 :)
declare %public function samples:out() as empty-sequence() external;