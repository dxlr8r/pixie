#!/bin/sh

Math()
(
	op="${1:-}"
	shift

	if test "${1:-}" = '-'; then
		shift
		set -- $(cat) "$@"
	fi

	case "$op" in
	+ | add)
		printf '%s\n' $* | LC_NUMERIC=C awk -v SUM=0 '{ SUM=SUM + $1 } END { print SUM }'
		;;
	- | substract | sub)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM - $1 }} END { print SUM }'
		;;
	/ | divide | div)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM / $1 }} END { print SUM }'
		;;
	'*' | x | mul | multiply)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM * $1 }} END { print SUM }'
		;;
	% | mod | modulo)
		printf '%s\n' $* | LC_NUMERIC=C awk '{if (NR == 1) { SUM = $1} else { SUM=SUM % $1 }} END { print SUM }'
		;;
	esac
)

if test "${MATH_ALIAS:-false}" = 'true'; then
	alias madd='Math add'
	alias msub='Math sub'
	alias mdiv='Math div'
	alias mmul='Math mul'
	alias mmod='Math mod'
fi
