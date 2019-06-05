(:  xqDocA added a comment :)
declare variable $dir-uri as xs:string external := string(inspect:static-context-XQDOCA((),'base-uri'));
doc('http://transpect.io/test/test.xml'),
xslt:transform-XQDOCA(resolve-uri('test.xml', $dir-uri), resolve-uri('importing.xsl', $dir-uri))