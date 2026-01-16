#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/coll.sh

# Coll my_coll add

here my_import <<EOF
name;Argus Array
description type;Subspace telescope
description operator;Starfleet
description quadrant;alpha
description energy_source;fusion reactor
status reactor temperatur;200
status reactor current_output;34
status reactor max_output;67
status reactor client;Ten Forward
status reactor client;The Bridge
status reactor client;Shuttlebay 2
status reactor;true
status reactor;false
status reactor;false
status reactor;true
status dilithium_reserves deneva;1337
status dilithium_reserves io;521
status dilithium_reserves elas;5147
status dilithium_reserves remus;217
EOF

while IFS=';' read key value; do
	Coll my_coll add "$key" "$value"
done <<-EOF
	$(printf '%s\n' "$my_import")
EOF

# Coll my_coll get | nl -n rn -w2

# Coll my_coll {add,rm}-at
Coll my_coll rm-at 'status reactor' 1
Coll my_coll add-at 'status reactor' 1 'false'
Coll my_coll rm-at 'status reactor' 2
Coll my_coll add-at 'status reactor' 2 'true'
Coll my_coll rm-at 'status reactor' 0
Coll my_coll add-at 'status reactor' 0 'false'

Coll my_coll get 'status reactor' 2 | awk '{printf substr($NF, 0, 1)}' | test "$(cat)" = 'ftff'
Coll my_coll get-value 'status reactor' | awk '{printf substr($NF, 0, 1)}' | test "$(cat)" = 'ftff'

Coll my_coll get 'status' 2:3 | test "$(wc -l)" -eq 14
