#!/bin/bash
# Script to run tests *inside the Docker container*!
set -euxo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"/../..
cpanm --quiet --notest /usr/src/perl-modules/*.tar.gz
prove -l
