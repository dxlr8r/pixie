#!/bin/sh

PixieArgs()
{
	case "$1" in
	kv-to-var)
		shift

		# add last argument (prefix) as first
		set -- "$(eval "printf '%s\n' \${$#}")" "$@"
		eval "${1}0=0"
		# remove first argument (prefix)
		shift

		# add number of arguments (not including self) as last argument
		set -- "$@" $#
		while test $# -gt 2; do
			# 1: current pair
			# ...: rest pairs
			# $#-1: prefix
			# $#: number of args
			set -- \
				"${1%%=*}" \
				"${1#*=}" \
				"$(eval "printf '%s\n' \${$(($# - 1))}")" \
				"$(eval "printf '%s\n' \${$#}")" \
				"$@"
			# 1: current pair key
			# 2: current pair value
			# 3: prefix
			# 4: number of args
			# 5: current pair
			# ...: rest pairs
			# $#-1: prefix
			# $#: number of args

			if test "$1" != "$5"; then
				case "${1-}" in
				[A-Za-z_] | [A-Za-z_][A-Za-z0-9_]*) : ;;
				*) return 1 ;;
				esac
				case "${3-}" in
				[A-Za-z_] | [A-Za-z_][A-Za-z0-9_]*) : ;;
				*) return 1 ;;
				esac

				eval "${3}${1}=\$2"

				eval "${3}0=\$((\$4 - \$# + 6))"
			elif test "$5" = '--'; then
				eval "${3}0=\$((\$4 - \$# + 6))"
				return 0
			else
				return 0
			fi

			shift 5

			# ...: rest pairs
			# $#: prefix
		done
		;;
	to-elist)
		shift
		(
			PixieArgs kv-to-var "$@" __pixie_args_to_elist_
			shift "$__pixie_args_to_elist_0"
			shift "${__pixie_args_to_elist_shift:-0}"
			PixieString esc "$@"
		)
		;;
	esac
}

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Args=PixieArgs
fi
