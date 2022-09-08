(:
 : Copyright © 2019, Joe Wicentowski
 : All rights reserved.
 :
 : Redistribution and use in source and binary forms, with or without
 : modification, are permitted provided that the following conditions are met:
 :     * Redistributions of source code must retain the above copyright
 :       notice, this list of conditions and the following disclaimer.
 :     * Redistributions in binary form must reproduce the above copyright
 :       notice, this list of conditions and the following disclaimer in the
 :       documentation and/or other materials provided with the distribution.
 :     * Neither the name of the <organization> nor the
 :       names of its contributors may be used to endorse or promote products
 :       derived from this software without specific prior written permission.
 :
 : THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 : ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 : WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 : DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 : DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 : (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 : LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 : ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 : (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 : SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 :)
xquery version "3.1";

(:~ Validate, compare, sort, parse, and serialize Semantic Versioning (SemVer)
 :  2.0.0 version strings, using XQuery.
 :
 :  SemVer rules are applied strictly, raising errors when version strings do
 :  not conform to the spec.
 :
 :  @author Joe Wicentowski
 :  @version 2.2.2
 :  @see https://semver.org/spec/v2.0.0.html
 :  @see https://gist.github.com/joewiz/b349e2853a17bf817e5d0013d01fa9f9
 :)

module namespace semver = "http://exist-db.org/xquery/semver";

declare namespace array="http://www.w3.org/2005/xpath-functions/array";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

(:~ A regular expression for checking a SemVer version string
 :  @author David Fichtmueller
 :  @see https://github.com/semver/semver/pull/460
 :)
declare variable $semver:regex := "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$";

(:~ Validate whether a SemVer string conforms to the spec
 :  @param A version string
 :  @return True if the version is valid, false if not
 :)
declare function semver:validate($version as xs:string) as xs:boolean {
    try {
        let $parsed := semver:parse($version)
        return
            true()
    } catch * {
        false()
    }
};

(:~ Parse a SemVer version string (strictly)
 :  @param A version string
 :  @return A map containing analysis of the parsed version, containing entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :  @error regex-error
 :  @error identifier-error
 :)
declare function semver:parse($version as xs:string) as map(*) {
    semver:parse($version, false())
};

(:~ Parse a SemVer version string (with an option to coerce invalid SemVer strings)
 :  @param A version string
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return A map containing analysis of the parsed version, containing entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :  @error regex-error
 :  @error identifier-error
 :)
declare function semver:parse($version as xs:string, $coerce as xs:boolean) as map(*) {
    (: run the version against the standard SemVer regex :)
    let $analysis := analyze-string($version, $semver:regex)
    let $groups := $analysis/fn:match/fn:group
    return
        if (exists($groups)) then
            try {
                (: an inline function for casting identifiers to the appropriate types :)
                let $cast-identifier := function($identifier as xs:string) {
                    if ($identifier castable as xs:integer) then
                        $identifier cast as xs:integer
                    else
                        $identifier
                }
                let $release-identifiers := subsequence($groups, 1, 3) ! $cast-identifier(.)
                (: groups 4 and 5 are optional and so must be selected by @nr rather than position :)
                let $pre-release-identifiers := array { $groups[@nr eq "4"] ! tokenize(., "\.") ! $cast-identifier(.) }
                let $build-metadata-identifiers := array { $groups[@nr eq "5"] ! tokenize(., "\.") ! $cast-identifier(.) }
                return
                    map {
                        "major": $release-identifiers[1],
                        "minor": $release-identifiers[2],
                        "patch": $release-identifiers[3],
                        "pre-release": $pre-release-identifiers,
                        "build-metadata": $build-metadata-identifiers,
                        "identifiers": array { $release-identifiers, $pre-release-identifiers, $build-metadata-identifiers }
                    }
            } catch * {
                semver:error("identifier-error", $version)
            }
        else if ($coerce) then 
            semver:coerce($version)
        else
            semver:error("regex-error", $version)
};

(:~ Coerce a non-SemVer version string into SemVer version string and parse it as such
 :  @param A version string which will be coerced to a SemVer version string
 :  @return A map containing analysis of the parsed version, containing entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :)
declare function semver:coerce($version as xs:string?) as map(*) {
    let $version := string-to-codepoints($version)
    return
        let $major-ver := semver:read-version-number($version)
        let $minor-ver := semver:read-version-number($major-ver?tail)
        let $patch := semver:read-version-number($minor-ver?tail)
        let $pre-release := semver:read-pre-release($patch?tail)
        let $metadata := semver:read-metadata($pre-release?tail)
        let $mmp := map {
            "major": $major-ver?number,
            "minor": $minor-ver?number,
            "patch": $patch?number
        } return
            let $mmppr :=
                if (not(empty($pre-release?identifier)))
                then
                    map:merge(($mmp, map { "pre-release": array { $pre-release?identifier } }))
                else
                    map:merge(($mmp, map { "pre-release": [] }))
            return
                let $mmpprbm :=
                    if (not(empty($metadata?identifier)))
                    then
                        map:merge(($mmppr, map { "build-metadata": array { $metadata?identifier } }))
                    else
                        map:merge(($mmppr, map { "build-metadata": [] }))
                return
                    map:merge(($mmpprbm, map { "identifiers": [ $mmpprbm?major, $mmpprbm?minor, $mmpprbm?patch, $mmpprbm?pre-release, $mmpprbm?build-metadata ] }))
};

(:~
 : Read a major/minor/patch version number from a set of codepoints
 :
 : @param $s the codepoints
 : @return a map containing the "number" and the "tail", where the tail is any remaining codepoints after the "number".
 :)
declare %private function semver:read-version-number($s as xs:integer*) as map(*) {
	semver:read-version-number($s, ())
};

(:~
 : Read a major/minor/patch version number from a set of codepoints
 :
 : @param $s the codepoints
 : @param $accum an accumulator used for self-recursion.
 : @return a map containing the "number" and the "tail",
 :     where the tail is any remaining codepoints after the "number".
 :)
declare %private function semver:read-version-number($s as xs:integer*, $accum) as map(*) {
    let $head := head($s)
    let $tail := tail($s)
    return
        if (empty($head) or (not(empty($accum)) and $head eq 46) or $head = (43, 45))	(: 43 is a 'Plus Sign', i.e. '+', 45 is a hyphen, i.e. '-', and 46 is a 'period', i.e. '.' :)
        then
            map {
                "number": if (empty($accum)) then 0 else xs:integer($accum),
                "tail": $s
            }
        else
            (: 48 is a 'zero', i.e. '0', and 57 is a 'nine' i.e. '9' :)
            if ($head ge 48 and $head le 57)
            then
                semver:read-version-number($tail, $accum || codepoints-to-string($head))
            else
                (: skip character :)
                semver:read-version-number($tail, $accum)
};

(:~
 : Read a pre-release identifier from a set of codepoints
 :
 : @param $s the codepoints
 : @return a map containing a sequence of "identifier" and the "tail",
 :     where the tail is any remaining codepoints after the "identifier"(s).
 :)
declare %private function semver:read-pre-release($s as xs:integer*) as map(*) {
	semver:read-pre-release($s, ())
};

(:~
 : Read a pre-release identifier from a set of codepoints
 :
 : @param $s the codepoints
 : @param $accum an accumulator used for self-recursion.
 : @return a map containing a sequence of "identifier" and the "tail",
 :     where the tail is any remaining codepoints after the "identifier"(s).
 :)
declare %private function semver:read-pre-release($s as xs:integer*, $accum) as map(*) {
    let $head := head($s)
    let $tail := tail($s)
    return
        if (empty($head) or $head eq 43)  (: 43 is a 'Plus Sign', i.e. '+' :)
        then
            map {
                "identifier": $accum,
                "tail": $s
            }
        else if ($head eq 46)	(: 46 is a 'period', i.e. '.' :)
        then
            (: start next identifer :)
            semver:read-pre-release(subsequence($tail, 2), ($accum, codepoints-to-string($tail[1])))

        (: [0-9A-Za-z-] :)
        else if (($head ge 48 and $head le 57)
                or ($head ge 65 and $head le 90)
                or ($head ge 97 and $head le 122)
                or ($head eq 45 and not(empty($accum))))
        then
            semver:read-pre-release($tail, (subsequence($accum, 1, count($accum) - 1), $accum[last()] || codepoints-to-string($head)))
        else
            (: skip character :)
            semver:read-pre-release($tail, $accum)
};

(:~
 : Read build metadata identifiers from a set of codepoints
 :
 : @param $s the codepoints
 : @return a map containing a sequence of "identifier" and the "tail",
 :     where the tail is any remaining codepoints after the "identifier"(s).
 :)
declare %private function semver:read-metadata($s as xs:integer*) as map(*) {
	semver:read-metadata($s, ())
};

(:~
 : Read a build metadata identifiers from a set of codepoints
 :
 : @param $s the codepoints
 : @param $accum an accumulator used for self-recursion.
 : @return a map containing a sequence of "identifier" and the "tail",
 :     where the tail is any remaining codepoints after the "identifier"(s).
 :)
declare %private function semver:read-metadata($s as xs:integer*, $accum) as map(*) {
    let $head := head($s)
    let $tail := tail($s)
    return
        if (empty($head) or (not(empty($accum)) and $head eq 43))  (: 43 is a 'Plus Sign', i.e. '+' :)
        then
            map {
                "identifier": $accum,
                "tail": $s
            }
        else if ($head eq 46)	(: 46 is a 'period', i.e. '.' :)
        then
            (: start next identifer :)
            semver:read-pre-release(subsequence($tail, 2), ($accum, codepoints-to-string($tail[1])))

        (: [0-9A-Za-z-] :)
        else if (($head ge 48 and $head le 57)
                or ($head ge 65 and $head le 90)
                or ($head ge 97 and $head le 122)
                or ($head eq 45 and not(empty($accum))))
        then
            semver:read-pre-release($tail, (subsequence($accum, 1, count($accum) - 1), $accum[last()] || codepoints-to-string($head)))
        else
            (: skip character :)
            semver:read-pre-release($tail, $accum)
};

(:~ Serialize a SemVer string
 :  @param The major version
 :  @param The minor version
 :  @param The patch version
 :  @param Pre-release identifiers
 :  @param Build identifiers
 :  @return A SemVer string
 :)
declare function semver:serialize($major as xs:integer, $minor as xs:integer, $patch as xs:integer, $pre-release as xs:anyAtomicType*, $build-metadata as xs:anyAtomicType*) {
    let $release := string-join(($major, $minor, $patch), ".")
    let $pre-release := string-join($pre-release ! string(.), ".")
    let $build-metadata := string-join($build-metadata ! string(.), ".")
    let $candidate :=
        $release ||
        (if ($pre-release) then "-" || $pre-release else ()) ||
        (if ($build-metadata) then "+" || $build-metadata else ())
    (: raise an error if the candidate is invalid :)
    let $check := semver:parse($candidate)
    return
        $candidate
};

(:~ Serialize a parsed SemVer string
 :  @param A map containing the components of the SemVer
 :  @return A SemVer string
 :)
declare function semver:serialize($version as map(*)) {
    semver:serialize($version?major, $version?minor, $version?patch, $version?pre-release, $version?build-metadata)
};

(:~ Compare two versions (strictly)
 :  @param A version string
 :  @param A second version string
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare function semver:compare($v1 as xs:string, $v2 as xs:string) as xs:integer {
    let $parsed-v1 := semver:parse($v1)
    let $parsed-v2 := semver:parse($v2)
    return
        semver:compare-parsed($parsed-v1, $parsed-v2)
};

(:~ Compare two versions (with an option to coerce invalid SemVer strings)
 :  @param A version string
 :  @param A second version string
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare function semver:compare($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:integer {
    let $parsed-v1 := semver:parse($v1, $coerce)
    let $parsed-v2 := semver:parse($v2, $coerce)
    return
        semver:compare-parsed($parsed-v1, $parsed-v2)
};

(:~ Test if v1 is a lower version than v2 (strictly)
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is less than v2
 :)
declare function semver:lt($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:lt($v1, $v2, false())
};

(:~ Test if v1 is a lower version than v2 (with an option to coerce invalid SemVer strings)
 :  @param A version string
 :  @param A second version string
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return true if v1 is less than v2
 :)
declare function semver:lt($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) eq -1
};

(:~ Test if v1 is a lower version or the same version as v2 (strictly)
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is less than or equal to v2
 :)
declare function semver:le($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:le($v1, $v2, false())
};

(:~ Test if v1 is a lower version or the same version as v2 (with an option to coerce invalid SemVer strings)
 :  @param A version string
 :  @param A second version string
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return true if v1 is less than or equal to v2
 :)
declare function semver:le($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) = (-1, 0)
};

(:~ Test if v1 is a higher version than v2 (strictly)
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is greater than v2
 :)
declare function semver:gt($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:gt($v1, $v2, false())
};

(:~ Test if v1 is a higher version than v2 (with an option to coerce invalid SemVer strings)
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is greater than v2
 :)
declare function semver:gt($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) eq 1
};

(:~ Test if v1 is the same or higher version than v2 (strictly)
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is greater than or equal to v2
 :)
declare function semver:ge($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:ge($v1, $v2, false())
};

(:~ Test if v1 is the same or higher version than v2
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is greater than or equal to v2
 :)
declare function semver:ge($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) = (1, 0)
};

(:~ Test if v1 is equal to v2
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is equal to v2
 :)
declare function semver:eq($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:compare($v1, $v2) eq 0
};

(:~ Test if v1 is not equal to v2 (strictly)
 :  @param A version string
 :  @param A second version string
 :  @return true if v1 is not equal to v2
 :)
declare function semver:ne($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:ne($v1, $v2, false())
};

(:~ Test if v1 is not equal to v2 (with an option to coerce invalid SemVer strings)
 :  @param A version string
 :  @param A second version string
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return true if v1 is not equal to v2
 :)
declare function semver:ne($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) ne 0
};


