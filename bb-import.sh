#!/bin/bash

DATE_FORMAT="%F"
IFS=$'\n'

function parse_file() {
	read title;
	read intro;
	read sep;
	content="$(cat)"
	tags="$(echo "$content" | sed '/^\(Метки\|Tags\): /!d;s/^[^ ]* //;s/, */ /g;s/./\L&/g')"
	content="$(echo "$content" | sed '/^\(Метки\|Tags\): /d')"
	[ "$sep" = "* * *" ] || content="$sep
$content"
	
	echo "title=$title
intro=$intro
tags=$tags
created=$(date -r "$1" +"$DATE_FORMAT")
modified=$(date -r "$2" +"$DATE_FORMAT")
modified_now=1

$content"
}

function parse_html() {
	read line; # <!-- entry begin -->
	read line; # <h3><a class="ablack" href="ze-drem.html">
	read title;# Ze Drem
	read line; # </a></h3>
	read line; # <div class="subtitle">September 26, 2009  &mdash;
	read line; # Alexey Shpakovsky</div>
	read line; # <!-- text begin -->
	while [ "$intro" == "" ]; do
		read intro;# EuroEnglish --- Ze drem vil finali kum tru!
	done
	while [ "$sep" == "" ]; do
		read sep;  # <hr>
	done
	content="$(cat)"
	[ "$sep" = "<hr>" ] || content="$sep
$content"
	# <p>Tags: <a href='tag_Fun.html'>Fun</a></p>
	tags="$(echo "$content" | sed '/^<p>\(Метки\|Tags\): /!d;s/<[^<]*>//g;s/^[^ ]* //;s/, */ /;s/./\L&/g')"
	content="$(echo "$content" | sed '/^<p>\(Метки\|Tags\): /d;/<!-- text end -->/d')"

	echo "title=$title
intro=$intro
tags=$tags
created=$(date -r "$1" +"$DATE_FORMAT")
modified=$(date -r "$1" +"$DATE_FORMAT")
modified_now=1

<div>
$content
</div>"
}



for f in $(ls -tr "$1"/*.html | sed '/all_\|tag_\|index\.html/d'); do
	(
	name="$(basename $f)"
	src="$(dirname $f)"
	name="${name%.html}"
	if [ ! -f "$src/$name.md" ]; then
		sed '/<!-- entry begin -->/,/<!-- text end -->/!d' "$src/$name.html" | parse_html "$src/$name.html" >"$name.md"
		touch -r "$src/$name.html" "$name.md"
	else
		parse_file "$src/$name.html" "$src/$name.md" <"$src/$name.md" >"$name.md"
		touch -r "$src/$name.md" "$name.md"
	fi
	bash "$(dirname $0)"/lazyblog.sh add "$name.md"
	)
done
