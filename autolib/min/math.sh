#!/bin/sh
# SPDX-FileCopyrightText: 2022-2026 Simen Strange <https://github.com/dxlr8r/pixie>
# SPDX-License-Identifier: MIT
# Version: 0.0.1-beta

PIXIE_MATH_SOURCED=true

PixieMath()
(
	op="${1:-}"
	shift

	if test "${1:-}" = '-'; then
		shift
		set -- $(cat) "$@"
	fi

	case "$op" in
	+ | add | sum)
		printf '%s\n' $* | LC_NUMERIC=C awk -v SUM=0 '{ SUM=SUM + $1 } END { print SUM }'
		;;
	- | sub | substract)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM - $1 }} END { print SUM }'
		;;
	/ | div | divide)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM / $1 }} END { print SUM }'
		;;
	'*' | x | mul | multiply)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM * $1 }} END { print SUM }'
		;;
	% | mod | modulo)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM % $1 }} END { print SUM }'
		;;
	avg | average)
		printf '%s\n' $* | LC_NUMERIC=C awk -v ARGS=$# -v SUM=0 '{ SUM=SUM + $1 } END { print SUM / ARGS }'
		;;
	max | maximum)
		printf '%s\n' $* | LC_NUMERIC=C awk '{ if(NR == 1) {MAX = $1} else if($1 > MAX) {MAX = $1} } END { print MAX }'
		;;
	min | minimum)
		printf '%s\n' $* | LC_NUMERIC=C awk '{ if(NR == 1) {MIN = $1} else if($1 < MIN) {MIN = $1} } END { print MIN }'
		;;
	esac
)

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Math=PixieMath
fi

if test "${PIXIE_MATH_ALIAS:-true}" = 'true'; then
	alias madd='Math add'
	alias msub='Math sub'
	alias mdiv='Math div'
	alias mmul='Math mul'
	alias mmod='Math mod'
	alias mavg='Math avg'
	alias mmax='Math max'
	alias mmin='Math min'
fi
