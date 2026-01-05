#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
cd ./src/lib/

for el in ./base/*.sh; do
	. "$el"
done

build()
(
	_kvargs_to_var "$@" _
	set --

	while IFS='' read entry; do
		if test -f "$entry"; then
			set -- "$@" "$entry"
		elif test -d "$entry"; then
			for item in "$entry/"*.sh; do
				test -f "$item" \
					&& set -- "$@" "$item" || :
			done

		fi
	done <<-EOF
		$(printf '%s\n' "$_require" | tr ':' "$NEWLINE")
	EOF

	if test -f "$_lib"; then
		set -- "$@" "$_lib"
	fi

	if test -n "${_subdir:-}"; then
		target="../../lib/$_subdir/$_lib"
	else
		target="../../lib/$_lib"
	fi

	awk '{
		if(NR==1 && /^#!/) {SB=$0; print}
		if($0 != SB) {print}
	}' "$@" | tee "$target" >/dev/null
)

build require=base lib=base.sh
build require=base lib=ext.sh
build require=base:. lib=all.sh

build require=base lib=math.sh
build require=base lib=string.sh
build require=base lib=text.sh

# min

build lib=math.sh subdir=min
build require=base/_.sh:base/_kvargs_to_var.sh lib=string.sh subdir=min
build require=base/_.sh:base/_kvargs_to_var.sh lib=text.sh subdir=min

# ext

build require=base:ext.sh lib=math.sh subdir=ext
build require=base:ext.sh lib=string.sh subdir=ext
build require=base:ext.sh lib=text.sh subdir=ext