(:~ Sort SemVer strings (strictly)
 :  @param A sequence of version strings
 :  @return A sequence of sorted version strings
 :)
declare function semver:sort($versions as xs:string+) as xs:string+ {
    semver:sort($versions, false())
};

(:~ Sort SemVer strings (with an option to coerce invalid SemVer strings)
 :  @param A sequence of version strings
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return A sequence of sorted version strings
 :)
declare function semver:sort($versions as xs:string+, $coerce as xs:boolean) as xs:string+ {
    let $parsed := $versions ! semver:parse(., $coerce)
    (: First, sort versions by major, minor, and patch (using fast standard sort) :)
    let $release-sorted := sort($parsed, (), function($p) { $p?major, $p?minor, $p?patch } )
    (: Second, sort any versions with pre-release fields :)
    let $pre-release-sorted :=
        (: group by major, minor, and patch to limit sorting to like versions :)
        for $p1 in $release-sorted
        group by $major := $p1?major
        order by $major
        return
            for $p2 in $p1
            group by $minor := $p2?minor
            order by $minor
            return
                for $p3 in $p2
                group by $patch := $p3?patch
                let $releases := $p3[?pre-release => array:size() eq 0]
                let $pre-releases := $p3[?pre-release => array:size() gt 0]
                order by $patch
                return
                    (
                        semver:sort-pre-release($pre-releases, ()),
                        (: versions without pre-release metadata take precedence :)
                        $releases
                    )
    for $version in $pre-release-sorted
    return
        semver:serialize($version)
};

