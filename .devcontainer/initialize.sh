#!/bin/bash
set -euxo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

sudo apt-get update
sudo apt-get install -y shellcheck vim

( cd pl/xt && cpanm --installdeps --notest . )
(
    cd py
    python3 -m venv .venv
    # shellcheck source=/dev/null
    source .venv/bin/activate
    make installdeps
    simple-perms -mr .
)
( cd js && npm ci )
( cd web-src && npm ci )
./hardlinks.sh
