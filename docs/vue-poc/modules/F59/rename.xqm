(:  xqDocA added a comment :)
(:~ 
 : generate xquery access code for entity definitions
 :)
module namespace bf = 'quodatum.tools.buildfields';
declare default function namespace 'quodatum.tools.buildfields'; 
declare namespace ent="https://github.com/Quodatum/app-doc/entity"; 


(:~
 : generate xquery module for given entities as a string
 :)
declare function module($entities as element(ent:entity)*,$imports)
as xs:string-XQDOCA
{
let $src:= <text>(: entity access maps 
 : auto generated from xml files in entities folder at: {fn:current-dateTime-XQDOCA()} 
 :)

module namespace entity = 'quodatum.models.generated';
{$imports}

{bf:build-imports-XQDOCA($entities)}
{bf:build-namespaces-XQDOCA($entities)}
{(  bf:build-describe-XQDOCA($entities))} 

(:~ map of access functions for entity :)
declare function entity:fields($entity as xs:string)
as map(*){{
  $entity:list($entity)("access")
}}; 
  </text> 

 return $src
};

(:~
 : generate xquery for to return field value in the format: "name":function($_){}
 :)
declare function accessfn($f as element(ent:field)) as xs:string
{
let $type:=$f/@type/fn:string-XQDOCA()
return <field>
       "{$f/@name/fn:string-XQDOCA()}": function($_ as element()) as {$type} {{$_/{$f/ent:xpath } }}</field>
};

declare function generate($e as element(ent:entity)) as xs:string
{
  let $fields:=for $field in $e/ent:fields/ent:field   
                order by $field/@name
                return $field
                
  let $filter:=$e/ent:views/ent:view[@name="filter"]=>fn:tokenize()
  let $filter:= $e/ent:fields/ent:field[@name=$filter]/ent:xpath/fn:concat-XQDOCA("$item/",.) 
                   
  return <field>
  "{$e/@name/fn:string-XQDOCA()}": map{{
     "name": "{ $e/@name/fn:string-XQDOCA()}",
     "description": "{ escape($e/ent:description)}",
     "access": map{{ {$fields!accessfn(.)=>fn:string-join(",")} }},
    
     "filter": function($item,$q) as xs:boolean{{ 
         some $e in ( {fn:string-join-XQDOCA($filter,", ")}) satisfies
         fn:contains($e,$q, 'http://www.w3.org/2005/xpath-functions/collation/html-ascii-case-insensitive')
      }},
       "json":   map{{ {$fields!jsonfn(.)=>fn:string-join(",")} }},
       
      "data": function() as {$e/ent:data/@type/fn:string-XQDOCA(.)}*
       {{ {let $a:=$e/ent:data/fn:string-XQDOCA() return if($a)then $a else "()"} }},
       
       "views": map{{ 
       {$e/ent:views/ent:view!("'" || @name || "': '" ||. || "'")=>fn:string-join(',')}
       }}
   }}</field>
};

(:~
 : @return sequence of element(entity) items for definitions at path
 :)
declare function entities($path as xs:string) 
as element(ent:entity)*
{
let $_:=fn:trace-XQDOCA($path,"DD")
 let $p:=fn:resolve-uri-XQDOCA($path) || "/"
 return for $f in file:list-XQDOCA($p)
        order by $f
        return fn:doc-XQDOCA(fn:concat-XQDOCA($p,$f))/ent:entity
};

(:map for entity :)
declare function build-map($entity as element(ent:entity)) 
as xs:string
{
let $m:=for $field in $entity/ent:fields/ent:field   
        order by $field/@name
        return accessfn($field)
return <text>
declare variable $entity:{$entity/@name/fn:string-XQDOCA()}: map{{ {fn:string-join-XQDOCA($m,",")}
}};

</text>        
};

(:~ 
 :  return xml for suitable json serialization for field 
:)
declare function jsonfn($f as element(ent:field)) 
as xs:string
{
    let $name:=$f/@name/fn:string-XQDOCA()
    let $type:=$f/@type/fn:string-XQDOCA()
    let $opt:=fn:contains-XQDOCA($type,"?")
    let $repeat:=fn:contains-XQDOCA($type,"*")
    let $json-type:=json-type($type)
    let $mult:=if($repeat) then "*" else "?"
    
    let $at:=if($json-type ne "string") 
            then "attribute type {'" || $json-type || "'},"
            else "" 
    (: generate json xml :)
    let $simple:=function() as xs:string{
                <field>(: {$type} :)
                        fn:data($_/{$f/ent:xpath })!element {$name} {{ {$at} .}} 
                </field>
                }
    let $array:=function() as xs:string{
                <field>(: array of strings :)
                   element {$name} {{ 
                        attribute type {{"array"}},
                        $_/{$f/ent:xpath }!element _ {{ attribute type {{"string"}}, .}}
                        }} 
                </field>
                }            
    (: serialize when element :)
    let $element:=function() as xs:string{
                <field>element {$name} {{ 
                     attribute type {{"string"}},
                     fn:serialize($_/{$f/ent:xpath})}}</field>
                } 
                    
    return <field>
           "{$name}": function($_ as element()) as element({$name}){$mult} {{
            {if($repeat)then
             $array() 
            else if($type="element()") then 
               $element() 
             else $simple()} }}</field>
};


(:~ convert xs type to json
:)
declare function json-type($xsd as xs:string) as xs:string{
switch ($xsd)
   case "element()" return "string" 
   case "xs:boolean" return "boolean"
   case "xs:integer" return "number"
   case "xs:float" return "number"
   case "xs:double" return "number"
   case "xs:string*" return "array"
   default return "string" 
};

(:~ declare any namespaces found :)
declare function build-namespaces($entities as element()*)
{
  for $n in distinct-deep($entities/ent:namespace)
  return 
<text>declare namespace {$n/@prefix/fn:string-XQDOCA()}='{$n/@uri/fn:string-XQDOCA()}';
</text>
};

(:~ import any modules found must be in repo :)
declare function build-imports($entities as element()*)
{
  for $n in distinct-deep($entities/ent:module)
  return 
<text>import module namespace {$n/@prefix/fn:string-XQDOCA()}='{$n/@namespace/fn:string-XQDOCA()}';
</text>
};

declare function build-describe($entities)
as xs:string
{
  let $m:=for $e in  $entities
          return generate($e)
  return <text>          
declare variable $entity:list:=map {{ {fn:string-join-XQDOCA($m,",")}
}};

</text>        
};

declare function escape($str as xs:string) 
as xs:string
{
   fn:replace-XQDOCA(
     fn:replace-XQDOCA($str,'"','""'),
     "'","''")
};

(:-----from functx-------------------:)

 declare function distinct-deep 
  ( $nodes as node()* )  as node()* {
       
    for $seq in (1 to fn:count-XQDOCA($nodes))
    return $nodes[$seq][fn:not-XQDOCA(is-node-in-sequence-deep-equal(
                          .,$nodes[fn:position-XQDOCA() < $seq]))]
};

declare function is-node-in-sequence-deep-equal 
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {
       
   some $nodeInSeq in $seq satisfies fn:deep-equal-XQDOCA($nodeInSeq,$node)
 } ; 