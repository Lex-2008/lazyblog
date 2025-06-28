Lazy blog
=========

my version of a static blog generator, using Bash and XML/XSLT

"Lazy", because it tries to do as little as possible:

* do only the most essential stuff on server side
  (like providing links from index page to all posts),
  and move all non-essential stuff (like search and tags)
  to client side (Javascript)

* do only the most essential stuff when generating index.html
  (patch it, instead of regenerating anew)

* try to keep code as small as possible
  (under 100 lines of bash script)

Originally it tried to fit between [jr][]
(which does not look very search-engine friendly),
and [bashblog][] (which re-reads all posts on single post modification),
but now I'm not sure how much XSLT is SEO-friendly.

[jr]: http://xeoncross.github.io/jr/
[bashblog]: https://github.com/cfenollosa/bashblog

Technology used
---------------

Server-side:
* sed -i
* envsubst

Client-side:
* XSLT for main page display

Javascript features:
* array.map, array.filter, array.forEach (FF1.5+, IE 9+)
* (document|element).querySelector\[All\] (FF 3.5+, IE 9+, Opera 10+, Safari 3.2+)
* window.onhashchange (Chrome 5.0+, FF 3.6, IE 8+, Opera 10.6+, Safari 5.0+)
