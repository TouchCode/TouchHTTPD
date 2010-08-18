<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml">
	
	<xsl:output method="xml" version="1.0" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" indent="yes"/>
	
	<xsl:template match="/">
		<html>
			<head>
				<title>Entries</title>
<!-- 
				<link rel="stylesheet" href="/static/NSError.css" type="text/css"/>
 -->
			</head>
			<body>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="entries">
		<table>
			<thead>
				<th>Name</th>
				<th>Kind</th>
				<th>Full Path</th>
			</thead>
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<xsl:template match="entry">
		<tr>
			<td>
				<a>
					<xsl:attribute name="href"><xsl:value-of select="./href" /></xsl:attribute>
					<xsl:value-of select="./name"/>
				</a>
			</td>
			<td>
				<xsl:value-of select="./kind"/>
			</td>
			<td>
				<xsl:value-of select="./path"/>
			</td>
		</tr>
	</xsl:template>

</xsl:stylesheet>
