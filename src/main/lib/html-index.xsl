<?xml version="1.0" encoding="UTF-8"?>
<!-- Generates html index page. Project: xqdoc Author: Andy Bunce Date: 20170101 
	Version: 0.1 Comments: I/p is files e.g <c:directory name="adminlog" xml:base="file:///C:/Users/andy/git/vue-poc/src/vue-poc/features/adminlog/"> 
	<c:file name="logs.xqm"/> -->
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:doc="http://www.xqdoc.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/02/xpath-functions"
                xmlns:qd="http://www.quodatum.com/ns/xsl" exclude-result-prefixes="xs doc fn"
                xmlns:c="http://www.w3.org/ns/xproc-step" version="3.0">
    <xsl:import href="xqdoc.xsl"/>

    <!-- build project index" -->
    <xsl:param name="project" as="xs:string" >?</xsl:param>
    <xsl:param name="ext-id" as="xs:string" >?</xsl:param>
    <xsl:param name="src-folder" as="xs:string" >c:/</xsl:param>
    <!-- relative path to resource files -->
    <xsl:param name="resources" as="xs:string" select="'resources/'" />

    <xsl:variable name="css" select="concat($resources,'base.css')" />

    <xsl:template match="/">
        <html>
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
                <meta http-equiv="Generator"
                      content="xqdoc-r - https://github.com/quodatum/xqdoc-r" />

                <title>
                    <xsl:value-of select="'Index'" />  <xsl:value-of select="$ext-id" />

                    * xqDoc
                </title>
                <xsl:call-template name="resources">
                    <xsl:with-param name="path" select="$resources"/>
                </xsl:call-template>
            </head>

            <body class="home" id="top">
                <div id="main">
                    <h1>
                        <span class="tag tag-success">
                            <xsl:value-of select="$project" />
                        </span>
                        XQDoc ,id: <xsl:value-of select="$ext-id" />
                    </h1>
                    <xsl:call-template name="toc" />
                    <a href="restxq.html">RestXQ</a>
                    <div>src: <xsl:value-of select="$src-folder" /></div>
                    <div id="file">
                        <h1>Files</h1>
                        <ul>
                            <xsl:apply-templates select=".//c:file" />
                        </ul>
                    </div>

                    <div id="ns">
                        <h1>Namespace</h1>
                        <ul>
                            <xsl:for-each select=".//c:file">
                                <xsl:variable name="path" select="resolve-uri(@name,$src-folder)"/>
                                <xsl:variable name="doc" select="doc($path)"/>
                                <li>
                                    <xsl:value-of select="position()"/>
                                    <xsl:value-of select="$path"/>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>

                    <div class="footer">
                        <p style="text-align:right">
                            |
                            generated at
                            <xsl:value-of select="current-dateTime()" />
                        </p>
                    </div>
                </div>

            </body>
        </html>
    </xsl:template>

    <xsl:template match="c:file">
        <xsl:variable name="path" select="string-join(ancestor-or-self::*/@name,'/')"/>
        <li>
            <a href="modules/F{position()}/index.html">
                <xsl:value-of select="qd:path(@name)" />
            </a>

            <xsl:value-of select="position()" />
            <xsl:value-of select="$path" />
        </li>
    </xsl:template>

    <xsl:template name="toc">
        <nav id="toc">
            <h2>
                <a id="contents"></a>
                <span class="tag tag-success">
                    <xsl:value-of select="$project" />
                </span>
            </h2>
            <ol class="toc">
                <li>
                    <a href="#main">
                        <span class="secno">1 </span>
                        <span class="content">Introduction</span>
                    </a>
                </li>
                <li>
                    <a href="#ns">
                        <span class="secno">2 </span>
                        <span class="content">Namespaces</span>
                    </a>
                </li>
                <li>
                    <a href="#file">
                        <span class="secno">3 </span>
                        <span class="content">Files</span>
                    </a>
                </li>
            </ol>
        </nav>
    </xsl:template>


</xsl:stylesheet>
