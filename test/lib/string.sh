#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../lib/string.sh

# String replace && str_replace

test "$(echo fuubar | String replace value='u' match='o')" = 'foobar'
test "$(echo fuubar | String replace value='u' match='o' in=-)" = 'foobar'
test "$(echo fuubar | String replace value='u' match='o' -)" = 'foobar'
test "$(String replace value='u' match='o' in='fuubar')" = 'foobar'

test "$(str_replace u o fuubar)" = 'foobar'
test "$(echo fuubar | str_replace u o)" = 'foobar'
test "$(echo fuubar | str_replace u o -)" = 'foobar'
