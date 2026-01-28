#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/pixie.sh

# which
test "$(which ls)" = '/usr/bin/ls'

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

# prn
prn a b c | grep -Fxq 'a b c'

# prnl
prnl a b c | tr "$NEWLINE" ":" | grep -Fxq 'a:b:c:'

# rand
a=$(rand 100)
b=$(rand 100)
printf %s "$a" | wc -c | test "$(cat)" -eq 100
test "$a" != "$b"

# seq
seq 1 3 | xargs | grep -Fqx '1 2 3'

# status

{
	status 2
	rc=$?
} || :
test "$rc" -eq 2
