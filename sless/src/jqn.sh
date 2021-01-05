
set -Ceu
set -o pipefail

if type jq >/dev/null 2>&1; then
    jq "$@" | cat -n
else
    echo "jq not found"
    echo "See: https://stedolan.github.io/jq/"
    cat -n
fi

