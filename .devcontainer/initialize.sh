#!/bin/bash
set -euxo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

( cd pl/xt && cpanm --installdeps --notest . )
(
    cd py
    python -m venv .venv
    # shellcheck source=/dev/null
    source .venv/bin/activate
    make installdeps
    simple-perms -mr .
)
( cd js && npm ci )
( cd web-src && npm ci )
./hardlinks.sh
