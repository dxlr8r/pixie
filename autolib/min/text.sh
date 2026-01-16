#!/bin/sh

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
	PixieArgs kv-to-var "$@" __nloop_
	while IFS='' read -r "${__nloop_var:-entry}"; do
		"${__nloop_fn:-_}"
	done <<-EOF
		$(printf '%s\n' "$__nloop_list")
	EOF
	unset __nloop_var __nloop_list __nloop_fn
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

PIXIE_TEXT_SOURCED=true

PixieText()
{
	case "$1" in
	ensure-line)
		(
			PixieArgs kv-to-var "$@" __text_ensure_line_
			if test "${1:-}" = '-' || test "${__text_ensure_line_in:-}" = '-' || test -z "${__text_ensure_line_in:-}"; then
				__text_ensure_line_in=$(cat)
			fi
			in=$__text_ensure_line_in
			after=$__text_ensure_line_after
			match_re=$__text_ensure_line_match_re
			value=$__text_ensure_line_value

			if printf %s\\n "$in" | grep -Fxq "$value"; then
				return 0
			fi

			append=0
			line_number=$(printf %s\\n "$in" | awk -v REGEX="$match_re" '{if($0 ~ REGEX) {print NR; exit}}')

			if test -z "$line_number"; then
				line_number=$(printf %s\\n "$in" | awk -v NEEDLE="$after" '{if($0 == NEEDLE) {print NR + 1; exit}}')
				append=1
			fi

			test -n "$line_number" || return 1

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

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Text=PixieText
fi
