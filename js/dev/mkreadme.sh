#!/bin/bash
set -euxo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"/..

npx typedoc --githubPages false --out .tmpdocs --plugin typedoc-plugin-rename-defaults \
    --plugin typedoc-plugin-markdown --hideBreadcrumbs true --hideInPageTOC true src/re-int-ineq.ts
perl -wMstrict -nle 'last if /^#### Defined in$/; print unless /^# re-int-ineq$/' .tmpdocs/modules.md >README.md
rm -rf .tmpdocs
