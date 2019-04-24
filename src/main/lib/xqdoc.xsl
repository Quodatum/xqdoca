<?xml version="1.0" encoding="UTF-8"?>
<!-- shared module for xqdoc -->
<xsl:stylesheet version="3.0" 
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:doc="http://www.xqdoc.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:qd="http://www.quodatum.com/ns/xsl" exclude-result-prefixes="xs doc">
        
	<xsl:template name="resources">
	     <xsl:param name="path" />
				<link rel="shortcut icon" type="image/x-icon" href="{$path}xqdoc.png"/>
				<link rel="stylesheet" type="text/css" href="{$path}prism.css"/>
				<link rel="stylesheet" type="text/css" href="{$path}page.css"/>
				<link rel="stylesheet" type="text/css" href="{$path}query.css"/>
				<link rel="stylesheet" type="text/css" href="{$path}base.css"/>
				<style>
				.tag {font-size: 100%;}
				</style>
				  <script src="{$path}prism.js" type="text/javascript">&#160;</script>
	</xsl:template>
	
	<!-- path -->
  <xsl:function name="qd:path" as="xs:string">
    <xsl:param name="file" />
    <xsl:sequence select="concat('*',$file)" />
  </xsl:function>
  
  <!-- link to namespace -->
  <xsl:function name="qd:nslink" as="element(a)">
    <xsl:param name="ns" as="xs:string"/>
    <a href="imports.html#{ $ns }"><xsl:value-of select="$ns"/></a>
  </xsl:function>  
</xsl:stylesheet>