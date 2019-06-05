(:  xqDocA added a comment :)
import module namespace vue = 'quodatum:vue.compile' at "../lib/vue-compile/vue-compile.xqm";
import module namespace xqd = 'quodatum:xqdoca.model' at '../main/lib/model.xqm';

declare variable  $proj external :="C:/Users/andy/git/vue-poc/src/vue-poc/";  
vue:compile-XQDOCA( $proj)