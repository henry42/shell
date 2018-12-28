log() {
    if [[ -n "$VERBOSE" ]]; then echo -e "$@"; else test 1; fi
}

error() {
    echo "$@" >&2
    exit 1
}

warning() {
    echo "$@" >&2
}

function checkStatus {
    if [ $? -ne 0 ];
    then
        error "Encountered an error, aborting!"
    fi
}
