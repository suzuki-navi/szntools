
set -Ceu
set -o pipefail

if type zip >/dev/null 2>&1; then
    (
        cd $SZNPACK_HARD_WORKING_DIR
        cat > ziptmp.zip
        unzip -v ziptmp.zip
    )
else
    echo "unzip not found"
fi