(:~ Sort arbitrary items by their SemVer strings (with an option to coerce invalid SemVer strings)
 :  @param A sequence of items to sort
 :  @param A function taking a single parameter used to derive a SemVer string from the item
 :  @param An option for coercing non-SemVer version strings into parsable form
 :  @return The sequence of items in SemVer order
 :)
declare function semver:sort($items as item()*, $function as function(*), $coerce as xs:boolean) as item()* {
    let $items-with-verison := 
        $items !
            map { 
                "item": .,
                "version": $function(.)
            }
    let $sorted-versions := semver:sort($items-with-verison?version, $coerce)
    for $version in $sorted-versions
    return
        $items-with-verison[?version eq $version]?item
};

(:~ Sort pre-release fields
 :  @param The versions to sort
 :  @param An accumulator for sorted versions
 :  @return Sorted versions
 :)
declare %private function semver:sort-pre-release($parsed-versions as map(*)*, $sorted-versions as map(*)*) as map(*)* {
    if (exists($parsed-versions)) then
        let $head := head($parsed-versions)
        let $rest := tail($parsed-versions)
        let $is-largest-pre-release := every $item in $rest?pre-release satisfies semver:compare-pre-release($head?pre-release, $item) = (1, 0)
        return
            if ($is-largest-pre-release) then
                semver:sort-pre-release(tail($parsed-versions), ($head, $sorted-versions))
            else
                semver:sort-pre-release(($rest, $head), $sorted-versions)
    else
        $sorted-versions
};

