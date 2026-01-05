#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../lib/ext.sh

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

test "$(which ls)" = '/usr/bin/ls'
seq 1 3 | xargs | grep -Fqx '1 2 3'
