#!/bin/bash

version_hash=XXXX_VERSION_HASH_XXXX
sznpack_source_dir=$HOME/XXXX_SZNPACK_SOURCE_DIR_XXXX/version-$version_hash

export SZNPACK_SOURCE_DIR=$sznpack_source_dir

if [ ! -e $SZNPACK_SOURCE_DIR ]; then
    tool_parent_dir=$(dirname $SZNPACK_SOURCE_DIR)
    if [ ! -e $tool_parent_dir ]; then
        mkdir -p $tool_parent_dir
    fi

    mkdir $SZNPACK_SOURCE_DIR.tmp 2>/dev/null
    cat $0 | (
        cd $SZNPACK_SOURCE_DIR.tmp || exit $?
        perl -ne 'print $_ if $f; $f=1 if /^#SOURCE_IMAGE$/' | tar xzf - 2>/dev/null
    )
    mkdir $SZNPACK_SOURCE_DIR 2>/dev/null && mv $SZNPACK_SOURCE_DIR.tmp/* $SZNPACK_SOURCE_DIR/ && rm -rf $SZNPACK_SOURCE_DIR.tmp
fi

if [ ! -e $SZNPACK_SOURCE_DIR ]; then
    echo "Not found: $SZNPACK_SOURCE_DIR" >&2
    exit 1;
fi

bash $SZNPACK_SOURCE_DIR/main.sh "$@"

exit $?

#SOURCE_IMAGE
