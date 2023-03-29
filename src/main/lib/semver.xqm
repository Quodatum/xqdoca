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
 :  Additional functions are supplied for handling SemVer templates, as defined 
 :  in the EXPath Package spec.
 :
 :  @author Joe Wicentowski
 :  @see https://semver.org/spec/v2.0.0.html
 :  @see http://expath.org/spec/pkg#pkgdep
 :)

module namespace semver = "http://exist-db.org/xquery/semver";

declare namespace array="http://www.w3.org/2005/xpath-functions/array";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

(:~ A regular expression for validating SemVer strings and parsing valid SemVer strings
 :  
 :  @see https://semver.org/spec/v2.0.0.html#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
 :)
declare variable $semver:regex :=
    (: Start of string :)
    "^"
    (: Major version: A zero for initial development or a non-negative integer without leading zeros :)
    || "(0|[1-9]\d*)"
    (: `.` + Minor version: A zero or a non-negative integer without leading zeros :)
    || "\.(0|[1-9]\d*)"
    (: `.` + Patch version: A zero or a non-negative integer without leading zeros :)
    || "\.(0|[1-9]\d*)"
    (: `-` + Pre-release metadata (optional): A series of dot separated, non-empty identifiers, comprised only of ASCII alphanumerics and hyphens [0-9A-Za-z-] :)
    || "(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
    (: `+` + Build metadata (optional): A series of dot separated, non-empty identifiers, comprised only of ASCII alphanumerics and hyphens [0-9A-Za-z-] :)
    || "(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
    (: End of string :)
    || "$"
;

(:~ A forgiving regular expression for capturing groups needed to coerce a non-SemVer string into SemVer components :)
declare variable $semver:coerce-regex := 
    (: Start of string :)
    "^"
    (: Major version: One or more characters that are not `-`, `+`, or `.` :)
    || "([^-+.]+?)"
    (: `.` + Minor version: One or more characters that are not `-`, `+`, or `.` :)
    || "(?:\.([^-+.]+?))?"
    (: `.` + Patch version: One or more characters that are not `-`, `+`, or `.` :)
    || "(?:\.([^-+.]+?))?"
    (: `-` + Pre-release metadata (optional): One or more characters that are not `+` :)
    || "(?:-([^+]+?))?"
    (: `+` + Build metadata (optional): One or more characters :)
    || "(?:\+(.+))?"
    (: End of string :)
    || "$";

(:~ A regular expression for validating SemVer templates as defined in the EXPath Package spec
 :  
 :  @see http://expath.org/spec/pkg#pkgdep
 :)
declare variable $semver:expath-package-semver-template-regex :=
    (: Start of string :)
    "^"
    (: Major version: A zero for initial development or a non-negative integer without leading zeros :)
    || "(0|[1-9]\d*)"
    (: `.` + Minor version: Empty for a major version template, or a zero or a non-negative integer without leading zeros for a minor version template :)
    || "(?:\.(0|[1-9]\d*))?"
    (: End of string :)
    || "$";

(:~ Validate whether a SemVer string conforms to the spec
 :  
 :  @param $version A version string
 :  @return True if the version is valid, false if not
 :)
declare function semver:validate($version as xs:string) as xs:boolean {
    matches($version, $semver:regex)
};

(:~ Validate whether a version string conforms to the rules for SemVer templates as defined in the EXPath Package spec
 :  
 :  @param $version A version string
 :  @return True if the version is an SemVer template, false if not
 :)
declare function semver:validate-expath-package-semver-template($version as xs:string) as xs:boolean {
    matches($version, $semver:expath-package-semver-template-regex)
};

(:~ Parse a SemVer string (strictly)
 :  
 :  @param $version A version string
 :  @return A map containing analysis of the parsed version, with entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :  @error regex-error
 :  @error identifier-error
 :)
declare function semver:parse($version as xs:string) as map(*) {
    semver:parse($version, false())
};

(:~ Parse a SemVer string (with an option to coerce invalid SemVer strings)
 :  
 :  @param $version A version string
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return A map containing analysis of the parsed SemVer versions, with entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :  @error regex-error
 :  @error identifier-error
 :)
