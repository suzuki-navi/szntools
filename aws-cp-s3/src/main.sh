
# $SZNPACK_SOURCE_DIR
# $SZNPACK_HARD_WORKING_DIR

src_profile=default
dst_profile=default
src_path=
dst_path=
dry_run=

while (( $# > 0 )); do
    case "$1" in
        --profile)
            src_profile="$2"
            dst_profile="$2"
            shift
            ;;
        --src-profile)
            src_profile="$2"
            shift
            ;;
        --dst-profile)
            dst_profile="$2"
            shift
            ;;
        --dry-run)
            dry_run=1
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "$src_path" ]]; then
                src_path="$1"
            elif [[ -z "$dst_path" ]]; then
                dst_path="$1"
            else
                echo "Unknown parameter: $1" >&2
                exit 1
            fi
            ;;
    esac
    shift
done

# pathは最後にスラッシュがあってもなくても同じ

python $SZNPACK_SOURCE_DIR/sync-s3dir.py "$src_profile" "$src_path" "$dst_profile" "$dst_path" "$SZNPACK_HARD_WORKING_DIR/buf" > $SZNPACK_HARD_WORKING_DIR/script.sh

if [[ -n "$dry_run" ]]; then
    cat $SZNPACK_HARD_WORKING_DIR/script.sh
else
    bash $SZNPACK_HARD_WORKING_DIR/script.sh
fi

