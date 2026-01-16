#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/pixie.sh

# loop/nloop

data='aaa
bbb
ccc
ddd'

fn()
{
	echo "$i"
}
nloop var=i list="$data" fn=fn | test "$(cat)" = "$data"
loop i "$data" fn | test "$(cat)" = "$data"

# member

list='aaa
bbb
ccc'

member aaa "$list"

# rand

rand 100 | wc -c | test "$(cat)" -eq 100

# status

{
	status 2
	rc=$?
} || :
test "$rc" -eq 2

# seq
seq 1 3 | xargs | grep -Fqx '1 2 3'

# which
test "$(which ls)" = '/usr/bin/ls'