declare function semver:parse($version as xs:string, $coerce as xs:boolean) as map(*) {
    let $analysis := analyze-string($version, $semver:regex)
    let $groups := $analysis/fn:match/fn:group
    return
        if (empty($groups)) then
            if ($coerce) then 
                semver:coerce($version)
            else
                semver:error("identifier-error", $version)
        else
            let $release-identifiers := subsequence($groups, 1, 3) ! semver:cast-identifier(.)
            (: Groups 4 and 5 are optional and so must be selected by @nr rather than position :)
            let $pre-release-identifiers := array { $groups[@nr eq "4"] ! tokenize(., "\.") ! semver:cast-identifier(.) }
            let $build-metadata-identifiers := array { $groups[@nr eq "5"] ! tokenize(., "\.") ! semver:cast-identifier(.) }
            return
                map {
                    "major": $release-identifiers[1],
                    "minor": $release-identifiers[2],
                    "patch": $release-identifiers[3],
                    "pre-release": $pre-release-identifiers,
                    "build-metadata": $build-metadata-identifiers
                }
                => semver:populate-identifiers()
};

(:~ Coerce a non-SemVer version string into a SemVer string and parse it as such
 :  
 :  @param $version A version string which will be coerced into a parsed SemVer version
 :  @return A map containing analysis of the coerced version, with entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array. Fallback for invalid version strings: 0.0.0.
 :)
declare function semver:coerce($version as xs:string) as map(*) {
    let $analysis := analyze-string($version, $semver:coerce-regex)
    let $groups := $analysis/fn:match/fn:group
    let $release-identifiers := $groups[@nr = ("1", "2", "3")] ! replace(., "\D+", "") ! semver:cast-identifier(.)
    let $pre-release-identifiers := array { $groups[@nr eq "4"] ! tokenize(., "\.") ! semver:cast-identifier(.) }
    let $build-metadata-identifiers := array { $groups[@nr eq "5"] ! tokenize(., "\.") ! semver:cast-identifier(.) }
    return
        map {
            "major": if ($release-identifiers[1] instance of xs:integer) then $release-identifiers[1] else 0,
            "minor": if ($release-identifiers[2] instance of xs:integer) then $release-identifiers[2] else 0,
            "patch": if ($release-identifiers[3] instance of xs:integer) then $release-identifiers[3] else 0,
            "pre-release": $pre-release-identifiers,
            "build-metadata": $build-metadata-identifiers
        }
        => semver:populate-identifiers()
};

(:~ Resolve an EXPath Package SemVer Template as minimum (floor)
 :  
 :  @param $version An EXPath SemVer Template
 :  @return A map containing the resolved version, with entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :)
declare function semver:resolve-expath-package-semver-template-min($version as xs:string) as map(*) {
    semver:resolve-expath-package-semver-template($version, "min")
};

(:~ Resolve an EXPath Package SemVer Template as maximum (ceiling)
 :  
 :  @param $version An EXPath SemVer Template
 :  @return A map containing the resolved version, with entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :)
declare function semver:resolve-expath-package-semver-template-max($version as xs:string) as map(*)  {
    semver:resolve-expath-package-semver-template($version, "max")
};

(:~ Resolve an EXPath SemVer Package Template
 :  
 :  @param $version An EXPath Package SemVer Template
 :  @param $mode Mode for resolving the template: "min" (floor) or "max" (ceiling)
 :  @return A map containing the resolved version, with entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array.
 :)
declare function semver:resolve-expath-package-semver-template($version as xs:string, $mode as xs:string) {
    let $analysis := analyze-string($version, $semver:expath-package-semver-template-regex)
    let $groups := $analysis/fn:match/fn:group
    return
        if (empty($groups)) then 
            semver:error("template-error", $version)
        else
            let $release-identifiers := $groups[@nr = ("1", "2", "3")] ! replace(., "\D+", "")[. ne ""] ! semver:cast-identifier(.)
            let $major := if ($release-identifiers[1] instance of xs:integer) then $release-identifiers[1] else 0
            let $minor := if ($release-identifiers[2] instance of xs:integer) then $release-identifiers[2] else 0
            let $is-major-version-template := empty($release-identifiers[2])
            return
                if ($is-major-version-template) then
                    map {
                        "major": if ($mode eq "min") then $major else $major + 1,
                        "minor": 0,
                        "patch": 0,
                        "pre-release": [],
                        "build-metadata": []
                    }
                    => semver:populate-identifiers()
                else (: if ($is-minor-version-template) then :)
                    map {
                        "major": $major,
                        "minor": if ($mode eq "min") then $minor else $minor + 1,
                        "patch": 0,
                        "pre-release": [],
                        "build-metadata": []
                    }
                    => semver:populate-identifiers()
};

