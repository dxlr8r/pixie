#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
VERSION=$(cat VERSION)

cd ./src/lib/
LC_ALL=C

for el in ./*.sh; do
	. "$el"
done

here legal <<-EOF
	# SPDX-FileCopyrightText: 2022-2026 Simen Strange <https://github.com/dxlr8r/pixie>
	# SPDX-License-Identifier: MIT
	# Version: $VERSION
EOF

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

	awk -v LEGAL="$legal" '{
		if(NR==1 && /^#!/) {SB=$0; printf "%s\n%s\n", $0, LEGAL }
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
