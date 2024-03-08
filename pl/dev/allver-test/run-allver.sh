#!/bin/bash
set -euo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"

TEMPDIR="$( mktemp --directory )"
trap 'set +e; rm -rf "$TEMPDIR"' EXIT

../cpanfile2modurls.pl >modules.txt

wget --no-verbose --content-disposition --timestamping \
    --directory-prefix="$TEMPDIR" --input-file=modules.txt

BASEPATH="$(realpath "$(pwd)"/../..)"
PERLVER="$(perl -wMstrict -le 'require "./perlver.pl"; print for perlver()')"
#PERLVER="5.38"  # for testing only

for VER in $PERLVER; do
    echo -e "\e[2;30;43m##### Perl $VER #####\e[0m"
    set -x
    docker run -it --rm \
        -v "$BASEPATH:/usr/src/re-int-ineq:ro" \
        -v "$TEMPDIR:/usr/src/perl-modules:ro" \
        "perl:$VER" /usr/src/re-int-ineq/dev/allver-test/in-docker-run.sh
    set +x
done

echo -e "\e[1;32mPASS\e[0m"
