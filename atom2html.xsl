<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY nbsp "&#160;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atom="http://www.w3.org/2005/Atom" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:output method="html" encoding="utf-8" indent="yes" doctype-system="about:legacy-compat"/>
	<xsl:variable name="base" select="/atom:feed/atom:link/@href"/>
	<xsl:variable name="base_len" select="string-length($base)"/>
	<xsl:variable name="lazyblog-url" select="/processing-instruction('lazyblog-url')"/>
	<xsl:variable name="lang" select="document(concat($lazyblog-url, '/lang-', /atom:feed/@xml:lang, '.xml'))/*"/>
	<xsl:variable name="uniq_tags" select="/atom:feed/atom:entry/atom:category[not(@term=preceding::*/@term)]"/>
	<xsl:template match="/">
		<html>
			<xsl:attribute name="lang">
				<xsl:value-of select="/atom:feed/@xml:lang"/>
			</xsl:attribute>
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
				<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
				<title>
					<xsl:value-of select="/atom:feed/atom:title"/>
				</title>
				<style>
					html {color-scheme: light dark}
					@view-transition { navigation: auto; }
					body {
					margin: auto;
					max-width: 80ex;
					padding: 1ex; /* for 📱 users*/
					}
					header a, footer a, small a {color: inherit !important} /* linktext */
					a.title {font-size:larger; font-weight: bolder}
					main small {display: block}
					.intro {margin-top: 1em; margin-bottom: 1em} /* can be replaced with two empty divs */
					.intro div {display: inline}
				</style>
				<link rel="canonical">
					<xsl:attribute name="href">
						<xsl:value-of select="/atom:feed/atom:link[@rel='self']/@href"/>
					</xsl:attribute>
				</link>
				<link rel="alternate" type="application/atom+xml">
					<xsl:attribute name="href">
						<xsl:value-of select="/atom:feed/atom:link[@rel='self']/@href"/>
					</xsl:attribute>
				</link>
			</head>
			<body>
				<small style="float:right">
					<i>
						<xsl:value-of select="$lang/header/last-update"/>
						<time>
							<xsl:attribute name="datetime">
								<xsl:value-of select="/atom:feed/atom:updated"/>
							</xsl:attribute>
						<xsl:value-of select="translate(substring(/atom:feed/atom:updated, 0, 20), 'T', ' ')"/>
						<xsl:text> UTC</xsl:text>
						</time>
					</i>
				</small>
				<header>
					<h1 style="border-bottom: 1px solid #8888">
						<xsl:value-of select="/atom:feed/atom:title"/>
						<small style="font: initial;margin-left: 3.5em">
							<xsl:value-of select="/atom:feed/atom:subtitle"/>
						</small>
					</h1>
					<nav>
						<xsl:value-of select="$lang/header/links"/>
						<xsl:for-each select="/atom:feed/atom:link[@rel='related']">
							<a>
								<xsl:attribute name="href">
									<xsl:value-of select="@href"/>
								</xsl:attribute>
								<xsl:value-of select="@title"/>
							</a>
							<xsl:if test="position()!=last()">, </xsl:if>
						</xsl:for-each>
					</nav>
					<hr/>
					<div id="filter" style="margin-top: 1em">
						<xsl:value-of select="$lang/filter/by-tags"/>
						<div style="text-align: justify;">
							<span id="tags">
								<xsl:for-each select="$uniq_tags">
									<xsl:sort select="@term"/>
									<xsl:variable name="term" select="@term"/>
									<xsl:call-template name="tag">
										<xsl:with-param name="tag" select="@term"/>
										<xsl:with-param name="count" select="count(/atom:feed/atom:entry/atom:category[@term=$term])"/>
									</xsl:call-template>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</span>
						</div>
						<p>
							<a id="showall" href="#" style="float:right;margin-left:1ex">
								<xsl:value-of select="$lang/filter/show-all/pre"/>
								<xsl:value-of select="count(/atom:feed/atom:entry)"/>
								<xsl:value-of select="$lang/filter/show-all/post"/>
							</a>
						</p>
						<p>
							<label>
								<xsl:value-of select="$lang/filter/by-search"/>
								<input type="search" id="search">
									<xsl:attribute name="placeholder">
										<xsl:value-of select="normalize-space($lang/filter/search-placeholder)"/>
									</xsl:attribute>
								</input>
							</label>
						</p>
						<hr/>
					</div>
				</header>
				<main>
					<ol style="padding-left:0px">
						<xsl:for-each select="/atom:feed/atom:entry">
							<xsl:sort select="atom:published" order="descending"/>
							<li>
								<xsl:call-template name="entry">
									<xsl:with-param name="entry" select="."/>
								</xsl:call-template>
							</li>
						</xsl:for-each>
					</ol>
				</main>
				<script> <!-- same stuff, just for scripts -->
					var tags_count={
					<xsl:for-each select="$uniq_tags">
						<xsl:variable name="term" select="@term"/>
						'<xsl:value-of select="@term"/>':
						<xsl:value-of select="count(/atom:feed/atom:entry/atom:category[@term=$term])"/>,
					</xsl:for-each>
					};
					var tags=Object.keys(tags_count).sort();
					var posts=[
					<xsl:for-each select="/atom:feed/atom:entry">
						<xsl:sort select="atom:published" order="descending"/>
						{
						'created': '<xsl:value-of select="substring(atom:published, 0,11)"/>',
						'tags':[
						<xsl:for-each select="atom:category">
							'<xsl:value-of select="@term"/>',
						</xsl:for-each>
						]
						},
					</xsl:for-each>
					];
				</script>
				<script>
					<xsl:attribute name="src">
						<xsl:value-of select="$lazyblog-url"/>
						<xsl:text>/script.js</xsl:text>
					</xsl:attribute>
				</script>
				<footer style="text-align: center">
					<hr/>
					<p>
						<xsl:call-template name="rights">
							<xsl:with-param name="rights" select="/atom:feed/atom:rights"/>
						</xsl:call-template>
						<xsl:text> </xsl:text>
						<a>
							<xsl:attribute name="href">
								<xsl:value-of select="/atom:feed/atom:author/atom:uri"/>
							</xsl:attribute>
							<xsl:value-of select="/atom:feed/atom:author/atom:name"/>
						</a>
						<xsl:value-of select="$lang/footer/sep"/>
						<a id="email" href="javascript:(l=document.getElementById('email')).href='mailto:'+(l.innerHTML=location.hostname.replace('.','@'));void 0">
							<xsl:value-of select="$lang/footer/show-email"/>
						</a>
						<!--
					<small style="display:block">
						<xsl:value-of select="$lang/footer/generator"/>
						<a>
							<xsl:attribute name="href">
								<xsl:value-of select="/atom:feed/atom:generator/@uri"/>
							</xsl:attribute>
							<xsl:value-of select="/atom:feed/atom:generator"/>
						</a>
					</small>
					-->
					</p>
				</footer>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="entry">
		<xsl:param name="entry"/>
		<xsl:variable name="relative_url" select="substring($entry/atom:link/@href, $base_len+1)"/>
		<xsl:variable name="name_only" select="substring($relative_url, 0, string-length($relative_url)-string-length('.html')+1)"/>
			<a class="title">
				<xsl:call-template name="view-transition-name">
					<xsl:with-param name="name" select="$name_only"/>
					<xsl:with-param name="type">title</xsl:with-param>
				</xsl:call-template>
				<xsl:attribute name="href">
					<xsl:value-of select="$relative_url"/>
				</xsl:attribute>
				<xsl:value-of select="$entry/atom:title"/>
			</a>
			<small>
				<xsl:call-template name="view-transition-name">
					<xsl:with-param name="name" select="$name_only"/>
					<xsl:with-param name="type">small</xsl:with-param>
				</xsl:call-template>
				<xsl:value-of select="$lang/small/published"/>
				<time>
					<xsl:value-of select="substring($entry/atom:published, 0,11)"/>
				</time>
				<xsl:value-of select="$lang/small/sep"/>
				<xsl:value-of select="$lang/small/updated"/>
				<time>
					<xsl:attribute name="datetime">
						<xsl:value-of select="$entry/atom:updated"/>
					</xsl:attribute>
					<xsl:value-of select="substring($entry/atom:updated, 0,11)"/>
				</time>
				<xsl:value-of select="$lang/small/sep"/>
				<xsl:value-of select="$lang/small/tags"/>
				<xsl:for-each select="$entry/atom:category">
					<xsl:call-template name="tag">
						<xsl:with-param name="tag" select="@term"/>
					</xsl:call-template>
					<xsl:if test="position()!=last()">, </xsl:if>
				</xsl:for-each>
			</small>
			<!-- <div>&#38;nbsp;</div> <!&#45;&#45; gap  &#45;&#45;> -->
			<div class="intro">
				<xsl:call-template name="view-transition-name">
					<xsl:with-param name="name" select="$name_only"/>
					<xsl:with-param name="type">intro</xsl:with-param>
				</xsl:call-template>
					<xsl:copy-of select="$entry/atom:content/*"/>
				<xsl:value-of select="$lang/read-more/sep"/>
				<a>
					<xsl:attribute name="href">
						<xsl:value-of select="$relative_url"/>
					</xsl:attribute>
					<xsl:value-of select="$lang/read-more/text"/>
				</a>
			</div>
			<!-- <div>&#38;nbsp;</div> <!&#45;&#45; gap  &#45;&#45;> -->
	</xsl:template>

	<xsl:template name="rights">
		<xsl:param name="rights"/>
		<xsl:variable name="http">
			<xsl:if test="contains($rights, 'http')">
				<xsl:value-of select="normalize-space(concat('http', substring-after($rights, 'http')))"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="details">
			<xsl:call-template name="string-between">
				<xsl:with-param name="str" select="$rights"/>
				<xsl:with-param name="left" select="'('"/>
				<xsl:with-param name="right" select="')'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="short">
			<xsl:choose>
				<xsl:when test="$details">
					<xsl:value-of select="normalize-space(substring-before($rights, '('))"/>
				</xsl:when>
				<xsl:when test="$http">
					<xsl:value-of select="normalize-space(substring-before($rights, 'http'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$rights"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<a>
			<xsl:if test="$http">
				<xsl:attribute name="href">
					<xsl:value-of select="$http"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="$details">
				<xsl:attribute name="title">
					<xsl:value-of select="$details"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="$short"/>
		</a>
	</xsl:template>

	<xsl:template name="tag">
		<xsl:param name="tag"/>
		<xsl:param name="count"/>
		<a>
			<xsl:attribute name="href">
				<xsl:text>#tag:</xsl:text>
				<xsl:value-of select="$tag"/>
			</xsl:attribute>
			<xsl:value-of select="@term"/>
			<xsl:if test="$count">
				<xsl:variable name="term" select="@term"/>
				<xsl:text>&nbsp;(</xsl:text>
				<xsl:value-of select="$count"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</a>
	</xsl:template>

	<xsl:template name="view-transition-name">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:attribute name="style">
			<xsl:text>view-transition-name:</xsl:text>
			<xsl:value-of select="$name"/>
			<xsl:text>-</xsl:text>
			<xsl:value-of select="$type"/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template name="strip-right">
		<xsl:param name="str"/>
		<xsl:param name="sub"/>
		<xsl:choose>
			<xsl:when test="contains($str, $sub)">
				<xsl:value-of select="normalize-space(substring-before($str, $sub))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="string-between">
		<xsl:param name="str"/>
		<xsl:param name="left"/>
		<xsl:param name="right"/>
		<xsl:if test="contains($str, $left) and contains($str, $right)">
			<xsl:variable name="no_left" select="substring-after($str, $left)"/>
			<xsl:value-of select="normalize-space(substring-before($no_left, $right))"/>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
