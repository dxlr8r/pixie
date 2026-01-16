#!/bin/sh
# SPDX-FileCopyrightText: 2022-2026 Simen Strange <https://github.com/dxlr8r/argus>
# SPDX-License-Identifier: MIT
# Version: 0.4.0-alpha

# shellcheck disable=SC2154

PIXIE_COLL_SOURCED=true

# TODO: create List, subset of coll. We have removed possibility of optional 'key' after porting from argus. As it has some issues, especially with _rm-at (is 1 the key, or the item/index?).
#
# List, would just be wrapper around PixieColl, and store everything to a key called '_'. This allows for (alias list):
# list my_list add 'foo'
# list my_list add 'bar'
# list my_list rm-at 2

PixieColl()
{
	# `PixieColl` has two conflicting ways to order arguments
	# 1: `fn arg...`
	# 2: `var_name fn arg...`
	# To avoid collisions we prefix #1 with a sign not allowed in a variable:
	# 1: `PixieColl % fn ...`
	# 2: `PixieColl var_name fn ...`

	case "${1-}" in
	# helper functions
	%)
		shift
		case "${1-}" in

		# remove leading, trailing and repeating whitespace
		_normalise-key)
			shift
			(
				key=$(PixieString strim "$1")
				opt=$(printf '%s\n' "${2-}" | tr ',' "$NEWLINE")

				if test -n "$key"; then
					printf '%s ' "$key" | tr ' ' "$TABULATOR"
				else
					if PixieIs member 'allow-empty' "$opt"; then
						:
					else
						exit 1
					fi
				fi
			) || return $?
			;;

		# if any argument is empty or only contains whitespace return 1
		# _has_visible)
		# 	shift
		# 	while test "$#" -gt 0; do
		# 		printf '%s' "$1" | awk '{if ($0 ~ /(^$|[[:space:]])/) exit 1} END {if (NR != 1) exit 3}' \
		# 			|| return $?
		# 		shift
		# 	done
		# 	;;

		# like grep -v, but more suited handling of exit signals
		_grepv)
			shift
			(
				pat=$(printf '%s\n' "$1" | sed 's/Fx/==/' | sed 's/E/~/')
				cat | awk -v haystack="$2" 'BEGIN { needle=0 }; { if ($0 '"$pat"' haystack ) { needle=1 } else { print }}; END { exit !needle }' || exit $?
			) || return $?
			;;

		_if-last-key-is-int-remove-it)
			shift
			# first strip trailing tab from key, as value is not added. Then check if last key is an integer, if true remove last key
			awk -v key="$1" -v OFS='\t' 'BEGIN { $0 = key; sub(/[ \t]*$/, "", $0); if ($NF ~ /^[0-9]+$/) {$NF=""; print; exit 0} else {exit 1}}' || return $?
			;;

		_ilist-add-or-rm)
			shift
			(
				action=$1
				key=$2
				value=$3
				obj=$4

				# number of columns of keys
				qty_keys=$(printf '%s' "$key" | tr "$TABULATOR" "$NEWLINE" | wc -l | tr -d ' ')
				rkey=$(PixieColl % _if-last-key-is-int-remove-it "$key") || exit $?
				# regex=$(printf '^%s[0-9]+\\t' "$(PixieString esc "$rkey")" | sed 's/\\t/[[:blank:]]/g')
				regex="^${rkey}[0-9]+\t"

				# requested index of entry
				idx=$(printf '%s' "$key" | awk -v FS='\t' '{print $(NF-1)}')

				# determine the highest index currently available
				fallback_max_idx=$(printf '%s0\t\n' "$rkey")
				max_idx=$(printf '%s\n' "$fallback_max_idx" "$obj" | grep -E "$regex" | sort -nk$qty_keys | tail -n1 \
					| awk -v FS='\t' -v qty_keys="$qty_keys" '{print $(qty_keys)}')

				if test "$action" = "add"; then
					# increase rows
					alter_rows='
					{
						if ($0 ~ regex && $(qty_keys) >= idx)
							{ $(qty_keys)=$(qty_keys)+1; print }
						else print
					}'
				fi

				if test "$action" = "rm"; then
					# decrease rows
					alter_rows='
					{
						if ($0 ~ regex && $(qty_keys) > idx)
							{ $(qty_keys)=$(qty_keys)-1; print }
						else print
					}'
				fi

				# check if idx is valid if not replace with max_idx
				# if test $idx -gt $max_idx || test $idx -eq 0; then
				if test $idx -eq 0; then
					test "$action" = "add" && idx=$((max_idx + 1)) || :
					test "$action" = "rm" && idx=$max_idx || :
					key=$(printf '%s' "$key" | awk -v FS='\t' -v OFS='\t' -v new_idx="$idx" -v qty_keys="$qty_keys" '$(qty_keys) = new_idx')
				fi

				# if out of bounds, return
				#test $idx -gt $max_idx && { printf '%s' "$obj"; return 1; } || :

				# rm element
				test "$action" = "rm" && obj=$(printf '%s' "$obj" | grep -vE "^$key") || :

				# print obj and reorder
				test -n "$obj" && printf '%s\n' "$obj" | awk -v FS='\t' -v OFS='\t' -v qty_keys="$qty_keys" -v idx="$idx" -v regex="$regex" "$alter_rows" || :

				# add element
				test "$action" = "add" && printf "%s%s\n" "$key" "$value" || :
			) || return $?
			;;
		*)
			return 1
			;;
		esac
		;;
	# primary functions
	*)
		# $1 is the name of the variable
		# $2 is the name of the function
		case "${2-}" in

		# my_var add-value 'a b' 'hello'
		add-value | add | +)
			PixieIs variable-name "${1-}" || return $?
			if test -n "${4+x}"; then
				PixieAssign if-fn "$1" PixieColl "$1" _add-value-at "$3" 0 "$(PixieArgs to-elist shift=3 -- "$@")" || return $?
			else
				PixieAssign if-fn "$1" PixieColl "$1" _add-value-at "${3-}" 0 "$(cat | PixieString esc)" || return $?
			fi
			;;

		# subshell to keep variables local
		# _add-value)
		# 	(
		# 		key=$(PixieColl % _normalise-key "$3") || exit $?

		# 		# set obj to variable named $1
		# 		eval obj=\$"$1"
		# 		shift 3

		# 		if test "$ARGUS_NILIST" && PixieColl % _if-last-key-is-int-remove-it "$key" >/dev/null; then
		# 			# value=$(PixieString esc "$1")
		# 			# PixieColl % _ilist-add-or-rm "add" "$key" "$value" "$obj" || exit $?
		# 			:
		# 		else
		# 			test -n "$obj" && printf '%s\n' "$obj" || :
		# 			while test $# -gt 0; do
		# 				value=$(PixieString esc "$1")
		# 				printf "%s%s\n" "$key" "$value"
		# 				shift
		# 			done
		# 		fi
		# 	) || return $?
		# 	# status || {
		# 	# 	eval printf %s \"\$$1\"
		# 	# 	return $?
		# 	# }
		# 	;;

		# my_var add-value-at 'a b' 1 'hello'
		add-value-at | add-at | +i)
			PixieIs variable-name "${1-}" || return $?
			if test -n "${5+x}"; then
				# PixieArgs to-elist shift=4 -- "$@"
				# PixieColl "$1" _add-value-at "$3" "$4" "$(PixieArgs to-elist shift=4 -- "$@")"
				PixieAssign if-fn "$1" PixieColl "$1" _add-value-at "$3" "$4" "$(PixieArgs to-elist shift=4 -- "$@")" || return $?
			else
				PixieAssign if-fn "$1" PixieColl "$1" _add-value-at "${3-}" "${4-}" "$(cat | PixieString esc)" || return $?
			fi
			;;

		_add-value-at | _rm-at-key)
			(
				key=$(PixieColl % _normalise-key "$3") || exit $?
				PixieIs unsigned-int "$4" || exit $?

				eval obj=\$"$1"
				test "$2" = '_add-value-at' && op='add' || op='rm'
				idx=$4

				line=$(printf '%s' "$obj" \
					| awk -v FS='\t' -v OFS='\t' \
						-v IDX="$idx" -v KEY="${key}" -v OP="$op" '
							BEGIN {
								LINE=0
								KNR=0
								KEYL = split(KEY, _)
							}
							{
								# if same amount of rows && $0 starts with KEY
								if(NF == KEYL && index($0, KEY) == 1) {
									KNR=KNR + 1
									LINE=NR
									if(IDX == KNR) { exit }
								}
							}
							END {
								# if not found
								if (LINE == 0) {
									if(OP == "add") {
										# if IDX 0 or 1, add to bottom (0)
										if(IDX >= 0 && IDX <= 1) { print 0 }
									}
									# not found, exit 1
									else if(OP == "rm") { exit 1 }
								}
								# out of bounds
								else if(IDX > KNR) { exit 1 }
								else { print LINE }
							}') || exit $?

				# might be faster than doing esc twice?
				# $5 needs to pre applied with esc()
				# values=''
				# while IFS='' read -r "value"; do
				# 	values="${values}${key}${value}${NEWLINE}"
				# done <<-EOF
				# 	$(printf '%s\n' "${5-}")
				# EOF

				if test -n "${5-}"; then
					values=$(PixieString esc "${5-}")
				else
					values=''
				fi

				printf '%s' "$obj" \
					| awk -v FS='\t' -v OFS='\t' \
						-v IDX="$idx" -v LINE="$line" -v KEY="${key}" -v VAL="$values" -v OP="$op" '
						function gen_key_values(STR, PREFIX, LEN, ARR, OUT, i) {
							# LEN=split(STR, ARR, "\n")
							# OUT=""
							# for (i=1; i <= LEN; i++) {
							# 	OUT = sprintf("%s%s%s", OUT, PREFIX, ARR[i])
							# }
							# return OUT

							NL_TAIL = (STR ~ /\n$/)
							STR = PREFIX STR
							gsub(/\n/, "\n" PREFIX, STR)
							if (!NL_TAIL) STR = STR "\n"
							return STR
						}
						BEGIN {
							KEY_VALUES=gen_key_values(VAL, KEY)
						}
						{
							if (OP == "add") {
								if(LINE == NR && IDX > 0) {
									# print before
									printf "%s%s\n", KEY_VALUES, $0
									IDX=-1
								}
								else if (LINE == NR && IDX == 0) {
									# print after
									printf "%s\n%s", $0, KEY_VALUES
									IDX=-1
								}
								else { print }
							}
							# rm
							else {
								if(LINE != NR) { print }
							}
						}
						END {
							# LINE not found, but IDX is 0 or 1, so insert at bottom
							if(OP == "add" && IDX >= 0 && IDX <= 1) {
								printf "%s", KEY_VALUES
							}
						}' || exit $?
			) || return $?
			;;

		# my_var rm_key 'a'
		rm-key | -)
			PixieIs variable-name "${1-}" || return $?
			PixieAssign if-fn "$1" PixieColl "$1" _rm-key "${3-}" || return $?
			;;

		_rm-key)
			(
				key=$(PixieColl % _normalise-key "$3") || exit $?

				eval obj=\$"$1"

				# if the last key is an int, fill it's gap
				if test "$ARGUS_NILIST" && PixieColl % _if-last-key-is-int-remove-it "$key" >/dev/null; then
					PixieColl % _ilist-add-or-rm "rm" "$key" "$value" "$obj" || exit $?
				else
					if test -n "$obj"; then
						printf '%s' "$obj" | PixieColl % _grepv E "^$key" || exit $?
					fi
				fi
			) || return $?
			;;

		# my_var rm-value 'a b' 'hello'
		rm-value | -v)
			PixieIs variable-name "${1-}" || return $?
			PixieAssign if-fn "$1" PixieColl "$1" _rm-value "${3-}" "${4-}" || return $?
			;;

		_rm-value)
			(
				key=$(PixieColl % _normalise-key "$3") || exit $?

				eval obj=\$"$1"
				value=$4

				# printf '%s' "$obj" | grep -Fvx "${key}${value}"
				printf '%s' "$obj" | PixieColl % _grepv Fx "${key}${value}" || exit $?
			) || return $?
			;;

		# my_var rmx-value 'a b' 'he.*'
		rmx-value | -x)
			PixieIs variable-name "${1-}" || return $?
			PixieAssign if-fn "$1" PixieColl "$1" _rmx-value "${3-}" "${4-}" || return $?
			;;

		_rmx-value)
			(
				key=$(PixieColl % _normalise-key "$3") || exit $?
				PixieIs is-populated "$4" || exit $?

				eval obj=\$"$1"
				value=$(printf '%s' "$4" | sed 's/\\/\\&/g')

				# printf '%s' "$obj" | grep -vE "^${key}${value}\$"
				printf '%s' "$obj" | PixieColl % _grepv E "^${key}${value}\$" || exit $?
			) || return $?
			;;

		# my_var rm-at-key 'a b' 1
		rm-at-key | rm-at | -i)
			PixieIs variable-name "${1-}" || return $?
			PixieAssign if-fn "$1" PixieColl "$1" _rm-at-key "${3-}" "${4-}" || return $?
			# PixieColl "$1" _rm-at-key "${3-}" "${4-}" || return $?
			;;

		# TODO: allow user to only get specified key, with no siblings
		# my_var get 'a b' 2
		get | g | @)
			(
				PixieIs variable-name "${1-}" || test "${1-}" = '-' || exit $?
				# allow empty key
				key=$(PixieColl % _normalise-key "${3-}" allow-empty) || exit $?
				# allow empty int
				depth="${4:-0}"
				PixieIs unsigned-int "$4"

				if test "$1" = "-"; then
					obj=$(cat)
				else
					eval obj=\$"$1"
				fi
				# last key is int and is 0
				if
					test -n "$ARGUS_NILIST" \
						&& rkey=$(PixieColl % _if-last-key-is-int-remove-it "$key") \
						&& awk -v key="$key" 'BEGIN { $0 = key; if ($NF != 0) {exit 1} }'
				then
					regex="^${rkey}[-]?[0-9]+[[:blank:]]"
					printf '%s' "$obj" | grep -E "$regex" | tail -n1 | awk '{print} END { exit !NR }' || exit $?
				else
					if test "$depth" -eq 0; then
						printf '%s' "$obj" | grep -E "^$key" || exit $?
					else
						# if(NF == KEYL && index($0, KEY) == 1) {
						printf '%s' "$obj" | awk -v FS='\t' -v OFS='\t' -v KEY="$key" -v DEPTH="$depth" \
							'{if($0 ~ ("^" KEY) && NF == (DEPTH + 1)) {print}}'
					fi
				fi
			) || return $?
			;;

		# my_var get-value 'a'
		get-value | v | @v)
			(
				# TODO: calculate keys before out, and send it to PixieColl as the depth argument
				out=$(PixieColl "${1-}" get "${3-}" 0) || exit $?
				keys=$(printf '%s' "$3" | awk '{print NF}')

				# if(NF == KEYL && index($0, KEY) == 1) {
				printf %s "$out" | awk -v rkey="$3" -v keys="$keys" -v FS='\t' '{if (NF == keys+1 || rkey == "") { print $NF }} END { exit !NR }' || exit $?
			) || return $?
			;;

		# my_var get-pair 'a'
		get-pair | @p)
			(
				out=$(PixieColl "${1-}" get "${3-}" 0) || exit $?
				key=$(PixieColl % _normalise-key "$3" allow-empty) || exit $?

				printf %s "$out" | awk -v key="$key" '{print substr($0, length(key)+1) }' | awk -v FS='\t' '{print $1} END { exit !NR }' || exit $?
			) || return $?
			;;

		# my_var get-tail 'a b'
		get-tail | @t)
			(
				out=$(PixieColl "${1-}" get "${3-}" 0) || exit $?
				key=$(PixieColl % _normalise-key "$3" allow-empty) || exit $?

				printf %s "$out" | awk -v key="$key" '{print substr($0, length(key)+1) } END { exit !NR }' || exit $?
			) || return $?
			;;

			# my_var get-at 'a b' 1 2 # last is depth
		get-at | @i)
			(
				PixieIs unsigned-int "${4-}" || exit $?
				idx=$4
				out=$(PixieColl "$1" get "${3-}" "${5:-0}") || exit $?
				printf %s "$out" | awk -v item="$idx" 'BEGIN {found=0} {if (NR==item) {print; found=1}} END { if (!found && item==0) {print} else if (!found && item > 0) {exit 1}}' || exit $?
			) || return $?
			;;

		# my_var get-enumerated 'a b' 2
		get-enumerated | enum | @e)
			(
				out=$(PixieColl "$1" get "${3-}" "${4:-0}") || exit $?
				printf %s "$out" | awk '{print NR} END { exit !NR }' || exit $?
			) || return $?
			;;

		pack-ilist | pack)
			test "$ARGUS_NILIST" || return 1
			PixieAssign if-fn "$1" PixieColl "$1" _pack-ilist "${3-}" || return $?
			;;

		_pack-ilist)
			(
				key=$(PixieColl % _normalise-key "$3") || exit $?

				eval obj=\$"$1"
				keys=$(printf '%s' "$key" | tr "$TABULATOR" "$NEWLINE" | wc -l)
				ffkey=$((keys + 1))
				sfkey=$((keys + 2))
				# match key that are followed by an int
				regex="^${key}[-]?[0-9]+[[:blank:]]"

				# filter and sort out fields to enumerate
				enumerate=$(printf '%s' "$obj" | grep -E "$regex" | sort -nk$ffkey)
				printf '%s' "$enumerate" | awk -v ffkey="$ffkey" -v sfkey="$sfkey" -v FS='\t' -v OFS='\t' \
					'# init enumerator, previous, current & current next column
					BEGIN { e=0; pcol=e; ccol=e; cncol=e; }
					{
						ccol=$(ffkey);
						cncol=$(sfkey);
						# if first run OR ccol > pcol OR next cncol is non int
						if(e == 0 || ccol > pcol || cncol !~ /^[0-9]+$/ ) { e=e+1 };
						$(ffkey)=e; pcol=ccol; print
					}'

				# filter out fields not to enumurate
				printf '%s' "$obj" | grep -vE "$regex"
			) || return $?
			;;
		*)
			return 1
			;;
		esac
		;;
	esac
}

if test "${PIXIE_ALIAS:-true}" = 'true'; then
	alias Coll=PixieColl
fi

if test "${PIXIE_COLL_ALIAS:-true}" = 'true'; then
	alias coll=PixieColl
fi
