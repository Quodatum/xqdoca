(: AI slop :)
declare function local:pretty($doc as node()) as xs:string {
  let $indent := 2
  return local:format($doc, 0, $indent)
};

declare function local:format($node as node(), $depth as xs:integer, $indent as xs:integer) as xs:string {
  typeswitch($node)
    case element() 
      return local:indent($depth, $indent) || "<" || local:name($node) || ">" || 
             local:format-children($node/*, $depth + 1, $indent) || 
             local:indent($depth, $indent) || "</" || local:name($node) || ">"
    default 
      return $node
};

declare function local:format-children($nodes as node()*, $depth as xs:integer, $indent as xs:integer) as xs:string {
  string-join(for $n in $nodes return local:format($n, $depth, $indent), "\n")
};

declare function local:indent($depth as xs:integer, $spaces as xs:integer) as xs:string {
  string-join(for $i in 1 to ($depth * $spaces) return " ", "")
};