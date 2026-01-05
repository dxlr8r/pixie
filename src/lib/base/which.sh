#!/bin/sh

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
