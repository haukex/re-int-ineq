#!/bin/bash
set -euxo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

npx typedoc --githubPages false --out .tmpdocs --plugin typedoc-plugin-rename-defaults \
    --plugin typedoc-plugin-markdown --disableSources --hideBreadcrumbs true --hideInPageTOC true src/re-int-ineq.ts
perl -wMstrict -0777 -ple \
    ' s/\A# re-int-ineq\n+//; s/\|\s+\`undefined\`\s+\|/| *required* |/g; s/(\nSee Also\n.+(?=\n## Functions\n))//s;$_.=$1 ' \
    -- .tmpdocs/modules.md >README.md
rm -rf .tmpdocs