(:~ Compare two parsed SemVer versions
 :  @param A map containing analysis of a version string
 :  @param A map containing analysis of a second version string
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare %private function semver:compare-parsed($v1 as map(*), $v2 as map(*)) as xs:integer {
    (: Compare major, minor, and patch identifiers :)
    let $release-comparison :=
        semver:compare-release(
            array:subarray($v1?identifiers, 1, 3),
            array:subarray($v2?identifiers, 1, 3)
        )
    return
        switch ($release-comparison)
            case 0 return
                (: When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version. :)
                if (array:size($v1?pre-release) eq 0 and array:size($v2?pre-release) gt 0) then
                    1
                else if (array:size($v1?pre-release) gt 0 and array:size($v2?pre-release) eq 0) then
                    -1
                else
                    (: When major, minor, and patch are equal, compare pre-release :)
                    (: Build metadata SHOULD be ignored when determining version precedence. :)
                    semver:compare-pre-release(
                        $v1?pre-release,
                        $v2?pre-release
                    )
            default return
                $release-comparison
};

declare %private function semver:compare-release($v1 as array(*), $v2 as array(*)) {
    (: No (more) pairs to compare, so the release portions of the two versions are of equal precedence :)
    if (array:size($v1) eq 0 and array:size($v2) eq 0) then
        0
    (: Compare members using numeric operators :)
    else if (array:head($v1) lt array:head($v2)) then
        -1
    else if (array:head($v1) gt array:head($v2)) then
        1
    else
        semver:compare-release(array:tail($v1), array:tail($v2))
};

declare %private function semver:compare-pre-release($v1 as array(*), $v2 as array(*)) {
    (: No (more) pairs to compare, so the two versions are of equal precedence :)
    if (array:size($v1) eq 0 and array:size($v2) eq 0) then
        0
    (: A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal. :)
    else if (array:size($v1) eq 0) then
        -1
    else if (array:size($v2) eq 0) then
        1
    (: Numeric identifiers always have lower precedence than non-numeric identifiers. :)
    else if (array:head($v1) instance of xs:string and array:head($v2) instance of xs:integer) then
        1
    else if (array:head($v1) instance of xs:integer and array:head($v2) instance of xs:string) then
        -1
    (: Compare values using comparison operators :)
    else if (array:head($v1) lt array:head($v2)) then
        -1
    else if (array:head($v1) gt array:head($v2)) then
        1
    (: These identifiers are equal, so recurse to the next pair of identifiers :)
    else
        semver:compare-pre-release(array:tail($v1), array:tail($v2))
};

(:~ Raise a descriptive error
 :  @param An error code
 :  @param The version or identifier that triggered the error
 :  @return The error.
 :)
declare %private function semver:error($code as xs:string, $version as xs:string) {
    let $errors :=
        map {
            "regex-error":
                map {
                    "description": "Version did not match regex for valid semver",
                    "qname": QName("http://joewiz.org/ns/xquery/semver", "regex-error")
                },
            "identifier-error":
                map {
                    "description": "Version identifiers did not conform to semver spec",
                    "qname": QName("http://joewiz.org/ns/xquery/semver", "identifier-error")
                }
        }
    let $error := $errors?($code)
    return
        error($error?qname, $error?description || ": '" || $version || "'")
};
