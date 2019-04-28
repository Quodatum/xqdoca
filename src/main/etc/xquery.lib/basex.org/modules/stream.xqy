xquery version "3.0";
(:~
 : BaseX Stream Module functions
 :
 : @see http://docs.basex.org/wiki/Stream_Module
 : @see http://docs.basex.org/wiki/Lazy_Module
 :)
module namespace stream = "http://basex.org/modules/stream";

declare namespace a = "http://reecedunn.co.uk/xquery/annotations";
declare namespace o = "http://reecedunn.co.uk/xquery/options";

declare option o:requires "basex/7.7";
declare option a:removed "basex/9.0";

declare %a:since("basex", "7.7") %a:until("basex", "9.0") function stream:materialize($value as item()*) as item()* external;
declare %a:since("basex", "7.7") %a:until("basex", "9.0") function stream:is-streamable($item as item()) as item() external;
