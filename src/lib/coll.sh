#!/bin/sh
# SPDX-FileCopyrightText: 2022-2026 Simen Strange <https://github.com/dxlr8r/argus>
# SPDX-License-Identifier: MIT
# Version: 0.4.0-alpha

# shellcheck disable=SC2154

PIXIE_COLL_SOURCED=true

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

		gen-min-and-max-depth)
			shift
			(
				# allow empty int
				depth="${1:-0}"

				IFS=':' read -r min_depth max_depth <<-EOF
					$(printf %s "$depth")
				EOF

				case "$depth" in
				*:) max_depth=0 ;;
				*:*) : ;;
				*) max_depth="$min_depth" ;;
				esac
				PixieIs unsigned-int "$min_depth" "$max_depth" || exit 1

				printf '%s:%s' "$min_depth" "$max_depth"
			) || return $?
			;;
		# like grep -v, but more suited handling of exit signals
		_grepv)
			shift
			(
				pat=$(printf '%s\n' "$1" | sed 's/Fx/==/' | sed 's/E/~/')
				cat | awk -v haystack="$2" 'BEGIN { needle=0 }; { if ($0 '"$pat"' haystack ) { needle=1 } else { print }}; END { exit !needle }' || exit $?
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

		# my_var add-value-at 'a b' 1 'hello'
		add-value-at | add-at | +i)
			PixieIs variable-name "${1-}" || return $?
			if test -n "${5+x}"; then
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
									else { exit 1 }
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
			PixieAssign if-fn "$1" PixieColl "$1" _rm-key "${3-}" "${4-}" || return $?
			;;

		_rm-key)
			(
				key=$(PixieColl % _normalise-key "$3") || exit $?

				eval obj=\$"$1"

				IFS=':' read -r min_depth max_depth <<-EOF || exit $?
					$(PixieColl % gen-min-and-max-depth "$4")
				EOF

				if test "$((min_depth + max_depth))" -eq 0; then
					# printf '%s' "$obj" | grep -E "^$key" || exit $?
					printf '%s' "$obj" | PixieColl % _grepv E "^$key" || exit $?
				else
					printf '%s' "$obj" \
						| awk -v FS='\t' -v OFS='\t' -v KEY="$key" -v NEEDLE='0' \
							-v MIN="$min_depth" -v MAX="$max_depth" \
							'{
									if(MAX > 0) {
										if(NF >= (MIN + 1) && NF <= (MAX + 1) && index($0, KEY) == 1){ NEEDLE=1 }
										else { print }
									}
									else {
										if(NF >= (MIN + 1) && index($0, KEY) == 1){ NEEDLE=1 }
										else { print }
									}
								}
								END { exit !NEEDLE }' || exit $?
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
				PixieIs populated "$4" || exit $?

				eval obj=\$"$1"
				re_val=$(printf '%s' "$4" | sed 's/\\/\\&/g')

				printf '%s' "$obj" | awk -v FS='\t' -v OFS='\t' \
					-v KEY="$key" -v RE_VAL="$re_val" -v NEEDLE='0' '
					BEGIN {
						KEYL = split(KEY, _)
					}
					{
						if(NF == KEYL && index($0, KEY) == 1 && $NF ~ RE_VAL) { NEEDLE=1 }
						else { print }
					}
					END { exit !NEEDLE }' || exit $?
			) || return $?
			;;

		# my_var rm-at-key 'a b' 1
		rm-at-key | rm-at | -i)
			PixieIs variable-name "${1-}" || return $?
			PixieAssign if-fn "$1" PixieColl "$1" _rm-at-key "${3-}" "${4-}" || return $?
			# PixieColl "$1" _rm-at-key "${3-}" "${4-}" || return $?
			;;

		# my_var get 'a b' 2
		get | g | @)
			(
				PixieIs variable-name "${1-}" || test "${1-}" = '-' || exit $?
				# allow empty key
				key=$(PixieColl % _normalise-key "${3-}" allow-empty) || exit $?

				IFS=':' read -r min_depth max_depth <<-EOF || exit $?
					$(PixieColl % gen-min-and-max-depth "${4-}")
				EOF

				if test "$1" = "-"; then
					obj=$(cat)
				else
					eval obj=\$"$1"
				fi
				# last key is int and is 0

				# 0:0 -> no depth
				if test "$((min_depth + max_depth))" -eq 0; then
					printf '%s' "$obj" | grep -E "^$key" || exit $?
				else
					printf '%s' "$obj" \
						| awk -v FS='\t' -v OFS='\t' -v KEY="$key" -v NEEDLE='0' \
							-v MIN="$min_depth" -v MAX="$max_depth" '
								{
									if(MAX > 0) {
										if(NF >= (MIN + 1) && NF <= (MAX + 1) && index($0, KEY) == 1) {
											NEEDLE=1; print
										}
									}
									else {
										if(NF >= (MIN + 1) && index($0, KEY) == 1) {
											NEEDLE=1; print
										}
									}
								}
								END { exit !NEEDLE }' || exit $?
				fi
			) || return $?
			;;

		# my_var get-value 'a'
		get-value | v | @v)
			(
				keys=$(printf '%s' "$3" | awk '{print NF}')
				PixieColl "${1-}" get "${3-}" "$keys" \
					| awk -v FS='\t' '{print $NF} END {exit !NR}' || exit $?
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
				out=$(PixieColl "$1" get "${3-}" "${4-}") || exit $?
				printf %s "$out" | awk '{print NR} END { exit !NR }' || exit $?
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
