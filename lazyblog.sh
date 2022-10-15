#!/bin/bash

TEXT_TEMPLATE=".template.md"
POST_TEMPLATE=".post-template.html"
INDEX_TEMPLATE=".index-template.html"
DATE_FORMAT="%F"
BLOG_TITLE="Notes"
BLOG_INTRO="Notes about different stuff"
BLOG_URL="http://alexey.shpakovsky.ru/en"
PROCESSOR="cmark-gfm --unsafe -e footnotes -e table -e strikethrough -e tasklist --strikethrough-double-tilde"
GZIP_HTML="y" # set to "n" to disable creating compressed page.html.gz files next to each page.html
TEMPLATE_LIST='$BLOG_TITLE $BLOG_INTRO $BLOG_URL $PROCESSOR $name $url $title $created $modified $tags $htmltags $intro $style $styles'
TITLE_TO_FILENAME="sed 's/./\\L&/g;s/\\s/-/g;s/[^a-z0-9а-яёæøå_-]//g;s/^-*//'"
STYLES_TO_CSS='s_img_img {display:block; margin:auto; max-width:100%}_;
s_footnotes\?_.footnotes {border-top: 1px solid #8888;font-size:smaller}_;
s_hr_main hr {border: 1px solid #8888}_;
s_blockquote_blockquote {border-left:solid 3px gray}_;
s_cache_a[href^="/cache/"],a[href^="../cache/"] {font-size:x-small; vertical-align:sub}_;
s_archive_a[href^="http://archive."],a[href^="https://archive."] {font-size:x-small; vertical-align:sub}_;
/{/!d
'

. .config &> /dev/null

export BLOG_TITLE BLOG_INTRO BLOG_URL PROCESSOR

set +o histexpand

function die() {
	echo "$2" >&2
	exit "$1"
}

function process_file() {
	# $1 is *.md file to process
	src="$1"
	export name="${src%.*}"
	export modified=$(date -r "$1" +"$DATE_FORMAT")
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
		export styles="$(echo "$styles" | tr ' ' '\n' | sed "$STYLES_TO_CSS")"
		export htmltags="$(echo "$tags" | sed -r 's_([^ ]+)_\L<a href="./#tag:&">&</a>_g')"
		if [ "$CMD" != "reindex" ]; then
			sed '/=====/,$d' "$POST_TEMPLATE" | envsubst "$TEMPLATE_LIST"
			#echo "Markdown..." >&2
			$PROCESSOR
			sed '1,/=====/d' "$POST_TEMPLATE" | envsubst "$TEMPLATE_LIST"
		fi
	} <"$src" >"$dst"
	[ "$GZIP_HTML" = y -a "$CMD" != "reindex" ] && gzip -fk "$dst"
	[ "$CMD" = "draft" ] && return
	#echo "patching index.html..."
	[ -f index.html ] || sed '/<!-- begin $name -->/,/<!-- end $name -->/d' "$INDEX_TEMPLATE" | envsubst '$BLOG_TITLE $BLOG_INTRO $BLOG_URL' >index.html
	index_part="$(sed '/<!-- begin $name -->/,/<!-- end $name -->/!d' "$INDEX_TEMPLATE" | envsubst "$TEMPLATE_LIST")"
	sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d;/<!-- put contents below -->/r "<(echo "$index_part") index.html
	[ "$GZIP_HTML" = y -a -z "$SKIP_GZIP_INDEX" ] && gzip -fk index.html
}

CMD="$1"

case "$CMD" in
	( "add" | "update" | "file" ) # just process a file
		process_file "$2"
		;;
	( "rm" | "rmrf" ) # remove the file, rmrf additionally removes all files with same basename
		name="${2%.*}"
		sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d" index.html
		rm "$name.html" "$name.html.gz"
		[ "$CMD" = "rmrf" ] && rm -rf $name.* $name/
		;;
	( "mv" | "rename" | "publish" ) # rename a published file, also publish a draft
		[ -z "$2" -o -z "$3" ] && die 21 "ERROR! pass two arguments: old and new filename"
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		[ -f "$3" ] && die 29 "ERROR! file [$3] already exist!"
		name="${2%.*}"
		sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d" index.html
		rm "$name.html" "$name.html.gz"
		mv "$2" "$3"
		process_file "$3"
		;;
	( "post" | "draft" ) # add a post or draft, pass optional file with draft text
		[ -s "$TEXT_TEMPLATE" ] || die 27 "ERROR! file [$TEXT_TEMPLATE] must exist for posting"
		[ -z "$EDITOR" ] && die 25 "ERROR! \$EDITOR variable must be set!"
		eval "echo \"$(cat "$TEXT_TEMPLATE")\"" >.new-post.md
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
		[ -f "$2" && "$2" != "$new_filename.md" ] && echo rm "$2"
		;;
	( "edit" )
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		[ -z "$EDITOR" ] && die 25 "ERROR! \$EDITOR variable must be set!"
		$EDITOR "$2"
		process_file "$2"
		;;
	( "rebuild" | "reindex" )
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		rm index.html
		shift
		SKIP_GZIP_INDEX=1
		for f in $(ls -tr "$@"); do ( process_file "$f" ); done
		[ "$GZIP_HTML" = y ] && gzip -fk index.html
		;;
	( "import" ) # used when importing to other scripts - does nothing
		;;
	( * ) # any other command - prints this text
		echo "use one of the following commands:"
		grep '^\s*(' "$0"
		;;
esac

