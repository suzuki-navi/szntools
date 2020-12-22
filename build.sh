#!/bin/bash

set -Ceu
set -o pipefail

cd $(dirname $0)

mkdir -p bin

for d in $(ls .); do
    if [[ ! -d $d ]]; then
        continue
    fi
    if [[ $d = bin ]] || [[ $d = var ]]; then
        continue
    fi
    echo '################'
    echo "# $d"
    echo '################'
    (
        cd $d
        make
    )
    if [[ -e $d/bin/$d ]] && ( [[ ! -e bin/$d ]] || ! cmp bin/$d $d/bin/$d >/dev/null ); then
        cp -vp $d/bin/$d bin/$d
    fi
done

