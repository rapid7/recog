#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Usage: $(basename $0) <xml fingerprint directory>"
    exit 1
fi

if [ ! -d "$1" ]
then
    echo "The XML fingerprint file directory must be supplied."
    exit 1
fi

bin/recog_verify "$1/*.xml"

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
    bin/recog_verify "$1/*.xml"
    echo "Waiting for changes..."
}; done
