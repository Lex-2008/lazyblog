# lazyblog
a static blog generator which tries to do as little as possible on the server side

Main idea behind this blog system is to _do as little as possible_.
Meaning, offload as much as possible to client-side (but still being search engine friendly).
It tries to fit between [jr][] (where the whole markdown rendering is made client-side),
and [bashblog][] (for example, by moving tags, as being non-essential for search-engine navigation, to client-side).

Also, bashblog spends noticeable time rebuilding `all_posts.html` page
after every minor change to any article, what is a bit annoying
and maybe also could be avoided.

[jr]: http://xeoncross.github.io/jr/
[bashblog]: https://github.com/cfenollosa/bashblog
