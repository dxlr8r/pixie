#!/bin/sh

BASE_SOURCED=true

NEWLINE='
'
TABULATOR='	'

_kvargs_to_var()
{
	while test $# -gt 1; do
		# 1: current pair
		# ...: rest pairs
		# $#: prefix
		set -- "${1%%=*}" "${1#*=}" "$(eval printf %s\\\\n "\$$#")" "$@"
		# 1: current pair key
		# 2: current pair value
		# 3: prefix
		# 4: current pair
		# ...: rest pairs
		# $#: prefix

		if test "$1" != "$4"; then
			eval "${3}${1}=\$2"
		fi

		for i in 1 2 3 4; do
			shift
		done
		# ...: rest pairs
		# $#: prefix
	done
}

rand()
(
	set -- "${1:-8}"
	buf=''
	if test -n "${RANDOM:-}"; then
		while test "${#buf}" -lt "$1"; do
			buf=$(printf %s%s "$buf" "$RANDOM")
		done
	elif test -c /dev/urandom -a -r /dev/urandom; then
		floor10=$(($1 / 10))
		buf=$(od -An -tu4 -N$((4 * ($floor10 + 2))) /dev/urandom | tr -dc '0-9')
		# should in practice never happen
		while test "${#buf}" -lt "$1"; do
			buf=0${buf}
		done
	else
		i=0
		while true; do
			prand=$(sh -c 'echo $$')

			if test "$i" -eq 0; then
				timestamp=$(date +%Y%m%d%H%M%S)
				crc=$(printf %s "$prand" "$timestamp" | cksum | awk '{print $1}')
				buf=${buf}${crc}
			else
				crc=$(printf %s "$prand" "$i" | cksum | awk '{print $1}')
				buf=${buf}${crc}
			fi

			test "${#buf}" -ge "${1:-8}" && break || :
			i=$((i + 1))
		done
	fi

	printf '%.*s' "$1" "$buf"
)

if ! which seq >/dev/null; then
	seq()
	(
		i=$1
		while test $i -le $2; do
			printf '%s\n' "$i"
			i=$((i + 1))
		done
	)
fi

which()
{
	while IFS= read -r entry; do
		if test -f "$entry/$1"; then
			printf '%s\n' "$entry/$1"
			return 0
		fi
	done <<-EOF
		$(printf '%s\n' "$PATH" | tr : "$NEWLINE")
	EOF
	return 1
}

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
