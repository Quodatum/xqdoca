xquery version '3.1';
(:~ 
A BaseX 10.7+ interface to pdfbox3 https://pdfbox.apache.org/ , 
requires pdfbox jars on classpath, in lib/custom or xar
@note following the java source the terms outline and bookmark
refer to the same concept. Also label and (page)range are used interchangably
@note tested with pdfbox-app-3.0.5.jar
@see https://pdfbox.apache.org/download.cgi
@javadoc https://javadoc.io/static/org.apache.pdfbox/pdfbox/3.0.5/
@author Andy Bunce 2025
:)

module namespace pdfbox="org.expkg_zone58.Pdfbox3";

declare namespace Loader ="java:org.apache.pdfbox.Loader"; 
declare namespace PDFTextStripper = "java:org.apache.pdfbox.text.PDFTextStripper";
declare namespace PDDocument ="java:org.apache.pdfbox.pdmodel.PDDocument";
declare namespace PDDocumentCatalog ="java:org.apache.pdfbox.pdmodel.PDDocumentCatalog";
declare namespace PDPageLabels ="java:org.apache.pdfbox.pdmodel.common.PDPageLabels";
declare namespace PDPageLabelRange="java:org.apache.pdfbox.pdmodel.common.PDPageLabelRange";

declare namespace PageExtractor ="java:org.apache.pdfbox.multipdf.PageExtractor";
declare namespace PDPage ="java:org.apache.pdfbox.pdmodel.PDPage";
declare namespace PDPageTree ="java:org.apache.pdfbox.pdmodel.PDPageTree";
declare namespace PDDocumentOutline ="java:org.apache.pdfbox.pdmodel.interactive.documentnavigation.outline.PDDocumentOutline";
declare namespace PDDocumentInformation ="java:org.apache.pdfbox.pdmodel.PDDocumentInformation";
declare namespace PDOutlineItem="java:org.apache.pdfbox.pdmodel.interactive.documentnavigation.outline.PDOutlineItem";
declare namespace PDFRenderer="java:org.apache.pdfbox.rendering.PDFRenderer";
declare namespace PDMetadata="java:org.apache.pdfbox.pdmodel.common.PDMetadata";
declare namespace COSInputStream="java:org.apache.pdfbox.cos.COSInputStream";


declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";


declare namespace RandomAccessReadBuffer="java:org.apache.pdfbox.io.RandomAccessReadBuffer";
declare namespace RandomAccessReadBufferedFile = "java:org.apache.pdfbox.io.RandomAccessReadBufferedFile";
declare namespace PDRectangle="java:org.apache.pdfbox.pdmodel.common.PDRectangle";

declare namespace File ="java:java.io.File";



(:~ "With-document" pattern: open pdf,apply $fn function, close pdf
 creates a local pdfobject and ensures it is closed after use
e.g pdfbox:with-pdf("path...",pdfbox:page-text(?,5))
:)
declare function pdfbox:with-pdf($src as xs:string,
                                $fn as function(item())as item()*)
as item()*{
 let $pdf:=pdfbox:open($src)
 return try{
            $fn($pdf),pdfbox:close($pdf)
        } catch *{
            pdfbox:close($pdf),fn:error($err:code,$src || " " || $err:description)
        }

};


(:~ open pdf using fetch:binary, returns pdf object :)
declare function pdfbox:open($pdfsrc as item())
as item(){
pdfbox:open($pdfsrc, map{})
};

(:~ open pdf from file/url/binary, opts may have password , returns pdf object 
@param $pdfsrc a fetchable url or filepath, or xs:base64Binary item
@param $opts options options include map {"password":}
@note fetch:binary for https will use a lot of memory here
:)
declare function pdfbox:open($pdfsrc as item(), $opts as map(*))
as item(){
  try{

      if($pdfsrc instance of xs:base64Binary)
      then Loader:loadPDF( $pdfsrc,string($opts?password))
      else if(starts-with($pdfsrc,"http"))
           then Loader:loadPDF( fetch:binary($pdfsrc),string($opts?password))
           else  Loader:loadPDF(RandomAccessReadBufferedFile:new($pdfsrc),string($opts?password))

} catch *{
    let $loc:=if($pdfsrc instance of xs:base64Binary)
              then "xs:base64Binary"
              else $pdfsrc
    return error(xs:QName("pdfbox:open"),"Failed PDF load " || $loc || " " || $err:description)
}
};

