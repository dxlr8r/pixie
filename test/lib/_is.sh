#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/pixie.sh

# in-list | member

list='aaa
bbb
ccc'

Is in-list aaa "$list"
