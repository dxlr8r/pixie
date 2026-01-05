#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../lib/base.sh

assert=' a a
bb'
def doc1 <<-EOF
	 a a
	bb
EOF
test "$doc1" = "$assert"

def doc2 ' a a' 'bb'
test "$doc2" = "$assert"

rand 100 | wc -c | test "$(cat)" -eq 100
