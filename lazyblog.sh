#!/bin/bash

TEMPLATE=".template.html"
INDEX_PART_TEMPLATE=".index.part.html"
INDEX_FULL_TEMPLATE=".index.full.html"
DATE_FORMAT="%F"
TEMPLATE_LIST='$title $author $created $modified $intro $content'
SEP=" -- "
SORT_TEMPLATE='$created'

set +o histexpand

function process_file() {
	src="$1"
	name="${src%.*}"
	dst="$name.html"
	if [ ! -s "$src" ]; then
		echo "ERROR! file [$src] must exist for rebuild_file"
		exit 1
	fi
	{
		# read header an set variables
		while read line; do
			[ "$line" = "" ] && break
			key="${line%=*}"
			value="${line/*=}"
			[ "$value" = "NOW" ] && value = "$(date +"$DATE_FORMAT")"
			eval export $key="\"$value\""
		done
		# rest of $src file gets passed through markdown
		content="$(Markdown.pl)"
	} <"$src"
	envsubst "$TEMPLATE_LIST" <"$TEMPLATE" >"$dst"
}

function update_index() {
	[ -f index.html ] || cp "$INDEX_FULL_TEMPLATE" index.html
	index_part="$(envsubst "$TEMPLATE_LIST" <"$INDEX_PART_TEMPLATE")"
	sort="$(envsubst "$TEMPLATE_LIST" <<<"$SORT_TEMPLATE")"
	delete "$name" <index.html  | insert "$name" "$sort" "$index_part" >index.new.html
	mv index.new.html index.html
}

#separators look like this:
#<!-- begin $name $sep $sort -->
#<!-- end $name -->

function delete() {
	name="$1"
	print=1
	while read line; do
		expr "$line" : "<!-- begin $name $SEP" >/dev/null && print=0
		[ "$print" = 1 ] && echo "$line"
		[ "$line" = "<!-- end $name -->" ] && cat # process rest of file
	done
}

function insert() {
	name="$1"
	sort="$2"
	content="$3"
	print=0
	while read line; do
		#if this_sort="$(expr "$line" : "<!-- begin .* $SEP \(.*\) -->")"; then
			#if expr "$this_mark" >= "$my_mark"; then
		this_sort="$(expr "$line" : "<!-- begin .* $SEP \(.*\) -->")" && expr "$this_sort" \<= "$sort" >/dev/null && print=1
		[ "$line" = "<!-- contents above -->" ] && print=1
		if [ "$print" = "1" ]; then
			echo "<!-- begin $name $SEP $sort -->"
			echo "$content"
			echo "<!-- end $name -->"
			echo "$line"
			cat
			break
		fi
		echo "$line"
	done
}

case "$1" in
	( "add" | "file" | "update" )
		process_file "$2"
		update_index
		;;
	( "rm" )
		name="${2%.*}"
		delete "$name" <index.html  >index.new.html
		mv index.new.html index.html
		;;
	( "update1" )
		process_file "$2"
		;;
	( "post" )
		echo "not implemented yet" >&2
		;;
	( "edit" )
		echo "not implemented yet" >&2
		;;
	( "rebuild" )
		rm index.html
		shift
		for f in "$@"; do
			( # to protect variables exported from one file to influencing other files,
			  # we process each file in a subshell
				process_file "$f"
				update_index
			)
		done
		;;
	( "import" )
		# used when importing to other scripts
		;;
	( "*" )
		echo "some help text"
		;;
esac

