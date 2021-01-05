
set -Ceu
set -o pipefail

target_file=
while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ "$arg" = "--" ]]; then
        shift
        target_file="$1"
    else
        echo "Unknown argument: $arg" >&2
        exit 1
    fi
    shift
done

if type zip >/dev/null 2>&1; then
    if [[ -n "$target_file" ]]; then
        unzip -v "$target_file"
    else
        (
            cd $SZNPACK_HARD_WORKING_DIR
            cat > ziptmp.zip
            unzip -v ziptmp.zip
        )
    fi
else
    echo "unzip not found"
fi