(:~ The version of the PDF specification used by $pdf  e.g "1.4"
returned as string to avoid float rounding issues
 :)
declare function pdfbox:specification($pdf as item())
as xs:string{
 PDDocument:getVersion($pdf)=>xs:decimal()=>round(4)=>string()
};

(:~ Save pdf $pdf to filesystem at $savepath , returns $savepath :)
declare function pdfbox:pdf-save($pdf as item(),$savepath as xs:string)
as xs:string{
   PDDocument:save($pdf, File:new($savepath)),$savepath
};

(:~ Create binary representation of $pdf object as xs:base64Binary :)
declare function pdfbox:binary($pdf as item())
as xs:base64Binary{
   let $bytes:=Q{java:java.io.ByteArrayOutputStream}new()
   let $_:=PDDocument:save($pdf, $bytes)
   return  Q{java:java.io.ByteArrayOutputStream}toByteArray($bytes)
         =>convert:integers-to-base64()
};

(:~ Release any resources related to <code>$pdf</code>:)
declare function pdfbox:close($pdf as item())
as empty-sequence(){
  (# db:wrapjava void #) {
     PDDocument:close($pdf)
  }
};

(:~ Number of pages in PDF:)
declare function pdfbox:number-of-pages($pdf as item())
as xs:integer{
  PDDocument:getNumberOfPages($pdf)
};

(:~ Pdf page as image (zero is cover)
options.format="bmp jpg png gif" etc, options.scale= 1 is 72 dpi?? :)
declare function pdfbox:page-render($pdf as item(),$pageNo as xs:integer,$options as map(*))
as xs:base64Binary{
  let $options := map:merge(($options,map{"format":"jpg","scale":1}))
  let $bufferedImage := PDFRenderer:new($pdf)
                      =>PDFRenderer:renderImage($pageNo,$options?scale)
  let $bytes := Q{java:java.io.ByteArrayOutputStream}new()
  let $_ := Q{java:javax.imageio.ImageIO}write($bufferedImage ,$options?format,  $bytes)
  return Q{java:java.io.ByteArrayOutputStream}toByteArray($bytes)
         =>convert:integers-to-base64()
 
};


