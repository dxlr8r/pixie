#!/bin/sh

PIXIE_TEXT_SOURCED=true

PixieText()
{
	case "$1" in
	ensure-line)
		(
			shift
			PixieArgs kv-to-var "$@" __pixie_text_ensure_line_

			: ${__pixie_text_ensure_line_in:=-}
			if test "${__pixie_text_ensure_line_in:-}" = '-'; then
				__pixie_text_ensure_line_in=$(cat)
			fi

			in=$__pixie_text_ensure_line_in
			after=$__pixie_text_ensure_line_after
			match_re=$__pixie_text_ensure_line_match_re
			value=$__pixie_text_ensure_line_value

			# if already defined, escape early
			if printf %s\\n "$in" | grep -Fxq "$value"; then
				exit 0
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
			test -n "$line_number" || exit 1

			# insert/replace line in $file
			printf %s\\n "$in" | awk -v VALUE="$value" -v LINENUMBER="$line_number" -v APPEND="$append" '
			{
				if (NR == LINENUMBER) {
					print VALUE
			 		if (APPEND == 1) { print $0 }
				}
				else { print $0 }
			}'
		) || return $?
		;;
	esac
}

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Text=PixieText
fi
