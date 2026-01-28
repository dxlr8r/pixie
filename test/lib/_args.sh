#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/pixie.sh

# `to-elist` depends on `kv-to-var`

fn()
{
	Args to-elist shift=3 -- "$@"
}

fn 1 2 3 a b c d | tr "$NEWLINE" : | grep -Fqx 'a:b:c:d:'