(:~ Defines a map from property names to evaluation method.
   Keys are property names, 
   values are sequences of functions to get property value starting from a $pdf object.
:)
declare %private variable $pdfbox:property-map:=map{
  "#pages": pdfbox:number-of-pages#1,

  "#bookmarks": pdfbox:number-of-bookmarks#1,

  "#labels": pdfbox:number-of-labels#1,

  "specification":pdfbox:specification#1,

  "title": (PDDocument:getDocumentInformation#1,
            PDDocumentInformation:getTitle#1) ,

  "author": (PDDocument:getDocumentInformation#1,
             PDDocumentInformation:getAuthor#1 ),

  "creator": (PDDocument:getDocumentInformation#1,
              PDDocumentInformation:getCreator#1),

  "producer": (PDDocument:getDocumentInformation#1,
               PDDocumentInformation:getProducer#1),

  "subject": (PDDocument:getDocumentInformation#1,
              PDDocumentInformation:getSubject#1),

  "keywords": (PDDocument:getDocumentInformation#1,
               PDDocumentInformation:getKeywords#1),

  "creationDate": (PDDocument:getDocumentInformation#1,
                   PDDocumentInformation:getCreationDate#1,
                   pdfbox:gregToISO#1),

  "modificationDate":  (PDDocument:getDocumentInformation#1,
                        PDDocumentInformation:getModificationDate#1,
                        pdfbox:gregToISO#1),

   "labels":      pdfbox:labels-as-string#1                     
};

(:~ Defined property names, sorted :)
declare function pdfbox:property-names() 
as xs:string*{
  $pdfbox:property-map=>map:keys()=>sort()
};

(:~  Return the value of $property for $pdf :)
declare function pdfbox:property($pdf as item(),$property as xs:string)
as item()*{
  let $fns:= $pdfbox:property-map($property)
  return if(exists($fns))
         then fold-left($fns, 
                        $pdf, 
                        function($result,$this as function(*)){$result!$this(.)})
         else error(xs:QName('pdfbox:property'),concat("Property '",$property,"' not defined."))
};

(:~ summary CSV style info for all properties for $pdfpaths 
:)
declare function pdfbox:report($pdfpaths as xs:string*)
as map(*){
 pdfbox:report($pdfpaths,pdfbox:property-names())
};

(:~ summary CSV style info for named $properties for PDFs in $pdfpaths 
@see https://docs.basex.org/main/CSV_Functions#xquery
:)
declare function pdfbox:report($pdfpaths as item()*, $properties as xs:string*)
as map(*){
  map{"names":   array{"path",$properties},
  
      "records": for $path in $pdfpaths
                 let $name:=if($path instance of xs:base64Binary) then "binary" else $path
                 return try{
                  let $pdf:=pdfbox:open($path)
                  return (fold-left($properties,
                                  array{$name},
                                  function($result as array(*),$prop as xs:string){
                                    array:append($result, string(pdfbox:property($pdf, $prop)))}
                         ), pdfbox:close($pdf)
                         )
                 } catch *{
                      fold-left($properties,
                                array{$name},
                                function($result as array(*),$prop as xs:string){
                                    array:append($result, "#ERROR")}
                               )
                 }
               
  }
};

(:~ Convenience function to save report() data to file :)
declare function pdfbox:report-save($data as map(*),$dest as xs:string)
as empty-sequence(){
  let $opts := map {  "format":"xquery", "header":"yes", "separator" : "," }
  return file:write-text($dest,csv:serialize($data,$opts))
};

(:~ The number of outline items defined in $pdf :)
declare function pdfbox:number-of-bookmarks($pdf as item())
as xs:integer{
  let $xml:=pdfbox:outline-xml($pdf)
  return count($xml//bookmark)
};

(:~ XMP metadata as "RDF" document
@note usually rdf:RDF root, but sometimes x:xmpmeta 
:)
declare function pdfbox:metadata($pdf as item())
as document-node(element(*))?
{
  let $m:=PDDocument:getDocumentCatalog($pdf)
         =>PDDocumentCatalog:getMetadata()
  return  if(exists($m))
          then 
              let $is:=PDMetadata:exportXMPMetadata($m)
              return pdfbox:do-until(
                        map{"n":0,"data":""},

                        function($input,$pos ) {  pdfbox:read-stream($is,$input?data)},

                        function($output,$pos) { $output?n eq -1 }     
                     )?data=>parse-xml()
          else ()
};

(:~ read next block from XMP stream :)
declare %private function pdfbox:read-stream($is,$read as xs:string)
as map(*){
  let $blen:=4096
  let $buff:=Q{java:java.util.Arrays}copyOf(array{xs:byte(0)},$blen)
  let $n:= COSInputStream:read($is,$buff,xs:int(0),xs:int($blen))
  let $data:=convert:integers-to-base64(subsequence($buff,1,$n))=>convert:binary-to-string()
  return map{"n":$n, "data": $read || $data}
};

(:~ Return outline for $pdf as map()* :)
declare function pdfbox:outline($pdf as item())
as map(*)*{
  (# db:wrapjava some #) {
  let $outline:=
                PDDocument:getDocumentCatalog($pdf)
                =>PDDocumentCatalog:getDocumentOutline()
 
  return  if(exists($outline))
          then pdfbox:outline($pdf,PDOutlineItem:getFirstChild($outline)) 
  }
};

(:~ return bookmark info for children of $outlineItem as seq of maps :)
declare %private function pdfbox:outline($pdf as item(),$outlineItem as item()?)
as map(*)*{
  let $find as map(*):=pdfbox:outline_($pdf ,$outlineItem)
  return map:get($find,"list")
};

(:~ outline helper. BaseX bug 10.7? error if inlined in outline :)
declare %private function pdfbox:outline_($pdf as item(),$outlineItem as item()?)
as map(*){
  pdfbox:do-until(
    
     map{"list":(),"this":$outlineItem},

     function($input,$pos ) { 
        let $bk:= pdfbox:bookmark($input?this,$pdf)
        let $bk:= if($bk?hasChildren)
                  then let $kids:=pdfbox:outline($pdf,PDOutlineItem:getFirstChild($input?this))
                        return map:merge(($bk,map:entry("children",$kids)))
                  else $bk 
        return map{
              "list": ($input?list, $bk),
              "this":  PDOutlineItem:getNextSibling($input?this)}
      },

     function($output,$pos) { empty($output?this) }                      
  )
};

(:~ PDF outline in xml format :)
declare function pdfbox:outline-xml($pdf as item())
as element(outline)?{
 let $outline:=pdfbox:outline($pdf)
  return if(exists($outline))
         then <outline>{$outline!pdfbox:bookmark-xml(.)}</outline>
         else ()
};

(:~ Convert outline map to XML :)
declare %private function pdfbox:bookmark-xml($outline as map(*)*)
as element(bookmark)*
{
  $outline!
  <bookmark title="{?title}" index="{?index}">
    {?children!pdfbox:bookmark-xml(.)}
  </bookmark>
};

(:~ Return bookmark info for $bookmark
@return map{index:..,title:..,hasChildren:..}
:)
declare %private function pdfbox:bookmark($bookmark as item(),$pdf as item())
as map(*)
{
 map{ 
  "index":  PDOutlineItem:findDestinationPage($bookmark,$pdf)=>pdfbox:find-page($pdf),
  "title":  (# db:checkstrings #) {PDOutlineItem:getTitle($bookmark)}
  (:=>translate("�",""), :),
  "hasChildren": PDOutlineItem:hasChildren($bookmark)
  }
};


(:~ pageIndex of $page in $pdf :)
declare function pdfbox:find-page(
   $page as item()? (: as java:org.apache.pdfbox.pdmodel.PDPage :),
   $pdf as item())
as item()?
{
  if(exists($page))
  then PDDocument:getDocumentCatalog($pdf)
      =>PDDocumentCatalog:getPages()
      =>PDPageTree:indexOf($page)
};            

(:~  Return new  PDF doc with pages from $start to $end as xs:base64Binary, (1 based)  
@param $start first page to include
@param $end last page to include
:)
declare function pdfbox:extract-range($pdf as item(), 
             $start as xs:integer,$end as xs:integer)
as xs:base64Binary
{
    let $a:=PageExtractor:new($pdf, $start, $end) =>PageExtractor:extract()
    return (pdfbox:binary($a),pdfbox:close($a)) 
};

(:~ The number of labels defined in PDF  :)
declare function pdfbox:number-of-labels($pdf as item())
as xs:integer
{
  let $labels:=PDDocument:getDocumentCatalog($pdf)
               =>PDDocumentCatalog:getPageLabels()
  return if(exists($labels)) 
         then PDPageLabels:getPageRangeCount($labels)
         else 0
};

(:~   pageLabel for every page from derived from page-ranges
The returned sequence will contain at MOST as much entries as the document has pages.
@see https://www.w3.org/TR/WCAG20-TECHS/PDF17.html#PDF17-examples
@see https://codereview.stackexchange.com/questions/286078/java-code-showing-page-labels-from-pdf-files
:)
declare function pdfbox:labels-by-page($pdf as item())
as xs:string*
{
  PDDocument:getDocumentCatalog($pdf)
  =>PDDocumentCatalog:getPageLabels()
  =>PDPageLabels:getLabelsByPageIndices()
};

(:~ sequence of label ranges defined in PDF as formatted strings
@return a custom representation of the labels e.g "0-*Cover,1r,11D" 
:)
declare function pdfbox:labels-as-string($pdf as item())
as xs:string{
  let $pagelabels:=PDDocument:getDocumentCatalog($pdf)
                   =>PDDocumentCatalog:getPageLabels()
  return $pagelabels
         !(0 to pdfbox:number-of-pages($pdf)-1)
         !pdfbox:label-as-string($pagelabels,.)=>string-join("&#10;")
            
};

(:~ get pagelabels exist :)
declare function pdfbox:page-labels($pdf)
{
  PDDocument:getDocumentCatalog($pdf)
  =>PDDocumentCatalog:getPageLabels()
};

(:~ label for $page formated as string, empty if none :)
declare function pdfbox:label-as-string($pagelabels,$page as  xs:integer)
as xs:string?{
  let $label:=PDPageLabels:getPageLabelRange($pagelabels,$page)
  return  if(empty($label))
          then ()
          else
            let $start:=  PDPageLabelRange:getStart($label)
            let $style := PDPageLabelRange:getStyle($label)
            let $prefix:= PDPageLabelRange:getPrefix($label) 
            return string-join(($page, 
                                if(empty($style)) then "-" else $style,
                                if(($start eq 1)) then "" else $start,
                                if(exists($prefix)) then '*' || $prefix  (:TODO double " :)
                    ))
};

(:~ sequence of maps for each label/page range defined in $pdf:)
declare function pdfbox:labels-as-map($pdf as item())
as map(*)*{
  let $pagelabels:=PDDocument:getDocumentCatalog($pdf)
                   =>PDDocumentCatalog:getPageLabels()
  return  $pagelabels
          !(0 to pdfbox:number-of-pages($pdf)-1)
          !pdfbox:label-as-map($pagelabels,.)
};

(:~ label/page-range for $page as map :)
declare function pdfbox:label-as-map($pagelabels,$page as  xs:integer)
as map(*)
{
  let $label:=PDPageLabels:getPageLabelRange($pagelabels,$page)
  return if(empty($label))
  then ()
  else map{
      "index": $page,
      "prefix": PDPageLabelRange:getPrefix($label),
      "start":  PDPageLabelRange:getStart($label),
      "style":  PDPageLabelRange:getStyle($label)
      }
};



(:~ return text on $pageNo :)
declare function pdfbox:page-text($pdf as item(), $pageNo as xs:integer)
as xs:string{
  let $tStripper := (# db:wrapjava instance #) {
         PDFTextStripper:new()
         => PDFTextStripper:setStartPage($pageNo)
         => PDFTextStripper:setEndPage($pageNo)
       }
  return (# db:checkstrings #) {PDFTextStripper:getText($tStripper,$pdf)}
};

(:~ Return size of $pageNo (zero based)
@return e.g. [0.0,0.0,168.0,239.52]
 :)
declare function pdfbox:page-media-box($pdf as item(), $pageNo as xs:integer)
as xs:string{
  PDDocument:getPage($pdf, $pageNo)
  =>PDPage:getMediaBox()
  =>PDRectangle:toString()
};

(:~  Version of Apache Pdfbox in use  e.g. "3.0.4" :)
declare function pdfbox:version()
as xs:string{
  Q{java:org.apache.pdfbox.util.Version}getVersion()
};

(:~ Convert date :)
declare %private
function pdfbox:gregToISO($item as item()?)
as xs:string?{
 if(exists($item))
 then Q{java:java.util.GregorianCalendar}toZonedDateTime($item)=>string()
 else ()
};

(:~ fn:do-until shim for BaseX 9+10 
if  fn:do-until not found use hof:until, note: $pos always zero
:)
declare %private function pdfbox:do-until(
 $input 	as item()*, 	
 $action 	as function(item()*, xs:integer) as item()*, 	
 $predicate 	as function(item()*, xs:integer) as xs:boolean? 	
) as item()*
{
  let $fn:=function-lookup(QName('http://www.w3.org/2005/xpath-functions','do-until'), 3)
  return if(exists($fn))
         then $fn($input,$action,$predicate)
         else let $hof:=function-lookup(QName('http://basex.org/modules/hof','until'), 3)
              return if(exists($hof))
                      then $hof($predicate(?,0),$action(?,0),$input)
                      else error(xs:QName('pdfbox:do-until'),"No implementation do-until found")

};
