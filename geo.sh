#!/bin/bash

LAZYBLOG_DIR="../lazyblog"
outdir="geo"

die() {
	echo "$2" >&2
	exit "$1"
}

. .config &>/dev/null
test -f "$LAZYBLOG_DIR/lang-$BLOG_LANG.sh" || die 1 "$LAZYBLOG_DIR/lang-$BLOG_LANG.sh not found"
. "$LAZYBLOG_DIR/lang-$BLOG_LANG.sh"

GEO_PRE="<div style='white-space: nowrap;overflow-x: clip;font-size: small;border: 2px groove ThreeDFace;padding: 1em;'>
$lang_geo_served_on <!--# echo var='show_date' --> $lang_geo_served_at <!--# echo var='show_time' -->
$lang_geo_served_for <span title='<!--# echo var='show_asn' -->' style='cursor:default'>
<script>document.write(String.fromCodePoint(...'<!--# echo var='show_co' -->'.toUpperCase().split('').map((char) => 127397 + char.charCodeAt(0))));</script>
</span>
<!--# echo var='show_ip' -->,
sha:<!--# echo var='show_sha' -->
</div>"


outname="$outdir/${uuid:?"uuid env var must be set"}.html"
postproc="${@:-cat}"

mkdir -p "$outdir"
rm -f "$outname"*

[[ -z "$name" ]] || ln -s "$name" "$outname.link"

# we need to go through this file multiple times
src="$(mktemp)"
cat >"$src"

tags="$(cat "$src" | sed -n '/^@/{s/@//g;s/ /\n/;p}' | sort -u)"

for tag in $tags; do
	case "$tag" in
		( def* ) out='' ;;
		( unk* ) out='-' ;;
		( und* ) out='-' ;;
		( * ) out="-$tag" ;;
	esac

	outfile="$outname$out"

	printing=y
	while IFS= read -r line; do
		# if echo "$line" | grep -q '^@'; then
		if [[ "$line" =~ ^@ ]]; then
			# if echo "$line" | grep -q "$tag" || echo "$line" | grep -q '^@*$'; then
			if [[ "$line" == *"$tag"* || "$line" =~ ^@*$ ]]; then
				printing=y
			else
				printing=n
			fi
		else
			[[ "$printing" == y ]] && echo "$line"
		fi
	done <"$src" | eval "$postproc" >>"$outfile"
done
rm "$src"

echo "$GEO_PRE"
echo "<!--# include virtual='$outname' -->"
