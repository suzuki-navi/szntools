
export SLESS_HOME=$SZNPACK_SOURCE_DIR

option=

declare -a files=()
while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ "$arg" = -v ]]; then
        option="$option -v"
    elif [[ "$arg" = -h ]]; then
        option="$option -h"
    else
        files+=("$arg")
    fi
    shift
done

export TERMINAL_LINES=0
export TERMINAL_COLS=0
lesscmd="cat"
if [[ -t 1 ]]; then
    tput lines >/dev/null 2>&1 && export TERMINAL_LINES=$(tput lines);
    tput cols  >/dev/null 2>&1 && export TERMINAL_COLS=$(tput cols);
    option="$option --color"
    lesscmd="less -i -SRX"
fi

if [[ ${#files[@]} = 0 ]]; then
    bash $SLESS_HOME/object.sh $option
elif [[ ${#files[@]} = 1 ]]; then
    f="${files[0]}"
    bash $SLESS_HOME/object.sh $option "$f"
else
    for f in ${files[@]}; do
        if [[ -t 1 ]]; then
            echo -e "\e[32m$f\e[m"
        else
            echo "$f"
        fi
        bash $SLESS_HOME/object.sh $option "$f"
    done
fi | $lesscmd

