(:  xqDocA added a comment :)
xquery version "3.1";
(:~ data locations for image feature :)
module namespace cfg = "quodatum:media.image.configure";

declare variable $cfg:DB-IMAGE:="media-images-20180817";

declare variable $cfg:IMAGEDIR:="P:/pictures/Pictures/";
declare variable $cfg:THUMBDIR:="C:/tmp/";

(:
declare variable $cfg:IMAGEDIR:="/mnt/sda1/pictures/Pictures/";
declare variable $cfg:THUMBDIR:="/mnt/sda1/pictures/thumbs/";
:)