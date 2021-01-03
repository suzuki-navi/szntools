
set -Ceu
set -o pipefail

format_wrapper_option=
ls_option=
color_flag=
target_file=
while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ "$arg" = -v ]]; then
        format_wrapper_option="$format_wrapper_option -v"
    elif [[ "$arg" = -h ]]; then
        ls_option="$ls_option -h"
    elif [[ "$arg" = -n ]]; then
        format_wrapper_option="$format_wrapper_option -n"
    elif [[ "$arg" = --color ]]; then
        color_flag=1
        format_wrapper_option="$format_wrapper_option --color"
    else
        target_file=$1
    fi
    shift
done

if [[ "$target_file" = "" ]]; then
    perl $SLESS_HOME/format-wrapper.pl $format_wrapper_option
elif [[ -d "$target_file" ]]; then
    if [[ -n "$color_flag" ]]; then
        ls -alF $ls_option --color=always --time-style="+%Y-%m-%d %H:%M:%S" "$target_file"
    else
        ls -alF $ls_option --color=never --time-style="+%Y-%m-%d %H:%M:%S" "$target_file"
    fi
else
    perl $SLESS_HOME/format-wrapper.pl $format_wrapper_option < "$target_file"
fi

