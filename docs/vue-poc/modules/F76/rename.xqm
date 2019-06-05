(:  xqDocA added a comment :)
(:~ wadl:)
declare namespace xqdoc="http://www.xqdoc.org/1.0";
declare namespace wadl="http://wadl.dev.java.net/2009/02";
declare variable $src:="C:\tmp\xqdoc\src\graphxq\graphxq.xqm";

declare function local:get-XQDOCA($fun as element(xqdoc:function)*,$path as xs:string)
as element(wadl:resource)
{
 <wadl:resource path="{$path}">
<wadl:method name="GET">
        <wadl:doc xmlns="http://www.w3.org/1999/xhtml">about page for app</wadl:doc>
        <wadl:request/>
        <wadl:response>
          <wadl:representation mediaType="image/svg+xml"/>
        </wadl:response>

      </wadl:method>
</wadl:resource> 
};
let $xq:=doc($src)
let $prefix:=$xq//xqdoc:namespace[@uri="http://exquery.org/ns/restxq"]/@prefix/string()
let $paths:=$xq//xqdoc:functions/xqdoc:function/xqdoc:annotations/xqdoc:annotation[@name=$prefix || ":path"]/xqdoc:literal
let $p2:=$paths=>distinct-values()=>sort()
return <wadl:application>
<wadl:resources base="http://localhost:8984/doc/app//graphxq/view/wadl">
{for  $p in  $p2 return  local:get-XQDOCA((),$p)}
</wadl:resources>
</wadl:application>