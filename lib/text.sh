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

test "${BASE_SOURCED=-}" = 'true' || {
	printf %s\\n 'base must be sourced'
	return 1
}

Text()
{
	case "$1" in
	ensure-line)
		(
			_kvargs_to_var "$@" __text_ensure_line_
			if test "${1:-}" = '-' || test "${__text_ensure_line_in:-}" = '-' || test -z "${__text_ensure_line_in:-}"; then
				__text_ensure_line_in=$(cat)
			fi
			in=$__text_ensure_line_in
			after=$__text_ensure_line_after
			match_re=$__text_ensure_line_match_re
			value=$__text_ensure_line_value

			# if already defined, escape early
			if printf %s\\n "$in" | grep -Fxq "$value"; then
				return 0
			fi

			# search for match_re
			append=0
			line_number=$(printf %s\\n "$in" | awk -v REGEX="$match_re" '{if($0 ~ REGEX) {print NR; exit}}')

			# regex not found, search for after
			if test -z "$line_number"; then
				line_number=$(printf %s\\n "$in" | awk -v NEEDLE="$after" '{if($0 == NEEDLE) {print NR + 1; exit}}')
				append=1
			fi

			# if neither searches succeed, error
			test -n "$line_number" || return 1

			# insert/replace line in $file
			printf %s\\n "$in" | awk -v VALUE="$value" -v LINENUMBER="$line_number" -v APPEND="$append" '
			{
				if (NR == LINENUMBER) {
					print VALUE
			 		if (APPEND == 1) { print $0 }
				}
				else { print $0 }
			}'
		)
		;;
	esac
}
