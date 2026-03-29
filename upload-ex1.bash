#!/usr/bin/env bash
set -u

GATEWAY="192.168.99.4"
REMOTE_DIR="/public"
SELF="$(id -un)"

usage() {
    echo "Usage: $0 file1 [file2 ...]"
    echo "Uploads existing files to ${REMOTE_DIR} on gateway ${GATEWAY}"
    echo "Then checks Example 1 behavior:"
    echo "  jack -> jill read only, tay no access, aba-hadi read/write"
    echo "  jill -> jack read only, tay no access, aba-hadi read/write"
    echo "  tay  -> jack/jill no access, aba-hadi read/write"
}

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

partner=""
blocked_users=""

case "$SELF" in
    jack)
        partner="jill"
        blocked_users="tay"
        ;;
    jill)
        partner="jack"
        blocked_users="tay"
        ;;
    tay)
        partner=""
        blocked_users="jack jill"
        ;;
    aba-hadi)
        partner=""
        blocked_users="jack jill tay"
        ;;
    *)
        echo "Error: unsupported user $SELF"
        exit 1
        ;;
esac

uploaded_any=0

for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo "Error: not an existing file: $file"
        continue
    fi

    base="$(basename "$file")"

    echo "Uploading $file ..."
    if ! scp "$file" "${SELF}@${GATEWAY}:${REMOTE_DIR}/"; then
        echo "Error: upload failed for $file"
        continue
    fi

    uploaded_any=1
    echo "Uploaded: $base"
    echo "Checking Example 1 behavior for $base ..."

    # uploader should read
    if ssh "${SELF}@${GATEWAY}" "test -r ${REMOTE_DIR}/${base}"; then
        echo "PASS: ${SELF} can read $base"
    else
        echo "WARNING: ${SELF} should be able to read $base"
    fi

    # uploader should write
    if ssh "${SELF}@${GATEWAY}" "test -w ${REMOTE_DIR}/${base}"; then
        echo "PASS: ${SELF} can write $base"
    else
        echo "WARNING: ${SELF} should be able to write $base"
    fi

    # aba-hadi should always read
    if ssh "aba-hadi@${GATEWAY}" "test -r ${REMOTE_DIR}/${base}"; then
        echo "PASS: aba-hadi can read $base"
    else
        echo "WARNING: aba-hadi should be able to read $base"
    fi

    # aba-hadi should always write
    if ssh "aba-hadi@${GATEWAY}" "test -w ${REMOTE_DIR}/${base}"; then
        echo "PASS: aba-hadi can write $base"
    else
        echo "WARNING: aba-hadi should be able to write $base"
    fi

    # partner should read only
    if [ -n "$partner" ]; then
        if ssh "${partner}@${GATEWAY}" "test -r ${REMOTE_DIR}/${base}"; then
            echo "PASS: ${partner} can read $base"
        else
            echo "WARNING: ${partner} should be able to read $base"
        fi

        if ssh "${partner}@${GATEWAY}" "test -w ${REMOTE_DIR}/${base}"; then
            echo "WARNING: ${partner} should NOT be able to write $base"
        else
            echo "PASS: ${partner} cannot write $base"
        fi
    fi

    # blocked users should have no access
    for u in $blocked_users; do
        if ssh "${u}@${GATEWAY}" "test -r ${REMOTE_DIR}/${base}"; then
            echo "WARNING: ${u} should NOT be able to read $base"
        else
            echo "PASS: ${u} cannot read $base"
        fi

        if ssh "${u}@${GATEWAY}" "test -w ${REMOTE_DIR}/${base}"; then
            echo "WARNING: ${u} should NOT be able to write $base"
        else
            echo "PASS: ${u} cannot write $base"
        fi
    done

    echo
done

if [ "$uploaded_any" -eq 0 ]; then
    echo "No valid files were uploaded."
    exit 1
fi
