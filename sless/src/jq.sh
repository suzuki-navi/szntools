
set -Ceu
set -o pipefail

if type jq >/dev/null 2>&1; then
    jq "$@"
else
    echo "jq not found"
    cat
fi

