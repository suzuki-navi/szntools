
set -Ceu
set -o pipefail

if type batcat >/dev/null 2>&1; then
    # On Ubuntu using apt
    batcat -n "$@"
elif type bat >/dev/null 2>&1; then
    bat -n "$@"
else
    echo "bat not found"
    echo "See: https://github.com/sharkdp/bat"
    cat
fi

