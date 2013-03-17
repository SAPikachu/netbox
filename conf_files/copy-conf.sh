#!/bin/bash

SOURCE=$(readlink -m $1)
TARGET=${SOURCE//\//^}

if [ -f $TARGET ]; then
    echo "Fatal: $TARGET exists."
    exit 1
fi

cp $SOURCE $TARGET
