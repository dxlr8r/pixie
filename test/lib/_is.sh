#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/pixie.sh

# in-list | member

list='aaa
bbb
ccc'

Is in-list aaa "$list"

# variable-name

Is variable-name 'Aa_1' 'bB_2'

Is variable-name 'Cc_2' '3_dD' || {
	ret=$?
}
test "$ret" -eq 1

# populated

Is populated a
Is populated '' || {
	ret=$?
}
test "$ret" -eq 1

# visible

Is visible a
Is visible ' ' || {
	ret=$?
}
test "$ret" -eq 1

# unsigned-int

Is unsigned-int 1
Is unsigned-int -1 || {
	ret=$?
}
test "$ret" -eq 1

# int

Is int 1
Is int -1
Is int ' ' || {
	ret=$?
}
test "$ret" -eq 1
