<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml">
	
	<xsl:output method="xml" version="1.0" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" indent="yes"/>
	
	<xsl:template match="/">
		<html>
			<head>
				<title>NSError</title>
				<link rel="stylesheet" href="/static/NSError.css" type="text/css"/>
			</head>
			<body>
				<p>An error occured while processing this request.</p>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="NSUnderlyingErrorKey">
		<table>
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<xsl:template match="NSError">
		<table>
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<xsl:template match="domain|code">
		<tr>
			<td><xsl:value-of select="name()"/></td><td><xsl:value-of select="."/></td>
		</tr>
	</xsl:template>

	<xsl:template match="*">
		<tr>
			<td><xsl:value-of select="name()"/></td><td><xsl:apply-templates/></td>
		</tr>
	</xsl:template>

</xsl:stylesheet>
