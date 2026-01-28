#!/bin/sh
# SPDX-FileCopyrightText: 2022-2026 Simen Strange <https://github.com/dxlr8r/pixie>
# SPDX-License-Identifier: MIT
# Version: 0.0.2-beta

PIXIE_SOURCED=true

NEWLINE='
'
TABULATOR='	'
: ${TMPDIR:=/tmp}

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
	PixieArgs kv-to-var "$@" __pixie_nloop_
	while IFS='' read -r "${__pixie_nloop_var:-entry}"; do
		"${__pixie_nloop_fn:-_}"
	done <<-EOF
		$(printf '%s\n' "$__pixie_nloop_list")
	EOF
	unset __pixie_nloop_var __pixie_nloop_list __pixie_nloop_fn
}

prnl()
{
	if test $# -eq 0; then
		set -- "$(cat)"
	fi
	printf -- %s\\n "$@"
}

prn()
{
	if test $# -eq 0; then
		set -- "$(cat)"
	fi
	prnl "$@" | paste -sd' '
}

random()
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
alias rand=random

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

status()
{
	return ${1:-$?}
}

PixieArgs()
{
	case "$1" in
	kv-to-var)
		shift

		set -- "$(eval "printf '%s\n' \${$#}")" "$@"
		eval "${1}0=0"
		shift

		set -- "$@" $#
		while test $# -gt 2; do
			set -- \
				"${1%%=*}" \
				"${1#*=}" \
				"$(eval "printf '%s\n' \${$(($# - 1))}")" \
				"$(eval "printf '%s\n' \${$#}")" \
				"$@"

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

PixieAssign()
{
	case "${1-}" in
	here)
		shift
		if test -z "${1:-}"; then
			return 1
		elif test "$#" -eq 1; then
			eval "$1"'=$(cat)'
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
	populated)
		shift
		while test "$#" -gt 0; do
			test "$1" || return $?
			shift
		done
		;;
	visible)
		shift
		while test "$#" -gt 0; do
			printf %s "$1" | tr -d '[:space:]' | test -n "$(cat)" || return $?
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
	*)
		return 1
		;;
	esac
}

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Is=PixieIs
fi

if test "${PIXIE_IS_ALIAS:-true}" = 'true'; then
	alias is='PixieIs'
fi

PIXIE_STRING_SOURCED=true

PixieString()
{
	case "$1" in

	escape | esc)
		shift
		if test "$#" -eq 0; then
			set -- "$(cat)"
		fi
		while test "$#" -gt 0; do
			if test -n "$1"; then
				printf '%s_' "$1" | sed 's/\\/\\&/g' | awk -v RS='\t' -v ORS='\\t' 1 | awk -v ORS='\\n' 1 | awk '{ printf "%s", substr($0, 1, length($0)-5) }'
			fi
			shift
			printf \\n
		done
		;;

	unesc | unescape)
		shift
		if test "$#" -eq 0; then
			set -- "$(cat)"
		fi
		printf '%b' "$@"
		;;

	ltrim)
		shift
		while test $# -gt 0; do
			printf %s\\n "${1#"${1%%[![:space:]]*}"}"
			shift
		done
		;;
	rtrim)
		shift
		while test $# -gt 0; do
			printf %s\\n "${1%"${1##*[![:space:]]}"}"
			shift
		done
		;;
	trim)
		shift
		while test $# -gt 0; do
			(
				s=$1
				s=${s#"${s%%[![:space:]]*}"}
				s=${s%"${s##*[![:space:]]}"}
				printf %s\\n "$s"
			)
			shift
		done
		;;
	strim)
		shift
		while test $# -gt 0; do
			(
				set -f
				set -- $1
				printf %s\\n "$*"
			)
			shift
		done
		;;

	replace)
		(
			shift
			PixieArgs kv-to-var "$@" __pixie_string_replace_
			shift $__pixie_string_replace_0

			: ${__pixie_string_replace_value=$1}
			: ${__pixie_string_replace_match:=$2}
			: ${__pixie_string_replace_in:=$3}

			case "$__pixie_string_replace_in" in
			- | '') __pixie_string_replace_in=$(cat) ;;
			esac

			awk -v VALUE="$__pixie_string_replace_value" -v MATCH="$__pixie_string_replace_match" -v IN="$__pixie_string_replace_in" '
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

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias String=PixieString
fi

if test "${PIXIE_STRING_ALIAS:-true}" = 'true'; then
	alias str_replace='PixieString replace'
	alias str_esc='PixieString escape'
	alias str_unesc='PixieString unescape'
fi
