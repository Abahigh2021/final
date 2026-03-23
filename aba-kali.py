#!/bin/bash

DEST="/public"
GATEWAY="192.168.99.1"
USER_NAME="aba-hadi"

if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") FILE [FILE ...]"
    exit 1
fi

for item in "$@"; do
    if [ ! -f "$item" ]; then
        echo "ERROR: '$item' is not an existing file" >&2
        continue
    fi

    base=$(basename "$item")

    if scp "$item" "${USER_NAME}@${GATEWAY}:${DEST}/"; then
        echo "SUCCESS: '$item' copied to $DEST"

        perms=$(ssh "${USER_NAME}@${GATEWAY}" "stat -c '%A' '${DEST}/${base}'")
        echo "Gateway permissions for '$base': $perms"

    else
        echo "ERROR: failed to copy '$item' to $DEST" >&2
    fi
done
