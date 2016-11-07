#!/bin/bash

. lazyblog.sh import

function test_rebuild_file() {
mkdir test
cd test
echo "before
<!-- begin HUGE $SEP 5 -->
HUGE
<!-- end HUGE -->
<!-- begin big $SEP 3 -->
big
<!-- end big -->
<!-- begin asd $SEP 2 -->
old text
<!-- end asd -->
<!-- begin small $SEP 1 -->
small
<!-- end small -->
<!-- contents above -->
after" >index.html
echo "title=a s d
intro=some text
created=4

article" >asd.md
echo '$title
$intro' >"$INDEX_PART_TEMPLATE"
echo '$title
$intro
$content' >"$TEMPLATE"
echo -n "test_process_file "
process_file asd.md
[ "$(<asd.html)" = "a s d
some text" ] && echo y || echo n
echo -n "test_update_index "
update_index
[ "$(<index.html)" = "before
<!-- begin HUGE  --  5 -->
HUGE
<!-- end HUGE -->
<!-- begin asd  --  4 -->
a s d
some text
<!-- end asd -->
<!-- begin big  --  3 -->
big
<!-- end big -->
<!-- begin small  --  1 -->
small
<!-- end small -->
<!-- contents above -->
after" ] && echo y || echo n
cd ..
rm -rf test
}

function test_delete() {
echo -n "test_delete "
[ "$(echo "before
<!-- begin asd $SEP 1 -->
a
<!-- end asd -->
after" | delete "asd")" = "before
after" ] && echo y || echo n
}

function test_insert_last() {
echo -n "test_insert_last "
[ "$(echo "before
<!-- contents above -->
after" | insert "asd" "1" "some text")" = "before
<!-- begin asd $SEP 1 -->
some text
<!-- end asd -->
<!-- contents above -->
after" ] && echo y || echo n
}


function test_insert_place() {
echo -n "test_insert_place "
[ "$(echo "before
<!-- begin big $SEP 3 -->
big
<!-- end big -->
<!-- begin small $SEP 1 -->
small
<!-- end small -->
<!-- contents above -->
after" | insert "asd" "2" "some text")" = "before
<!-- begin big $SEP 3 -->
big
<!-- end big -->
<!-- begin asd $SEP 2 -->
some text
<!-- end asd -->
<!-- begin small $SEP 1 -->
small
<!-- end small -->
<!-- contents above -->
after" ] && echo y || echo n
}


test_delete
test_insert_last
test_insert_place
test_rebuild_file
