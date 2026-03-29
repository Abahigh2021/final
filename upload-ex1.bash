#!/usr/bin/env bash
set -u

GATEWAY="192.168.99.4"
REMOTE_DIR="/public"
SELF="$(id -un)"
SOCKET_DIR="${HOME}/.ssh/cm"
mkdir -p "$SOCKET_DIR"

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

control_path() {
    local user="$1"
    echo "${SOCKET_DIR}/cm-${user}@${GATEWAY}"
}

ensure_connection() {
    local user="$1"
    local cp
    cp="$(control_path "$user")"

    if ssh -o ControlMaster=auto \
          -o ControlPersist=10m \
          -o ControlPath="$cp" \
          -O check "${user}@${GATEWAY}" >/dev/null 2>&1; then
        return 0
    fi

    echo "Opening SSH connection for ${user}@${GATEWAY} ..."
    ssh -o ControlMaster=auto \
        -o ControlPersist=10m \
        -o ControlPath="$cp" \
        -o ConnectTimeout=10 \
        "${user}@${GATEWAY}" "exit" || return 1
}

remote_test() {
    local user="$1"
    local mode="$2"
    local file="$3"
    local cp
    cp="$(control_path "$user")"

    ssh -o ControlPath="$cp" \
        -o ConnectTimeout=10 \
        "${user}@${GATEWAY}" "test ${mode} '${file}'"
}

close_connection() {
    local user="$1"
    local cp
    cp="$(control_path "$user")"

    ssh -o ControlPath="$cp" \
        -O exit "${user}@${GATEWAY}" >/dev/null 2>&1 || true
}

uploaded_any=0

for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo "Error: not an existing file: $file"
        continue
    fi

    base="$(basename "$file")"
    remote_file="${REMOTE_DIR}/${base}"

    echo "Uploading $file ..."

    if ! ensure_connection "$SELF"; then
        echo "Error: could not authenticate as ${SELF} on gateway"
        continue
    fi

    if ! scp -o ControlPath="$(control_path "$SELF")" \
             "$file" "${SELF}@${GATEWAY}:${REMOTE_DIR}/"; then
        echo "Error: upload failed for $file"
        continue
    fi

    uploaded_any=1
    echo "Uploaded: $base"
    echo "Checking Example 1 behavior for $base ..."

    # uploader
    if remote_test "$SELF" -r "$remote_file"; then
        echo "PASS: ${SELF} can read $base"
    else
        echo "WARNING: ${SELF} should be able to read $base"
    fi

    if remote_test "$SELF" -w "$remote_file"; then
        echo "PASS: ${SELF} can write $base"
    else
        echo "WARNING: ${SELF} should be able to write $base"
    fi

    # aba-hadi
    if ensure_connection "aba-hadi"; then
        if remote_test "aba-hadi" -r "$remote_file"; then
            echo "PASS: aba-hadi can read $base"
        else
            echo "WARNING: aba-hadi should be able to read $base"
        fi

        if remote_test "aba-hadi" -w "$remote_file"; then
            echo "PASS: aba-hadi can write $base"
        else
            echo "WARNING: aba-hadi should be able to write $base"
        fi
    else
        echo "WARNING: could not authenticate as aba-hadi to test $base"
    fi

    # partner
    if [ -n "$partner" ]; then
        if ensure_connection "$partner"; then
            if remote_test "$partner" -r "$remote_file"; then
                echo "PASS: ${partner} can read $base"
            else
                echo "WARNING: ${partner} should be able to read $base"
            fi

            if remote_test "$partner" -w "$remote_file"; then
                echo "WARNING: ${partner} should NOT be able to write $base"
            else
                echo "PASS: ${partner} cannot write $base"
            fi
        else
            echo "WARNING: could not authenticate as ${partner} to test $base"
        fi
    fi

    # blocked users
    for u in $blocked_users; do
        if ensure_connection "$u"; then
            if remote_test "$u" -r "$remote_file"; then
                echo "WARNING: ${u} should NOT be able to read $base"
            else
                echo "PASS: ${u} cannot read $base"
            fi

            if remote_test "$u" -w "$remote_file"; then
                echo "WARNING: ${u} should NOT be able to write $base"
            else
                echo "PASS: ${u} cannot write $base"
            fi
        else
            echo "WARNING: could not authenticate as ${u} to test $base"
        fi
    done

    echo
done

if [ "$uploaded_any" -eq 0 ]; then
    echo "No valid files were uploaded."
    exit 1
fi
