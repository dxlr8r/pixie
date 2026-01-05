#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../lib/math.sh

test "$(madd 2 4 | msub - 3 | mmul - 4 | mdiv - 2 | madd - 1 | mmod - 2)" -eq 1
