#!/bin/bash

ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--schema-location)
            VALIDATE_SCHEMA="--schema-location $2"
            shift
            shift
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done
set -- "${ARGS[@]}"

if [ $# -eq 0 ]
then
    echo "Usage: $(basename $0) [--schema-location SCHEMA_LOCATION] <xml fingerprint directory>"
    exit 1
fi

if [ ! -d "$1" ]
then
    echo "The XML fingerprint file directory must be supplied."
    exit 1
fi

bin/recog_verify $VALIDATE_SCHEMA "$1/*.xml"

if ! type fswatch &>/dev/null;
then 
    echo "'fswatch' is required to monitor fingerprint files for changes and update the editor."
    echo "See: https://emcrisostomo.github.io/fswatch/ or install with:"
    echo " MacOS Homebrew: brew install fswatch"
    echo " Ubuntu/Debian:  apt install fswatch"
    echo
    echo "Otherwise, you can re-run this task using the Visual Studio Code command palette"
    exit 1
fi

echo "Waiting for changes..."
fswatch -0 $1 | while read -d "" event; do {
    echo "Changes detected, validating: ${event}"
    # TODO: VSCode doesn't support individual/incremental updates to files yet.
    bin/recog_verify $VALIDATE_SCHEMA "$1/*.xml"
    echo "Waiting for changes..."
}; done
