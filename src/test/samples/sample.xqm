(:~ 
 : This module provides some sample functions to demonstrate
 : the features of the Inspection Module.
 :
 : @author   BaseX Team
 : @see      http://docs.basex.org/wiki/XQDoc_Module
 : @version  1.0
 :)
module namespace samples = 'http://basex.org/modules/samples';

(:~ This is a sample string. :)
declare variable $samples:test-string as xs:string := 'this is a string';

(:~
 : This function simply returns the specified integer.
 : @param   $number number to return
 : @return  specified number
 :)
declare %private function samples:same($number as xs:integer) as xs:integer {
  $number
};