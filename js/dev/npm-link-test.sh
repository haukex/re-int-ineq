#!/bin/bash
set -euxo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

npm run prepublish

TEMPDIR="$( mktemp --directory )"
trap 'set +e; popd; rm -rf "$TEMPDIR"' EXIT

git clean -dxf dev/test-proj/
rsync -a dev/test-proj/ "$TEMPDIR" --exclude=__pycache__

npm link

pushd "$TEMPDIR"

npm link re-int-ineq
tsc
node test-thing.js

set +x
echo -e "\e[1;32mPASS\e[0m"
