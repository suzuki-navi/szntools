
set -Ceu
set -o pipefail

format_wrapper_option=
ls_option=
aws_ls_s3_option=
recursive_flag=
color_flag=
target_file=
while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ "$arg" = -f ]]; then
        shift
        f="$1"
        format_wrapper_option="$format_wrapper_option -f $f"
    elif [[ "$arg" = -v ]]; then
        format_wrapper_option="$format_wrapper_option -v"
    elif [[ "$arg" = -h ]]; then
        ls_option="$ls_option -h"
    elif [[ "$arg" = -N ]]; then
        format_wrapper_option="$format_wrapper_option -N"
    elif [[ "$arg" = -n ]]; then
        format_wrapper_option="$format_wrapper_option -n"
    elif [[ "$arg" = -r ]]; then
        aws_ls_s3_option="$aws_ls_s3_option -r"
        recursive_flag=1
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
elif [[ "$target_file" =~ ^s3:// ]]; then
    if type aws-ls-s3 >/dev/null 2>&1; then
        aws-ls-s3 --if-exists $aws_ls_s3_option "$target_file"
        aws-ls-s3 --cat --if-exists $aws_ls_s3_option "$target_file" | perl $SLESS_HOME/format-wrapper.pl $format_wrapper_option
    else
        echo "aws-ls-s3 not found"
    fi
elif [[ -d "$target_file" ]]; then
    if [[ -n "$recursive_flag" ]]; then
        find "$target_file" -printf "%M %n %u %g %s %TY-%Tm-%Td %TH:%TM:%TS %p\n"
    elif [[ -n "$color_flag" ]]; then
        ls -alF $ls_option --color=always --time-style="+%Y-%m-%d %H:%M:%S" "$target_file"
    else
        ls -alF $ls_option --color=never --time-style="+%Y-%m-%d %H:%M:%S" "$target_file"
    fi
else
    perl $SLESS_HOME/format-wrapper.pl $format_wrapper_option -- "$target_file"
fi

