#!/bin/sh

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
