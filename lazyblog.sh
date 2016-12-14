#!/bin/bash

TEXT_TEMPLATE=".template.md"
HTML_TEMPLATE=".template.html"
DATE_FORMAT="%F"
BLOG_TITLE="Notes"
READ_MORE="Read more..."
TEMPLATE_LIST='$name $title $created $modified $tags $intro $content'
TITLE_TO_FILENAME="sed 's/./\\L&/g;s/\\s/-/g;s/[^a-z0-9а-яёæøå_-]//g;s/^-*//'"

. .config &> /dev/null

set +o histexpand

function die() {
	echo "$2" >&2
	exit "$1"
}

function process_file() {
	src="$1"
	update_modified="$2"
	export name="${src%.*}"
	dst="$name.html"
	echo "processing file [$name]..."
	[ -s "$src" ] || die 11 "ERROR! file [$src] must exist for rebuild_file"
	[ "$src" = "$dst" ] && die 12 "ERROR! file [$src] must NOT end with .html"
	[ -s "$HTML_TEMPLATE" ] || die 13 "ERROR! file [$HTML_TEMPLATE] must exist for rebuild_file"
	{
		#echo "reading header..."
		while read line; do
			[ "$line" = "" ] && break
			key="${line%%=*}"
			value="${line#*=}"
			eval export "$key"="\$value"
		done
		#echo "Markdown..."
		export content="$(Markdown.pl)"
	} <"$src"
	if [ "$modified_now" = "1" -a "$update_modified" = "1" ]; then
		#echo "updating timestamp..."
		modified="$(date +"$DATE_FORMAT")"
		sed -i "1,/^$/s/^modified=.*/modified=$modified/" "$src"
	fi
	#echo "writing to [$dst]..."
	sed '/<!-- begin index only -->/,/<!-- end index only -->/d' "$HTML_TEMPLATE" | envsubst "$TEMPLATE_LIST" >"$dst"
	#echo "patching index.html..."
	[ -f index.html ] || sed '/<!-- begin $name -->/,/<!-- end $name -->/d' "$HTML_TEMPLATE" | title=$BLOG_TITLE envsubst '$title' >index.html
	content="<p class=\"readmore\"><a href=\"$name.html\">$READ_MORE</a></p>"
	index_part="$(sed '/<!-- begin $name -->/,/<!-- end $name -->/!d' "$HTML_TEMPLATE" | envsubst "$TEMPLATE_LIST")"
	sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d;/<!-- put contents below -->/r "<(echo "$index_part") index.html
}

case "$1" in
	( "add" )
		process_file "$2"
		;;
	( "update" )
		process_file "$2" 1
		;;
	( "rm" )
		name="${2%.*}"
		sed -i "/<!-- begin $name -->/,/<!-- end $name -->/d" index.html
		rm -r "$name.*"
		;;
	( "post" )
		[ -s "$TEXT_TEMPLATE" ] || die 27 "ERROR! file [$TEXT_TEMPLATE] must exist for posting"
		[ -z "$EDITOR" ] && die 25 "ERROR! \$EDITOR variable must be set!"
		eval "echo \"$(cat "$TEXT_TEMPLATE")\"" >.new-post.md
		[ -s "$2" ] && cat "$2" >>.new-post.md
		$EDITOR ".new-post.md"
		title="$(sed '/^title=/!d;s/^title=//' .new-post.md)"
		[ -z "$title" ] && die 26 "ERROR! \$title not set!"
		new_filename="$(echo $title | eval "$TITLE_TO_FILENAME").md"
		[ -z "$new_filename" ] && die 28 "ERROR! \$title does not contain valid characters!" #TODO: call it blog-post, maybe
		[ -f "$new_filename.html" ] && die 29 "ERROR! file [$new_filename.html] already exist!" #TODO: add numbers
		mv .new-post.md "$new_filename"
		process_file "$new_filename" 1
		;;
	( "edit" )
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		[ -z "$EDITOR" ] && die 25 "ERROR! \$EDITOR variable must be set!"
		$EDITOR "$2"
		process_file "$2" 1
		;;
	( "rebuild" )
		[ -f "$2" ] || die 23 "ERROR! file [$2] does not exist!"
		rm index.html
		shift
		for f in $(ls -tr "$@"); do ( process_file "$f" ) done
		;;
	( "import" )
		# used when importing to other scripts - does nothing
		;;
	( "*" )
		echo "some help text"
		;;
esac

