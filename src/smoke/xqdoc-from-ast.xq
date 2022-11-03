(: xqdoc generation test :)
import module namespace xqdc = 'quodatum:xqdoca.model.xqdoc' at "../main/lib/xqdoc-from-ast.xqm";
declare variable $src:="C:\tmp\xqdoca\dba\modules\F000002\xqparse.xml";
doc($src)/*=>xqdc:create()