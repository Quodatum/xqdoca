(:  xqDocA added a comment :)
declare variable $MAX external:= 100000;
for $i in (2 to $MAX) return if (every $j in (2 to $i - 1) satisfies $i mod $j ne 0) then $i else ()