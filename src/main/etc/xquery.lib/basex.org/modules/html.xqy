xquery version "3.1";
(:~
 : BaseX HTML Functions Module
 :
 : @see http://docs.basex.org/wiki/HTML_Module
 :)
module namespace html = "http://basex.org/modules/html";

declare namespace a = "http://reecedunn.co.uk/xquery/annotations";
declare namespace o = "http://reecedunn.co.uk/xquery/options";

declare option o:requires "basex/7.6";

declare %a:since("basex", "7.6") function html:parser() as xs:string external;
declare %a:since("basex", "7.6") function html:parse($input as xs:anyAtomicType) as document-node() external;
declare %a:since("basex", "7.6") function html:parse($input as xs:anyAtomicType, $options as map(*)?) as document-node() external;