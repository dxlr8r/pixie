#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/text.sh

doc='aaa
bbb
cc
ddd'

assert='aaa
bbb
ccc
ddd'

Text ensure-line \
	in="$doc" \
	after='bbb' \
	match_re='^c' \
	value='ccc' \
	| test "$(cat)" = "$assert"
