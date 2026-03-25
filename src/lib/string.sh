#!/bin/sh

PIXIE_STRING_SOURCED=true

PixieString()
{
	case "$1" in

	# escape a string
	escape | esc)
		shift
		if test "$#" -eq 0; then
			set -- "$(cat)"
		fi
		awk '
	    BEGIN {
	      for (i = 1; i < ARGC; i++) {
	        s = ARGV[i]
	        ARGV[i] = ""
	        gsub(/\\/, "\\\\\\", s)
	        gsub(/\t/, "\\t", s)
	        gsub(/\n/, "\\n", s)
	        print s
	      }
	      exit
	    }
	  ' "$@"
		;;

	# un/de escape escaped sequences
	unesc | unescape)
		shift
		if test "$#" -eq 0; then
			set -- "$(cat)"
		fi
		printf '%b' "$@"
		;;

	# trim whitespace on each string given as an argument
	# left trim
	ltrim)
		shift
		while test $# -gt 0; do
			printf %s\\n "${1#"${1%%[![:space:]]*}"}"
			shift
		done
		;;
	# right trim
	rtrim)
		shift
		while test $# -gt 0; do
			printf %s\\n "${1%"${1##*[![:space:]]}"}"
			shift
		done
		;;
	# left and right trim
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
	# left, right trim then squeeze repeat whitespace to a single space
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

	# in string replace
	replace)
		(
			shift
			# TODO: fix prefix
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
