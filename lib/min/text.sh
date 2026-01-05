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
