<?xml version="1.0" encoding="utf-8"?><!-- vi:set ts=4 sw=4: -->
<!DOCTYPE xsl:stylesheet [
<!ENTITY nbsp "&#160;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atom="http://www.w3.org/2005/Atom" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:output method="html" encoding="utf-8" indent="yes" doctype-system="about:legacy-compat"/>
	<xsl:variable name="base" select="/atom:feed/atom:link/@href"/>
	<xsl:variable name="base_len" select="string-length($base)"/>
	<xsl:variable name="lazyblog-url" select="/processing-instruction('lazyblog-url')"/>
	<xsl:variable name="privacy-policy" select="/atom:feed/*[@id='privacy-policy']"/>
	<xsl:variable name="tracker-code" select="/atom:feed/*[@id='tracker-code']"/>
	<xsl:variable name="lang" select="document(concat($lazyblog-url, '/lang-', /atom:feed/@xml:lang, '.xml'))/*"/>
	<!-- see: https://en.wikipedia.org/wiki/XSLT/Muenchian_grouping -->
	<xsl:key name="tags" match="/atom:feed/atom:entry/atom:category" use="@term"/>
	<xsl:variable name="all_tags" select="/atom:feed/atom:entry/atom:category"/>
	<xsl:variable name="uniq_tags" select="$all_tags[count(. | key('tags', @term)[1]) = 1]"/>
	<xsl:template match="atom:feed">
		<html lang="{@xml:lang}">
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
				<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
				<title>
					<xsl:value-of select="atom:title"/>
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
				<link rel="canonical" href="{atom:link[@rel='self']/@href}"></link>
				<link rel="alternate" type="application/atom+xml" href="{atom:link[@rel='self']/@href}"></link>
			</head>
			<body>
				<small style="float:right">
					<i>
						<xsl:value-of select="$lang/header/last-update"/>
						<time datetime="{atom:updated}">
							<xsl:value-of select="translate(substring(atom:updated, 0, 20), 'T', ' ')"/>
							<xsl:text> UTC</xsl:text>
						</time>
					</i>
				</small>
				<header>
					<h1 style="border-bottom: 1px solid #8888">
						<xsl:value-of select="atom:title"/>
						<small style="font: initial;margin-left: 3.5em">
							<xsl:value-of select="atom:subtitle"/>
						</small>
					</h1>
					<nav>
						<xsl:value-of select="$lang/header/links"/>
						<xsl:for-each select="atom:link[@rel='related']">
							<a href="{@href}">
								<xsl:value-of select="@title"/>
							</a>
							<!-- NOTE: can't do this using CSS, because it will make ", " part of link -->
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
									<a href="#tag:{@term}">
										<xsl:value-of select="@term"/>
										<!-- NOTE: we wrap everything in <xsl:text> here, because otherwise newline will add (breakable) space, and text might wrap between tag name and number in braces, defeating &nbsp; there -->
										<xsl:text>&nbsp;(</xsl:text>
										<xsl:value-of select="count(key('tags', @term))"/>
										<xsl:text>)</xsl:text>
									</a>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</span>
						</div>
						<p>
							<a id="showall" href="#" style="float:right;margin-left:1ex">
								<xsl:value-of select="$lang/filter/show-all/pre"/>
								<xsl:value-of select="count(atom:entry)"/>
								<xsl:value-of select="$lang/filter/show-all/post"/>
							</a>
						</p>
						<p>
							<label>
								<xsl:value-of select="$lang/filter/by-search"/>
								<input type="search" id="search" placeholder="{normalize-space($lang/filter/search-placeholder)}"></input>
							</label>
						</p>
						<hr/>
					</div>
				</header>
				<main>
					<ol style="padding-left:0px">
						<xsl:apply-templates select="atom:entry">
							<xsl:sort select="atom:published" order="descending"/>
						</xsl:apply-templates>
					</ol>
				</main>
				<script> <!-- same stuff, just for scripts -->
					var tags_count={
					<xsl:for-each select="$uniq_tags">
						'<xsl:value-of select="@term"/>':
						<xsl:value-of select="count(key('tags', @term))"/>,
					</xsl:for-each>
					};
					var tags=Object.keys(tags_count).sort();
					var posts=[
					<xsl:for-each select="atom:entry">
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
				<script src="{$lazyblog-url}/script.js"></script>
				<footer style="text-align: center">
					<hr/>
					<p>
						<xsl:apply-templates select="atom:rights"/>
						<xsl:text> </xsl:text>
						<a href="{atom:author/atom:uri}">
							<xsl:value-of select="atom:author/atom:name"/>
						</a>
						<xsl:if test="$privacy-policy">
							<xsl:value-of select="$lang/footer/sep"/>
							<a href="javascript:alert('{$privacy-policy}')">
								<xsl:value-of select="$lang/footer/privacy-policy"/>
							</a>
						</xsl:if>
						<xsl:value-of select="$lang/footer/sep"/>
						<a id="email" href="javascript:(l=document.getElementById('email')).href='mailto:'+(l.innerHTML=location.hostname.replace('.','@'));void 0">
							<xsl:value-of select="$lang/footer/show-email"/>
						</a>
						<!--
					<small style="display:block">
						<xsl:value-of select="$lang/footer/generator"/>
						<a href="{atom:generator/@uri}">
							<xsl:value-of select="atom:generator"/>
						</a>
					</small>
					-->
					</p>
				</footer>
				<xsl:if test="$tracker-code">
					<xsl:copy-of select="$tracker-code"/>
				</xsl:if>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="atom:entry">
		<xsl:variable name="relative_url" select="substring(atom:link/@href, $base_len+1)"/>
		<xsl:variable name="uuid" select="substring-after(atom:id, 'urn:uuid:')"/>
		<!-- <xsl:variable name="name_only" select="substring($relative_url, 0, string&#45;length($relative_url)&#45;string&#45;length('.html')+1)"/> -->
		<li>
			<a class="title" style="view-transition-name:title-{$uuid}" href="{$relative_url}">
				<xsl:value-of select="atom:title"/>
			</a>
			<small style="view-transition-name:small-{$uuid}">
				<xsl:value-of select="$lang/small/published"/>
				<time>
					<xsl:value-of select="substring(atom:published, 0,11)"/>
				</time>
				<xsl:value-of select="$lang/small/sep"/>
				<xsl:value-of select="$lang/small/updated"/>
				<time datetime="{atom:updated}">
					<xsl:value-of select="substring(atom:updated, 0,11)"/>
				</time>
				<xsl:value-of select="$lang/small/sep"/>
				<xsl:value-of select="$lang/small/tags"/>
				<xsl:for-each select="atom:category">
					<a href="#tag:{@term}">
						<xsl:value-of select="@term"/>
					</a>
					<!-- NOTE: can't do this using CSS, because it will make ", " part of link -->
					<xsl:if test="position()!=last()">, </xsl:if>
				</xsl:for-each>
			</small>
			<!-- <div>&#38;nbsp;</div> <!&#45;&#45; gap  &#45;&#45;> -->
			<div class="intro" style="view-transition-name:intro-{$uuid}">
				<xsl:copy-of select="atom:content/*"/>
				<xsl:value-of select="$lang/read-more/sep"/>
				<a href="{$relative_url}">
					<xsl:value-of select="$lang/read-more/text"/>
				</a>
			</div>
			<!-- <div>&#38;nbsp;</div> <!&#45;&#45; gap  &#45;&#45;> -->
		</li>
	</xsl:template>

	<xsl:template match="atom:rights">
		<xsl:variable name="rights" select="."/>
		<xsl:variable name="http">
			<xsl:if test="contains($rights, 'http')">
				<xsl:value-of select="normalize-space(concat('http', substring-after($rights, 'http')))"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="details">
			<xsl:if test="contains($rights, '(' ) and contains($rights, ')' )">
				<!-- text between (...) -->
				<xsl:value-of select="normalize-space(substring-before(substring-after($rights, '(' ), ')' ))"/>
			</xsl:if>
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

</xsl:stylesheet>
