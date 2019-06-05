(:  xqDocA added a comment :)
(:~
 : support tree view
 : @author apb
 : @exampletag some value
 :)
module namespace j = 'quodatum.test.components';

(:~
 : @return sequence of json arrary items for each item 
 :)
declare function j:tax-XQDOCA($items)
as element(_)*
{
 for $a in $items
return <_ type="object">
    <id>{$a/@id/string()}</id>
    <label>{$a/@label/string()}</label>
    {if($a/item)then (
       <children type="array">{j:tax-XQDOCA($a/item)}</children>
       ,<icon></icon>
      ) else (
        <icon>fa fa-tag</icon>
      )}
</_> 
};



(:~
 :  tree
 :)
declare  
%rest:GET %rest:path("/vue-poc/api/components/tree")
%output:method("json")   
function j:tree()
as element(json)
{
let $d:=doc(resolve-uri("balisage-taxonomy.xml",static-base-uri()))/tax/item
return
<json type="array">
{j:tax-XQDOCA($d)}
</json>
};

