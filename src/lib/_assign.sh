#!/bin/sh

PixieAssign()
{
	case "${1-}" in
	here)
		shift
		if test -z "${1:-}"; then
			return 1
		elif test "$#" -eq 1; then
			eval "$1"'=$(cat)'
			# should be faster for smaller payloads
			# eval "${1}=\"\$(
			# 	while IFS='' read -r line; do
			# 		printf '%s\n' \"\$line\"
			# 	done
			# )\""
		elif test "$#" -gt 1; then
			eval "$1"'=$(shift; printf %s\\n "$@")'
		fi
		;;
	if-fn)
		shift
		__assignfn_cmd_var=$1
		shift
		__assignfn_cmd_out=$("$@")

		set -- "$__assignfn_cmd_var" "$__assignfn_cmd_out" "$?" "$@"
		unset __assignfn_cmd_var __assignfn_cmd_out

		if status $3; then
			eval "$1=\$2"
		fi

		return $3
		;;
	esac
}

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Assign=PixieAssign
fi

if test "${PIXIE_ASSIGN_ALIAS:-true}" = 'true'; then
	alias assign='PixieAssign'
	alias here='PixieAssign here'
fi
