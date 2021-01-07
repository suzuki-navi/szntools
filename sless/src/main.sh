
# $SZNPACK_SOURCE_DIR
# $SZNPACK_HARD_WORKING_DIR

export SLESS_HOME=$SZNPACK_SOURCE_DIR

option=

declare -a files=()
while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ "$arg" = -f ]]; then
        shift
        f="$1"
        option="$option -f $f"
    elif [[ "$arg" = -v ]]; then
        option="$option -v"
    elif [[ "$arg" = -h ]]; then
        option="$option -h"
    elif [[ "$arg" = -N ]]; then
        option="$option -N"
    elif [[ "$arg" = -n ]]; then
        option="$option -n"
    elif [[ "$arg" = -r ]]; then
        option="$option -r"
    else
        files+=("$arg")
    fi
    shift
done

export TERMINAL_LINES=0
export TERMINAL_COLS=0
lesscmd="cat"
filename_esc_1=""
filename_esc_2=""
if [[ -t 1 ]]; then
    tput lines >/dev/null 2>&1 && export TERMINAL_LINES=$(tput lines);
    tput cols  >/dev/null 2>&1 && export TERMINAL_COLS=$(tput cols);
    option="$option --color"
    lesscmd="less -i -SRX"
    filename_esc_1="\e[32m"
    filename_esc_2="\e[m"
fi

if [[ ${#files[@]} = 0 && -t 0 ]]; then
    files+=(".")
fi

if [[ ${#files[@]} = 0 ]]; then
    bash $SLESS_HOME/object.sh $option
elif [[ ${#files[@]} = 1 ]]; then
    f="${files[0]}"
    bash $SLESS_HOME/object.sh $option -- "$f"
else
    for f in ${files[@]}; do
        echo -e "$filename_esc_1$f$filename_esc_2"
        bash $SLESS_HOME/object.sh $option -- "$f"
    done
fi | $lesscmd

