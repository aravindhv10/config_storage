#!/bin/sh
cd "$(dirname -- "${0}")"

. "${HOME}/important_functions.sh"

TOPOLOGY="$(realpath './topology.yaml')"

echo 'Download and install TiUP START' \
     && adown \
        'https://tiup-mirrors.pingcap.com/install.sh' \
        'install_tidb.sh' \
        '71aa8e9789bd8dbc1e35c417aabee19aadfed282abd50b329b3e996d091f95c97ad7779b052ab91f05e9d096992e114d3ed6f02877bf7b5712bba2170e6d9e31' \
        "${HOME}/TiDB/install_tidb.sh" \
    && echo 'Download and install TiUP DONE' ;

sh "${HOME}/TiDB/install_tidb.sh"

TIUP="${HOME}/.tiup/bin/tiup"

echo 'tiup update related START' \
    && "${TIUP}" update '--self' \
    && "${TIUP}" update cluster \
    && echo 'tiup update related DONE' ;

mkdir -pv -- \
    "/home/root/1/tidb/deploy" \
    "/home/root/1/tidb/data" ;

"${TIUP}" cluster check "${TOPOLOGY}" '--apply' '--user' root -i "${HOME}/.ssh/id_ed25519"
"${TIUP}" cluster deploy 'tidb-prod' 'v8.5.6' "${TOPOLOGY}" '--user' root -i "${HOME}/.ssh/id_ed25519"
"${TIUP}" cluster start 'tidb-prod' '--init'
