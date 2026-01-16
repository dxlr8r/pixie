#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/string.sh

# esc && unesc

doc1='	$a
\\ b'
doc2='a'
assert1='\t$a\n\\\\ b
a'
assert2='	$a
\\ b
a'

str_esc "$doc1" "$doc2" | test "$(cat)" = "$assert1"
str_esc "$doc1" "$doc2" | str_unesc | test "$(cat)" = "$assert2"

# replace && str_replace

test "$(echo fuubar | String replace value='u' match='o')" = 'foobar'
test "$(echo fuubar | String replace value='u' match='o' in=-)" = 'foobar'
test "$(echo fuubar | String replace value='u' match='o' -)" = 'foobar'
test "$(String replace value='u' match='o' in='fuubar')" = 'foobar'

test "$(str_replace u o fuubar)" = 'foobar'
test "$(echo fuubar | str_replace u o)" = 'foobar'
test "$(echo fuubar | String replace u o -)" = 'foobar'

# {,l,r,s}trim

doc=' hello  world	'

String trim "$doc" | test "$(cat)" = 'hello  world'
String ltrim "$doc" | test "$(cat)" = 'hello  world	'
String rtrim "$doc" | test "$(cat)" = ' hello  world'
String strim "$doc" | test "$(cat)" = 'hello world'
