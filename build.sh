#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
cd ./src/lib/
LC_ALL=C

for el in ./*.sh; do
	. "$el"
done

build()
(
	PixieArgs kv-to-var "$@" _
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
		target="../../autolib/$_subdir/$_lib"
	else
		target="../../autolib/$_lib"
	fi

	awk '{
		if(NR==1 && /^#!/) {SB=$0; print}
		# if($0 != SB) {print}
		if(NR>1 && $0 !~ /^[[:blank:]]*#/) {print}
	}' "$@" | tee "$target" >/dev/null
)

build require=. lib=pixie.sh

# min

build require=%pixie.sh:_args.sh:_assign.sh:_is.sh:string.sh subdir=min lib=pixie.sh
build require=%pixie.sh:_args.sh:_assign.sh:_is.sh:string.sh subdir=min lib=coll.sh
build subdir=min lib=math.sh
build require=%pixie.sh:_args.sh subdir=min lib=string.sh
build require=%pixie.sh:_args.sh subdir=min lib=text.sh
