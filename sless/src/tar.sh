
set -Ceu
set -o pipefail

if type tar >/dev/null 2>&1; then
    tar "$@"
else
    echo "tar not found"
    cat
fi

