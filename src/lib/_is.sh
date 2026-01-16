#!/bin/sh

PixieIs()
{
	case "$1" in
	in-list | member)
		(
			shift
			while IFS='' read -r line; do
				test "$1" = "$line" && exit 0 || continue
			done <<-EOF
				$(printf '%s\n' "$2")
			EOF
			exit 1
		) || return $?
		;;
	# if any argument is not a valid variable name return 1
	variable-name)
		shift
		(
			LC_ALL=C
			while test "$#" -gt 0; do
				case "${1-}" in
				[A-Za-z_] | [A-Za-z_][A-Za-z0-9_]*) : ;;
				*) exit 1 ;;
				esac
				shift
			done
		) || return $?
		;;
	# if any argument is empty return 1
	is-populated)
		shift
		while test "$#" -gt 0; do
			test "$1" || return $?
			shift
		done
		;;
	unsigned-int)
		shift
		while test $# -gt 0; do
			case "${1-}" in
			[0-9] | [1-9][0-9]*) : ;;
			*) return 1 ;;
			esac
			shift
		done
		;;
	int)
		shift
		while test $# -gt 0; do
			case "${1-}" in
			[0-9] | [1-9][0-9]*) : ;;
			-[0-9] | -[1-9][0-9]*) : ;;
			*) return 1 ;;
			esac
			shift
		done
		;;
	esac
}

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Is=PixieIs
fi

if test "${PIXIE_IS_ALIAS:-true}" = 'true'; then
	alias is='PixieIs'
fi
