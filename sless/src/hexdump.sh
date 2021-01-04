
set -Ceu
set -o pipefail

if type hexdump >/dev/null 2>&1; then
    hexdump "$@"
else
    echo "hexdump not found"
    cat
fi

