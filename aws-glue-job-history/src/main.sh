
set -Ceu

# $SZNPACK_SOURCE_DIR
# $SZNPACK_HARD_WORKING_DIR

profile=default

while (( $# > 0 )); do
    case "$1" in
        --profile)
            profile="$2"
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            echo "Unknown parameter: $1" >&2
            exit 1
            ;;
    esac
    shift
done

if type pipenv >/dev/null; then
    if [[ ! -e $SZNPACK_SOURCE_DIR/.installed ]]; then
        PIPENV_PIPFILE=$SZNPACK_SOURCE_DIR/Pipfile PIPENV_VENV_IN_PROJECT=1 pipenv sync >&2
        touch $SZNPACK_SOURCE_DIR/.installed
    fi
    PIPENV_PIPFILE=$SZNPACK_SOURCE_DIR/Pipfile PIPENV_VENV_IN_PROJECT=1 pipenv run python $SZNPACK_SOURCE_DIR/glue-job-history.py "$profile"
else
    python $SZNPACK_SOURCE_DIR/glue-job-history.py "$profile"
fi

