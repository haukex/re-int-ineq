#!/bin/bash
set -euo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"

function hardlink_files {
	if [ ! "$1" -ef "$2" ]; then
		cmp "$1" "$2"  # fails if different
		ln -vf "$1" "$2"
	fi
}

# These files should always be identical and therefore can be hard linked
# (on filesystems that support it)
hardlink_files "LICENSE.txt" "pl/LICENSE.txt"
hardlink_files "LICENSE.txt" "py/LICENSE.txt"
hardlink_files "LICENSE.txt" "js/LICENSE.txt"
hardlink_files "pl/t/testcases.json" "py/tests/testcases.json"
hardlink_files "pl/t/testcases.json" "js/src/__tests__/testcases.json"

