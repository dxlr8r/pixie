#!/bin/sh

set -Ceu

p_heredoc() {
  eval "${1}=''"
  while IFS='
' read -r line; do
    eval "${1}=\"\${${1}}\${line}
\""
  done
}


p_defns() {
  p_heredoc "$1"

  if test -n "$2" && test "$2" == "_" ; then
    # add `$1() ` to heredoc
    eval "${1}=\$(printf '%s' \"$1\" '()' ' ' \"\${${1}}\")"
  fi

  # execute function
  eval "eval \"\$${1}\""

  # TODO: export variable
}


p_defn() {
  p_defns "$1" "_"
}


p_defn ps_heredoc <<'EOF'
{
  p_heredoc "$1" "$2"
  eval "${1}=\$(printf \"\${${1}}\" | ps_enc)"
}
EOF


p_defn prn <<'EOF'
{
  printf "%s " "$@"
  printf '\n'
}
EOF


p_defns ps_enc <<'EOF'
ps_enc_() {
  if which base64 >/dev/null; then
    base64 | tr -d '\n' | xargs
  elif which uuencode >/dev/null; then
    uuencode -m /dev/stdout | awk 'NR>2 {printf last} {last=$0}' | xargs
  fi
}
ps_enc() {
  if test -n "$1"; then
    printf "%s" "$@" | ps_enc_
  else
    ps_enc_
  fi
}
EOF


p_defns ps_dec <<'EOF'
ps_dec_() {
  while read -r line; do
    if which base64 >/dev/null; then
      printf "$line" | base64 --decode
    elif which uuencode >/dev/null; then
      printf '%s\n%s\n%s\n' 'begin-base64 644 /dev/stdout' "$line" '====' | uudecode
    fi
  done
}

ps_dec() {
  if test -n "$1"; then
    printf "%s\n" "$@" | ps_dec_
  else
    xargs | ps_dec_
  fi 
}
EOF


p_defns prn <<'EOF'
prn() {
  printf "%s " "$@"
  printf '\n'
}
EOF


# find . -maxdepth 1 -exec sh -c 'eval "${ps_enc}"; printf "{}" | ps_enc' \;
