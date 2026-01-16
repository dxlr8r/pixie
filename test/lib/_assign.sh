#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/pixie.sh

# Assert here
assert=' a a
bb'
here doc1 <<-EOF
	 a a
	bb
EOF
test "$doc1" = "$assert"

here doc2 ' a a' 'bb'
test "$doc2" = "$assert"

# Assert if-fn

fn_ok()
{
	printf '%s\n' "$1"
	return 0
}

fn_fail()
{
	printf '%s\n' "$1"
	return 1
}

doc=x
Assign if-fn doc fn_ok a
test "$doc" = a

doc=x
Assign if-fn doc fn_fail a || :
test "$doc" = x
