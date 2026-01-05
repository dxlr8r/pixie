#!/bin/sh

test "${BASE_SOURCED=-}" = 'true' || {
	printf %s\\n 'base must be sourced'
	return 1
}

def()
{
	if test -z "${1:-}"; then
		return 1
	elif test "$#" -ge 2; then
		def "$1" <<-EOF
			$(
				shift
				printf %s\\n "$@"
			)
		EOF
	else
		eval "${1}=\"\$(
			while IFS='' read -r line; do
				printf '%s\n' \"\$line\"
			done
		)\""
	fi
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
	_kvargs_to_var "$@" __nloop_
	while IFS='' read -r "${__nloop_var:-entry}"; do
		"${__nloop_fn:-_}"
	done <<-EOF
		$(printf '%s\n' "$__nloop_list")
	EOF
	unset __nloop_var __nloop_list __nloop_fn
}