(:~ Check if a version satisfies EXPath Package dependency versioning attributes.
 :  
 :  @param $version A version string
 :  @param $versions An EXPath Package "versions" versioning attribute
 :  @param $semver An EXPath Package "semver" versioning attribute
 :  @param $semver-min An EXPath Package "semver-min" versioning attribute
 :  @param $semver-min An EXPath Package "semver-max" versioning attribute
 :  @return True if the version satisfies the attributes, or false if not
 :)
declare function semver:satisfies-expath-package-dependency-versioning-attributes(
    $version as xs:string, 
    $versions as xs:string?, 
    $semver as xs:string?, 
    $semver-min as xs:string?, 
    $semver-max as xs:string?
) as xs:boolean {
    (: "If the versions attribute is used, it defines the exact set of acceptable versions 
     : for the secondary package, separated by spaces." :)
    let $satisfies-versions :=
        if (empty($versions)) then
            false()
        else
            $version = tokenize($versions)
    (: Parse the version and evaluate the remaining versioning attributes, accounting for the possibility 
     : that they may be EXPath Package SemVer templates. :)
    let $version-parsed := semver:parse($version, true())
    let $satisfies-semver := 
        if (empty($semver)) then
            false()
        (: If semver is a template, resolve it into max and min versions :)
        else if (semver:validate-expath-package-semver-template($semver)) then
            semver:ge-parsed(
                $version-parsed,
                semver:resolve-expath-package-semver-template-min($semver)
            )
            and
            semver:lt-parsed(
                (: Disregard the pre-release identifier when comparing against EXPath Package SemVer 
                 : templates :)
                if (array:size($version-parsed?pre-release) gt 0) then
                    map:put($version-parsed, "pre-release", [])
                else
                    $version-parsed,
                semver:resolve-expath-package-semver-template-max($semver)
            )
        else
            semver:eq($version, $semver, true())
    let $satisfies-semver-min :=
        if (empty($semver-min)) then
            false()
        else if (semver:validate-expath-package-semver-template($semver-min)) then
            semver:ge-parsed(
                $version-parsed, 
                semver:resolve-expath-package-semver-template-min($semver-min)
            )
        else
            semver:ge($version, $semver-min, true())
    let $satisfies-semver-max := 
        if (empty($semver-max)) then
            false()
        else if (semver:validate-expath-package-semver-template($semver-max)) then
            semver:lt-parsed(
                (: Disregard the pre-release identifier when comparing against EXPath Package SemVer 
                 : templates :)
                if (array:size($version-parsed?pre-release) gt 0) then
                    map:put($version-parsed, "pre-release", [])
                else
                    $version-parsed,
                semver:resolve-expath-package-semver-template-max($semver-max)
            )
        else
            semver:lt($version, $semver-max, true())
    return
        $satisfies-versions 
        or $satisfies-semver 
        or (
            if (exists($semver-min) and exists($semver-max)) then
                $satisfies-semver-min and $satisfies-semver-max
            else if (exists($semver-min)) then
                $satisfies-semver-min
            else if (exists($semver-max)) then
                $satisfies-semver-max
            else
                false()
        )
};

(:~ Serialize a SemVer string
 :  
 :  @param $major The major version
 :  @param $minor The minor version
 :  @param $patch The patch version
 :  @param $pre-release Pre-release identifiers
 :  @param $build-metadata Build identifiers
 :  @return A SemVer string
 :)
declare function semver:serialize(
    $major as xs:integer, 
    $minor as xs:integer, 
    $patch as xs:integer, 
    $pre-release as xs:anyAtomicType*, 
    $build-metadata as xs:anyAtomicType*
) {
    let $release := string-join(($major, $minor, $patch), ".")
    let $pre-release := string-join($pre-release ! string(.), ".")
    let $build-metadata := string-join($build-metadata ! string(.), ".")
    let $candidate :=
        $release
        || (if ($pre-release) then "-" || $pre-release else ())
        || (if ($build-metadata) then "+" || $build-metadata else ())
    (: Raise an error if the candidate is invalid :)
    let $check := semver:parse($candidate)
    return
        $candidate
};

(:~ Serialize a parsed SemVer version
 :  
 :  @param $parsed-version A map containing the components of the SemVer string
 :  @return A SemVer string
 :  @deprecated As of 2.4.0 replace with serialize-parsed
 :)
declare function semver:serialize($parsed-version as map(*)) {
    semver:serialize-parsed($parsed-version)
};

(:~ Serialize a parsed SemVer version
 :  
 :  @param $parsed-version A map containing the components of the SemVer string
 :  @return A SemVer string
 :)
declare function semver:serialize-parsed($parsed-version as map(*)) {
    semver:serialize(
        $parsed-version?major, 
        $parsed-version?minor, 
        $parsed-version?patch, 
        $parsed-version?pre-release, 
        $parsed-version?build-metadata
    )
};

(:~ Compare two versions (strictly)
 :  
 :  @param $parsed-v1 A version string
 :  @param $parsed-v2 A second version string
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare function semver:compare($v1 as xs:string, $v2 as xs:string) as xs:integer {
    let $parsed-v1 := semver:parse($v1)
    let $parsed-v2 := semver:parse($v2)
    return
        semver:compare-parsed($parsed-v1, $parsed-v2)
};

(:~ Compare two versions (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare function semver:compare($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:integer {
    let $parsed-v1 := semver:parse($v1, $coerce)
    let $parsed-v2 := semver:parse($v2, $coerce)
    return
        semver:compare-parsed($parsed-v1, $parsed-v2)
};

(:~ Compare two parsed SemVer versions
 :  
 :  @param $parsed-v1 A map containing analysis of a version string
 :  @param $parsed-v2 A map containing analysis of a second version string
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare function semver:compare-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:integer {
    (: Compare major, minor, and patch identifiers :)
    let $release-comparison :=
        semver:compare-release(
            array:subarray($parsed-v1?identifiers, 1, 3),
            array:subarray($parsed-v2?identifiers, 1, 3)
        )
    return
        switch ($release-comparison)
            case 0 return
                (: When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version. :)
                if (array:size($parsed-v1?pre-release) eq 0 and array:size($parsed-v2?pre-release) gt 0) then
                    1
                else if (array:size($parsed-v1?pre-release) gt 0 and array:size($parsed-v2?pre-release) eq 0) then
                    -1
                else
                    (: When major, minor, and patch are equal, compare pre-release :)
                    (: Build metadata SHOULD be ignored when determining version precedence. :)
                    semver:compare-pre-release(
                        $parsed-v1?pre-release,
                        $parsed-v2?pre-release
                    )
            default return
                $release-comparison
};

(:~ Test if v1 is a lower version than v2 (strictly)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is less than v2
 :)
declare function semver:lt($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:lt($v1, $v2, false())
};

(:~ Test if v1 is a lower version than v2 (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return true if v1 is less than v2
 :)
declare function semver:lt($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) eq -1
};

(:~ Test if a parsed v1 is a lower version than a parsed v2
 :  
 :  @param $parsed-v1 A parsed Semver version
 :  @param $parsed-v2 A second parsed Semver version
 :  @return true if v1 is less than v2
 :)
declare function semver:lt-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:boolean {
    semver:compare-parsed($parsed-v1, $parsed-v2) eq -1
};

(:~ Test if v1 is a lower version or the same version as v2 (strictly)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is less than or equal to v2
 :)
declare function semver:le($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:le($v1, $v2, false())
};

(:~ Test if v1 is a lower version or the same version as v2 (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return true if v1 is less than or equal to v2
 :)
declare function semver:le($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) le 0
};

(:~ Test if a parsed v1 is a lower version or the same version as a parsed v2
 :  
 :  @param $parsed-v1 A parsed Semver version
 :  @param $parsed-v2 A second parsed Semver version
 :  @return true if v1 is less than or equal to v2
 :)
declare function semver:le-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:boolean {
    semver:compare-parsed($parsed-v1, $parsed-v2) le 0
};

(:~ Test if v1 is a higher version than v2 (strictly)
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is greater than v2
 :)
declare function semver:gt($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:gt($v1, $v2, false())
};

(:~ Test if v1 is a higher version than v2 (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is greater than v2
 :)
declare function semver:gt($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) eq 1
};

(:~ Test if a parsed v1 is a higher version than a parsed v2
 :  
 :  @param $parsed-v1 A parsed Semver version
 :  @param $parsed-v2 A second parsed Semver version
 :  @return true if v1 is greater than v2
 :)
declare function semver:gt-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:boolean {
    semver:compare-parsed($parsed-v1, $parsed-v2) eq 1
};

(:~ Test if v1 is the same or higher version than v2 (strictly)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is greater than or equal to v2
 :)
declare function semver:ge($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:ge($v1, $v2, false())
};

(:~ Test if v1 is the same or higher version than v2 (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is greater than or equal to v2
 :)
declare function semver:ge($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) ge 0
};

(:~ Test if a parsed v1 is the same or higher version than a parsed v2
 :  
 :  @param $parsed-v1 A parsed Semver version
 :  @param $parsed-v2 A second parsed Semver version
 :  @return true if v1 is greater than or equal to v2
 :)
declare function semver:ge-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:boolean {
    semver:compare-parsed($parsed-v1, $parsed-v2) ge 0
};

(:~ Test if v1 is equal to v2 (strictly)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is equal to v2
 :)
declare function semver:eq($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:compare($v1, $v2) eq 0
};

(:~ Test if v1 is equal to v2 (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is equal to v2
 :)
declare function semver:eq($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2) eq 0
};

(:~ Test if a parsed v1 is equal to a parsed v2
 :  
 :  @param $parsed-v1 A parsed Semver version
 :  @param $parsed-v2 A second parsed Semver version
 :  @return true if v1 is equal to v2
 :)
declare function semver:eq-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:boolean {
    semver:compare-parsed($parsed-v1, $parsed-v2) eq 0
};

(:~ Test if v1 is not equal to v2 (strictly)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @return true if v1 is not equal to v2
 :)
declare function semver:ne($v1 as xs:string, $v2 as xs:string) as xs:boolean {
    semver:ne($v1, $v2, false())
};

(:~ Test if v1 is not equal to v2 (with an option to coerce invalid SemVer strings)
 :  
 :  @param $v1 A version string
 :  @param $v2 A second version string
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return true if v1 is not equal to v2
 :)
declare function semver:ne($v1 as xs:string, $v2 as xs:string, $coerce as xs:boolean) as xs:boolean {
    semver:compare($v1, $v2, $coerce) ne 0
};

(:~ Test if a parsed v1 is not equal to a parsed v2
 :  
 :  @param $parsed-v1 A parsed Semver version
 :  @param $parsed-v2 A second parsed Semver version
 :  @return true if v1 is not equal to v2
 :)
declare function semver:ne-parsed($parsed-v1 as map(*), $parsed-v2 as map(*)) as xs:boolean {
    semver:compare-parsed($parsed-v1, $parsed-v2) ne 0
};

(:~ Compare release identifiers
 :  
 :  @param $v1 An array of release identifiers
 :  @param $v2 A second array of release identifiers
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare %private function semver:compare-release($v1-release-ids as array(*), $v2-release-ids as array(*)) {
    (: No (more) pairs to compare, so the release portions of the two versions are of equal precedence :)
    if (array:size($v1-release-ids) eq 0 and array:size($v2-release-ids) eq 0) then
        0
    (: Compare members using numeric operators :)
    else if (array:head($v1-release-ids) lt array:head($v2-release-ids)) then
        -1
    else if (array:head($v1-release-ids) gt array:head($v2-release-ids)) then
        1
    else
        semver:compare-release(array:tail($v1-release-ids), array:tail($v2-release-ids))
};

(:~ Compare pre-release identifiers
 :  
 :  @param $v1 An array of pre-release identifiers
 :  @param $v2 A second array of pre-release identifiers
 :  @return -1 if v1 < v2, 0 if v1 = v2, or 1 if v1 > v2.
 :)
declare %private function semver:compare-pre-release($v1-pre-release-ids as array(*), $v2-pre-release-ids as array(*)) {
    (: No (more) pairs to compare, so the two versions are of equal precedence :)
    if (array:size($v1-pre-release-ids) eq 0 and array:size($v2-pre-release-ids) eq 0) then
        0
    (: A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal. :)
    else if (array:size($v1-pre-release-ids) eq 0) then
        -1
    else if (array:size($v2-pre-release-ids) eq 0) then
        1
    (: Numeric identifiers always have lower precedence than non-numeric identifiers. :)
    else if (array:head($v1-pre-release-ids) instance of xs:string and array:head($v2-pre-release-ids) instance of xs:integer) then
        1
    else if (array:head($v1-pre-release-ids) instance of xs:integer and array:head($v2-pre-release-ids) instance of xs:string) then
        -1
    (: Compare values using comparison operators :)
    else if (array:head($v1-pre-release-ids) lt array:head($v2-pre-release-ids)) then
        -1
    else if (array:head($v1-pre-release-ids) gt array:head($v2-pre-release-ids)) then
        1
    (: These identifiers are equal, so recurse to the next pair of identifiers :)
    else
        semver:compare-pre-release(array:tail($v1-pre-release-ids), array:tail($v2-pre-release-ids))
};

(:~ Sort SemVer strings (strictly)
 :  
 :  @param $versions A sequence of version strings
 :  @return A sequence of sorted version strings
 :)
declare function semver:sort($versions as xs:string+) as xs:string+ {
    semver:sort($versions, false())
};

(:~ Sort SemVer strings (with an option to coerce invalid SemVer strings)
 :  
 :  @param $versions A sequence of version strings
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return A sequence of sorted version strings
 :)
declare function semver:sort($versions as xs:string*, $coerce as xs:boolean) as xs:string* {
    let $parsed := $versions ! semver:parse(., $coerce)
    let $sorted := semver:sort-parsed($parsed)
    for $s in $sorted
    return
        semver:serialize($s)
};

(:~ Sort arbitrary items by their SemVer strings (with an option to coerce invalid SemVer strings)
 :  @param $items A sequence of items to sort
 :  @param $function A function taking a single parameter used to derive a SemVer string from the item
 :  @param $coerce An option for coercing non-SemVer version strings into parsable form
 :  @return The sequence of items in SemVer order
 :)
declare function semver:sort($items as item()*, $function as function(*), $coerce as xs:boolean) as item()* {
    let $items-with-version :=
        for $item in $items
        let $version-string := $function($item)
        let $parsed-version := semver:parse($version-string, $coerce)
        return
            map {
                "item": $item,
                "version-string": $version-string,
                "parsed-version": $parsed-version
            }
    let $sorted-versions := semver:sort-parsed($items-with-version?parsed-version)
    for $sorted-version in $sorted-versions
    for $item-with-version in $items-with-version
    where semver:eq-parsed($item-with-version?parsed-version, $sorted-version)
    return
        $item-with-version?item
};

(:~ Sort SemVer maps
 :  @param $parsed-versions A sequence of SemVer maps, containing entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array
 :  @return A sorted sequence of SemVer maps, containing entries for each identifier ("major", "minor", "patch", "pre-release", and "build-metadata"), and an "identifiers" entry with all identifiers in an array
 :)
declare function semver:sort-parsed($parsed-versions as map(*)*) as map(*)* {
    (: First, sort versions by major, minor, and patch (using fast standard sort) :)
    let $release-sorted := fn:sort($parsed-versions, (), function($p) { $p?major, $p?minor, $p?patch } )
    return
        (: Second, sort any versions with pre-release fields,
           then group by major, minor, and patch to limit sorting to like versions :)
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
                        (: Versions without pre-release metadata take precedence :)
                        $releases
                    )
};

(:~ Sort pre-release fields
 :  
 :  @param $parsed-versions The versions to sort
 :  @param $sorted-versions An accumulator for sorted versions
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

(:~ Raise a descriptive error
 :  
 :  @param $code An error code
 :  @param $version The version or identifier that triggered the error
 :  @return The error.
 :)
declare %private function semver:error($code as xs:string, $version as xs:string) {
    let $errors :=
        map {
            "regex-error":
                map {
                    "description": "Version did not match the regular expression for valid SemVer",
                    "qname": QName("http://joewiz.org/ns/xquery/semver", "regex-error")
                },
            "identifier-error":
                map {
                    "description": "Version identifiers did not conform to SemVer spec",
                    "qname": QName("http://joewiz.org/ns/xquery/semver", "identifier-error")
                },
            "template-error":
                map {
                    "description": "Template did not conform to the EXPath Package spec for SemVer templates",
                    "qname": QName("http://joewiz.org/ns/xquery/semver", "template-error")
                }
        }
    let $error := $errors?($code)
    return
        error($error?qname, $error?description || ": '" || $version || "'")
};

(:~ A utility function for casting identifiers to the appropriate types
 :  
 :  @param $identifier An identifier
 :  return The identifier unchanged or cast as an integer
 :)
declare %private function semver:cast-identifier($identifier as xs:string) as xs:anyAtomicType {
    if ($identifier castable as xs:integer) then
        $identifier cast as xs:integer
    else
        $identifier
};

(:~ A utility function for populating the identifiers entry in a parsed version
 :  
 :  @param $parsed-version A map containing analysis of a version string
 :  return The map with an identifiers entry
 :)
declare %private function semver:populate-identifiers($parsed-version as map(*)) as map(*) {
    $parsed-version
    => map:put("identifiers", [ $parsed-version?major, $parsed-version?minor, $parsed-version?patch, $parsed-version?pre-release, $parsed-version?build-metadata ])
};
