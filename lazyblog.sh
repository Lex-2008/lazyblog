#!/bin/bash

LAZYBLOG_DIR="../lazyblog"
LAZYBLOG_URL="/lazyblog"
TEXT_TEMPLATE="$LAZYBLOG_DIR/template.md"
POST_TEMPLATE="$LAZYBLOG_DIR/post-template.html"
INDEX_TEMPLATE="$LAZYBLOG_DIR/index-template.xml"
INDEX_PAGE="index.xml"
DATE_FORMAT="%F"
BLOG_TITLE="Notes"
BLOG_INTRO="Notes about different stuff"
BLOG_URL="http://alexey.shpakovsky.ru/en"
BLOG_LINKS="http://alexey.shpakovsky.ru/ru/ Russian blog|http://alexey.shpakovsky.ru/photos/en.html Photo Archive|https://github.com/Lex-2008/ GitHub"
BLOG_AUTHOR="Alexey Shpakovsky"
BLOG_AUTHOR_URL="http://alexey.shpakovsky.ru/"
BLOG_RIGHTS="CC BY"
BLOG_RIGHTS_LONG="Creative Commons Attribution 4.0 International"
BLOG_RIGHTS_URL="https://creativecommons.org/licenses/by/4.0/"
privacy_nolog="No data about visitors of this page is collected"
privacy_log="For security purposes the following data is collected about visitors of this page: IP address and port, country and ISP, access date and time, URL of this and previous (if available) page, and browser user-agent. This data is stored for an indefinite period. To remove your data, send me an email with your data."
BLOG_PRIVACY="$privacy_nolog"
BLOG_LANG="en"
privacy_default="$BLOG_PRIVACY"
# TRACKER_CODE="<script async='' data-info-to='/info/' data-hello-to='/hello/' src='$LAZYBLOG_URL/page.js'></script>"
PROCESSOR="cmark-gfm --unsafe -e footnotes -e table -e strikethrough -e tasklist --strikethrough-double-tilde"
GZIP_HTML="y" # set to "n" to disable creating compressed page.html.gz files next to each page.html
TEMPLATE_LIST_LANG='$lang_small_published $lang_small_updated $lang_small_tags $lang_small_sep $lang_footer_sep $lang_footer_privacy $lang_footer_show_email $lang_footer_show_all'
TEMPLATE_LIST_MAIN='$LAZYBLOG_URL $BLOG_TITLE $BLOG_INTRO $BLOG_URL $BLOG_LINKS $BLOG_AUTHOR $BLOG_AUTHOR_URL $BLOG_RIGHTS $BLOG_RIGHTS_HTML $BLOG_LANG $BLOG_PRIVACY $BLOG_PRIVACY_XML $TRACKER_CODE $TRACKER_CODE_XML'
TEMPLATE_LIST_PAGE="$TEMPLATE_LIST_MAIN $TEMPLATE_LIST_LANG"' $PROCESSOR $name $url $uuid $title $texttitle $created $createdTZ $modified $modifiedTZ $tags $htmltags $xmltags $intro $textintro $htmlintro $style $styles $scripts $privacy $tracker_code'
TITLE_TO_FILENAME="sed 's/./\\L&/g;s/\\s/-/g;s/[^a-z0-9а-яёæøå_-]//g;s/^-*//;s/-\\+/-/'"
STYLES_TO_CSS='s_^img$_img {display:block; margin:auto; max-width:100%}_;
s_footnotes\?_.footnotes {border-top: 1px solid #8888;font-size:smaller}_;
s_hr_main hr {border: 1px solid #8888}_;
s_blockquote_blockquote {border-left:solid 3px gray;margin-left:1em;padding:0.1px 1em 0.1px 1em;background: rgba(128,128,128,0.5)}_;
s_pre_pre {border:solid 1px gray;background: rgba(128,128,128,0.5)}_;
s_invert-\?img$_@media (prefers-color-scheme: dark) {img{filter: invert()}}_;
s_cache_a[href^="/cache/"],a[href^="../cache/"] {font-size:x-small; vertical-align:sub}_;
s_archive_a[href^="http://archive."],a[href^="https://archive."],a[href^="https://web.archive.org"] {font-size:x-small; vertical-align:sub}_;
/{/!d
'
SCRIPTS_TO_HTML='s_live_<script>(new WebSocket((location.protocol[4]=="s"?"wss":"ws")+"://ws.shpakovsky.ru/modified.sh?"+location.host+location.pathname)).onmessage=(event)=>{if(event.data.indexOf("MODIFY")>-1) location.reload();};</script>_;
/script/!d
'

die() {
	echo "$2" >&2
	exit "$1"
}

. .config &> /dev/null
test -f "$LAZYBLOG_DIR/lang-$BLOG_LANG.sh" || die 1 "$LAZYBLOG_DIR/lang-$BLOG_LANG.sh not found"
. "$LAZYBLOG_DIR/lang-$BLOG_LANG.sh"

BLOG_LINKS="$(echo "$BLOG_LINKS" | tr '|' '\n' | sed -r 's_^([^ ]+) (.*)_\t<link rel="related" href="\1" title="\2"/>_')"
BLOG_RIGHTS_HTML="<a $(test -n "$BLOG_RIGHTS_URL" && echo "href='$BLOG_RIGHTS_URL'") $(test -n "$BLOG_RIGHTS_LONG" && echo "title='$BLOG_RIGHTS_LONG'")>$BLOG_RIGHTS</a>"

test -n "$TRACKER_CODE" && TRACKER_CODE_XML="<div id='tracker-code' xmlns='http://www.w3.org/1999/xhtml'>$TRACKER_CODE</div>"
BLOG_PRIVACY_XML="<div id='blog-privacy' xmlns='http://www.w3.org/1999/xhtml'>$BLOG_PRIVACY</div>"
test -z "$privacy_default" && privacy_default="$BLOG_PRIVACY"

test -n "$BLOG_RIGHTS_LONG" && BLOG_RIGHTS="$BLOG_RIGHTS ($BLOG_RIGHTS_LONG)"
test -n "$BLOG_RIGHTS_URL" && BLOG_RIGHTS="$BLOG_RIGHTS $BLOG_RIGHTS_URL"

export `echo "$TEMPLATE_LIST_MAIN $TEMPLATE_LIST_LANG" | tr -d '$'` PROCESSOR

set +o histexpand

rfc_date() {
	local a="$(date "$@" --utc --rfc-3339=seconds)"
	echo "${a/ /T}"
}

# https://github.com/sfinktah/bash/blob/master/rawurlencode.inc.sh
# https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
rawurlencode() {
	local string="${1}"
	local strlen=${#string}
	local encoded=""
	local pos c o
	for (( pos=0 ; pos<strlen ; pos++ )); do
		c="${string:$pos:1}"
		case "$c" in
			( [-_.~/a-zA-Z0-9] ) o="${c}"
				;;
			( * ) printf -v o '%%%02X' "'$c"
		esac
		encoded+="${o}"
	done
	echo "${encoded}"
}

process_file() {
	# $1 is *.md file to process
	src="$1"
	export name="${src%.*}"
	export url="$(LC_ALL=C rawurlencode "$name").html"
	export modified=$(date -r "$1" +"$DATE_FORMAT")
	export modifiedTZ="$(rfc_date -r "$1")"
	[ "${name:0:1}" = . ] && tracker_code='' || tracker_code="$TRACKER_CODE" # $tracker_code (lowercase) NOT on draft pages
	export tracker_code
	dst="$name.html"
	[ "$CMD" = "reindex" ] && dst="/dev/null"
	echo "processing file [$name]..."
	[ -s "$src" ] || die 11 "ERROR! src file [$src] must exist for process_file"
	[ "$src" = "$dst" ] && die 12 "ERROR! src file [$src] must NOT end with .html"
	[ -s "$POST_TEMPLATE" ] || die 13 "ERROR! post template file [$POST_TEMPLATE] must exist for process_file"
	{
		#echo "reading header..." >&2
		while read line; do
			[ "$line" = "" ] && break
			key="${line%%=*}"
			value="${line#*=}"
			eval export "$key"="\$value"
		done
		# privacy might contain a name of another env variable, which value is then used
		varname_privacy="privacy_$privacy"
		[ -n "${!varname_privacy}" ] && export privacy="${!varname_privacy}"
		[ -z "$privacy" ] && export privacy="$privacy_default"
		export styles="$(echo "$styles" | tr ' ' '\n' | sed "$STYLES_TO_CSS")"
		export scripts="$(echo "$scripts" | tr ' ' '\n' | sed "$SCRIPTS_TO_HTML")"
		export xmltags="$(echo "$tags" | tr ' ' '\n' | sed -r 's_([^ ]+)_\L\t\t<category term="&"/>_g')"
		export htmltags="$(echo "$tags" | sed -r 's_([^ ]+)_\L<a href="./#tag:&">&</a>_g')"
		export texttitle="$(echo "$title" | sed -r 's/<[^>]*>//g;s/&[a-z]+;//g')"
		export textintro="$(echo "$intro" | sed -r 's_"__g;s/<[^>]*>//g;s/&[a-z]+;//g')"
		export createdTZ="$(rfc_date --date="$created")"
		if [ "$CMD" != "reindex" ]; then
			sed '/=====/,$d' "$POST_TEMPLATE" | envsubst "$TEMPLATE_LIST_PAGE"
			#echo "Markdown..." >&2
			eval "$PROCESSOR"
			sed '1,/=====/d' "$POST_TEMPLATE" | envsubst "$TEMPLATE_LIST_PAGE"
		fi
	} <"$src" >"$dst"
	[ "$GZIP_HTML" = y -a "$CMD" != "reindex" ] && gzip -fk "$dst"
	[ "${name:0:1}" = . ] && return # do not add drafts to index.html
	#echo "patching index.html..."
	[ -f "$INDEX_PAGE" ] || sed '/<!-- begin $name -->/,/<!-- end $name -->/d' "$INDEX_TEMPLATE" | envsubst "$TEMPLATE_LIST_MAIN" >"$INDEX_PAGE"
	index_part="$(sed '/<!-- begin $name -->/,/<!-- end $name -->/!d' "$INDEX_TEMPLATE" | envsubst "$TEMPLATE_LIST_PAGE")"
	sed -i "0,/<updated>/s/updated>.*</updated>$(rfc_date)</;/<!-- begin $name -->/,/<!-- end $name -->/d;/<!-- put contents below -->/r "<(echo "$index_part") "$INDEX_PAGE"
	[ "$GZIP_HTML" = y -a -z "$SKIP_GZIP_INDEX" ] && gzip -fk "$INDEX_PAGE"
}

case "$1" in
	( "publish" )   # convert draft to post (rename, remove . from name)
		[ "${2:0:1}" = . ] || die 31 "filename [$2] doesn't look like a draft"
		set -- mv "$2" "${2:1}"
		;;
	( "unpublish" ) # convert post to draft (rename, add . to filename)
		[ "${2:0:1}" = . ] && die 32 "filename [$2] look like already a draft"
		set -- mv "$2" ".$2"
		;;
esac

CMD="$1"

case "$CMD" in
	( "add" | "update" | "file" ) # just process a file
		process_file "$2"
		;;
	( "rm" | "rmrf" ) # rm removes entry from index and *.html file, rmrf additionally removes all files with same basename, including *.md source
		name="${2%.*}"
		test -z "$name" && die 21 "pass argument to a file.html"
		sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d" "$INDEX_PAGE"
		[ "$GZIP_HTML" = y ] && gzip -fk "$INDEX_PAGE"
		rm "$name.html" "$name.html.gz"
		[ "$CMD" = "rmrf" ] && rm -rf $name.* $name/
		;;
	( "mv" | "rename" ) # rename a file
		[ -z "$2" -o -z "$3" ] && die 21 "ERROR! pass two arguments: old and new filename"
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		[ -f "$3" ] && die 29 "ERROR! file [$3] already exist!"
		name="${2%.*}"
		sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d" "$INDEX_PAGE"
		rm "$name.html" "$name.html.gz"
		mv "$2" "$3"
		process_file "$3"
		# when move destination is a draft - then process_file doesn't touch index.html,
		# thus doesn't recompress it. Let's do it here
		[ "${3:0:1}" = . -a "$GZIP_HTML" = y ] && gzip -fk "$INDEX_PAGE"
		;;
	( "post" | "draft" ) # add a post or draft, pass optional file with initial text
		[ -s "$TEXT_TEMPLATE" ] || die 27 "ERROR! file [$TEXT_TEMPLATE] must exist for posting"
		[ -z "$EDITOR" ] && die 25 "ERROR! \$EDITOR variable must be set!"
		[ -f .new-post.md ] || eval "echo \"$(cat "$TEXT_TEMPLATE")\"" >.new-post.md
		[ -s "$2" ] && cat "$2" >>.new-post.md
		$EDITOR ".new-post.md"
		title="$(sed '/^title=/!d;s/^title=//' .new-post.md)"
		[ -z "$title" ] && die 26 "ERROR! \$title not set!"
		new_filename="$(echo $title | eval "$TITLE_TO_FILENAME")"
		[ -z "$new_filename" ] && die 28 "ERROR! \$title does not contain valid characters!" #TODO: call it blog-post, maybe
		[ "$CMD" = "draft" ] && new_filename=".$new_filename"
		[ -f "$new_filename.html" ] && die 29 "ERROR! file [$new_filename.html] already exist!" #TODO: add numbers
		mv .new-post.md "$new_filename.md"
		process_file "$new_filename.md"
		[ -f "$2" -a "$2" != "$new_filename.md" ] && echo rm "$2"
		;;
	( "edit" )
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		[ -z "$EDITOR" ] && die 25 "ERROR! \$EDITOR variable must be set!"
		$EDITOR "$2"
		process_file "$2"
		;;
	( "rebuild" | "reindex" )
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		rm "$INDEX_PAGE"
		shift
		SKIP_GZIP_INDEX=1
		for f in $(ls -tr "$@"); do ( process_file "$f" ); done
		[ "$GZIP_HTML" = y ] && gzip -fk "$INDEX_PAGE"
		;;
	( "import" ) # used when importing to other scripts - does nothing
		;;
	( * ) # any other command - prints this text
		echo "use one of the following commands:"
		grep '^\s*(' "$0"
		;;
esac

