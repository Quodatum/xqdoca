(:  xqDocA added a comment :)
import module namespace qipe='http://quodatum.com/ns/pipeline' at "../../lib/pipeline.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm' ;

declare namespace docinfo="http://www.lexis-nexis.com/glp/docinfo";
declare variable $base:="C:\Users\andy\Dropbox\job\lexisnexis.2\data\";
declare variable $src:="C:\Users\andy\Desktop\basex.versions\data\08s3\raw\";
declare function local:resolve-XQDOCA($path,$base){
  file:resolve-path-XQDOCA($path,$base)
};
let $ip:=file:list-XQDOCA($src,false(), "*.xml")
let $ip:=subsequence($ip,1,10)!doc(concat($src,.))
let $d:=
<root xmlns="http://quodatum.com/ns/pipeline">
 <xslt href="{ local:resolve-XQDOCA('08S3-to-rosetta-legdoc.xsl',$base) }"/>
 <validate href="{ local:resolve-XQDOCA('legdoc-norm.dtd',$base) }" type="dtd" failOnError="true"/>
 <store base="c:\tmp\" fileExpression="'a' || $position || '.xml'" dated="true"/>
</root>

 return qipe:run-XQDOCA($d,$ip)


