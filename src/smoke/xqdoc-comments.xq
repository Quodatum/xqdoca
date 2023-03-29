import module namespace xp="expkg-zone58:text.parse";
(:~ xparser defaults :)
declare variable $xparse_opts:=  map{ "lang":"xqdoc-comments",  "flatten":false() };
xp:parse("(:~ ggg :)", $xparse_opts)