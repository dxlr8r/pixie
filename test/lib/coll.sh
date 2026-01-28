#!/bin/sh

set -e
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. ../../autolib/min/coll.sh

# add
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

# add-at rm-at
Coll my_coll rm-at-key 'status reactor' 1
Coll my_coll add-value-at 'status reactor' 1 'false'
Coll my_coll rm-at 'status reactor' 2
Coll my_coll add-at 'status reactor' 2 'true'
Coll my_coll -i 'status reactor' 0
Coll my_coll +i 'status reactor' 0 'false'

# get get-value
Coll my_coll get 'status reactor' 2 | awk '{printf substr($NF, 0, 1)}' | grep -Fxq 'ftff'
Coll my_coll get-value 'status reactor' | awk '{printf substr($NF, 0, 1)}' | grep -Fxq 'ftff'

# get with depth
Coll my_coll get 'status' 2:3 | test "$(wc -l)" -eq 14

# rm-key with depth
Coll my_coll rm-key 'status reactor' 2
Coll my_coll get-value 'status reactor temperatur' | test "$(cat)" -eq 200

# rmx-value
Coll my_coll rmx-value 'status reactor client' '^T'
Coll my_coll get-value 'status reactor client' | grep -Fxq 'Shuttlebay 2'

# rm-value
Coll my_coll rm-value 'status reactor client' 'Shuttlebay 2'
Coll my_coll get-value 'status reactor client' || {
	ret=$?
}
test "$ret" -eq 1

# get-pair
Coll my_coll get-pair 'status' \
	| sort -u | tr "$NEWLINE" : | grep -Fxq 'dilithium_reserves:reactor:'

# get-tail
Coll my_coll get-tail 'status reactor' | test "$(wc -l)" -eq 3

# get-enumerated
Coll my_coll get-enumerated 'status reactor' 3 | test "$(cat)" = "$(seq 1 3)"
