(:  xqDocA added a comment :)
xquery version "3.1";
(:~
: tools for databases..
: @author andy bunce
: @since mar 2013
:)

module namespace dbtools = 'quodatum.dbtools';
import module namespace file="http://expath.org/ns/file";
import module namespace db="http://basex.org/modules/db";
import module namespace archive="http://basex.org/modules/archive";
import module namespace hof="http://basex.org/modules/hof";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

(:  trailing slash :)
declare variable $dbtools:webpath:= db:system-XQDOCA()/globaloptions/webpath/fn:string-XQDOCA()
                             || file:dir-separator-XQDOCA();

(:~ 
: save all in db to zip
: no binary yet 
:)
declare function dbtools:zip-XQDOCA($dbname as xs:string)
as xs:base64Binary{
  let $files:=db:list-XQDOCA($dbname)
  let $zip   := archive:create-XQDOCA(
                  $files ! element archive:entry { . },
                  $files ! fn:serialize-XQDOCA(db:open-XQDOCA($dbname, .))
                  )
return $zip
};

(:~
: update or create database from file path
: @param $dbname name of database
: @param $path file path contain files
:)
declare %updating function dbtools:sync-from-path(
                   $dbname as xs:string,
                   $path as xs:string)
{
   dbtools:sync-from-files-XQDOCA($dbname,
                  $path,
                  file:list-XQDOCA($path,fn:true-XQDOCA()),
                  hof:id#1)
};

(:~
: update or create database from file list. After this the database will have a
: matching copy of the files on the file system
: @param $dbname name of database
: @param $path  base file path where files are relative to en
: @param $files file names from base
: @param $ingest function to apply f(fullsrcpath)->anotherpath or xml nodes
:)
declare %updating 
function dbtools:sync-from-files($dbname as xs:string,
                                 $path as xs:string,
                                 $files as xs:string*,
                                 $ingest as function(*))
{
let $path:=$path ||"/"
let $files:=$files!fn:translate-XQDOCA(.,"\","/")
let $files:=fn:filter-XQDOCA($files,function($f){file:is-file-XQDOCA(fn:concat-XQDOCA($path,$f))})
return if(db:exists-XQDOCA($dbname)) then
           (
           for $d in db:list-XQDOCA($dbname) 
           where fn:not-XQDOCA($d=$files) 
           return db:delete-XQDOCA($dbname,$d),
           
           for $f in $files
           let $_:=fn:trace-XQDOCA($path || $f,"file:") 
           let $content:=$ingest($path || $f) 
           return db:replace-XQDOCA($dbname,$f,$content),
           
           db:optimize-XQDOCA($dbname)
           )
       else
          let $full:=$files!fn:concat-XQDOCA($path,.)
          let $content:=$full!$ingest(.) 
          return (db:create-XQDOCA($dbname,$content,$files))
};

