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

def()
{
	if test -z "${1:-}"; then
		return 1
	elif test "$#" -ge 2; then
		def "$1" <<-EOF
			$(
				shift
				printf %s\\n "$@"
			)
		EOF
	else
		eval "${1}=\"\$(
			while IFS='' read -r line; do
				printf '%s\n' \"\$line\"
			done
		)\""
	fi
}

loop()
{
	while IFS='' read -r "${1:-}"; do
		"${3:-}"
	done <<-EOF
		$(printf '%s\n' "$2")
	EOF
}

nloop()
{
	_kvargs_to_var "$@" __nloop_
	while IFS='' read -r "${__nloop_var:-entry}"; do
		"${__nloop_fn:-_}"
	done <<-EOF
		$(printf '%s\n' "$__nloop_list")
	EOF
	unset __nloop_var __nloop_list __nloop_fn
}

test "${BASE_SOURCED=-}" = 'true' || {
	printf %s\\n 'base must be sourced'
	return 1
}

String()
{
	case "$1" in
	replace)
		(
			shift
			_kvargs_to_var "$@" __str_replace_
			if test "${1:-}" = '-' || test "${__str_replace_in:-}" = '-' || test -z "${__str_replace_in:-}"; then
				__str_replace_in=$(cat)
			fi

			awk -v VALUE="$__str_replace_value" -v MATCH="$__str_replace_match" -v IN="$__str_replace_in" '
				BEGIN {
					VALUE_L=length(VALUE);
					for(i=1; i <= length(IN);) {
						f=0;
						for(j=1; j <= VALUE_L; j++) {
							if (substr(IN, i+j-1, 1) == substr(VALUE, j, 1)) {f++}
						}
						if (f==VALUE_L) { printf "%s", MATCH; i=i+=VALUE_L }
						else {printf "%s", substr(IN, i, 1); i++}
					}
					printf "\n"
				}'
		)
		;;
	esac
}

if test "${STRING_ALIAS:-false}" = 'true'; then
	str_replace()
	(String replace value="$1" match="$2" in="${3:--}")
fi
