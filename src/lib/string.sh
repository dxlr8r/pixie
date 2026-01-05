#!/bin/sh

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
