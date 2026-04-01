#!/bin/bash
# upload-ex1.bash
# Uploads files to /public on gateway and applies Example 1 ACLs (read-only between jack & jill)
# Usage: upload-ex1.bash file1 [file2 ...]

# -------------------------------
# 1. Usage check
# -------------------------------
if [ $# -eq 0 ]; then
    echo "Usage: upload-ex1.bash file1 [file2 ...]"
    echo "Uploads files to /public on gateway."
    echo "Applies Example 1 ACLs: jack & jill read each other, tay blocked."
    exit 1
fi

SELF="$(id -un)"
GATEWAY_IP="192.168.99.5"   # update this if your gateway IP changes
REMOTE_DIR="/public"
uploaded_any=0

# -------------------------------
# 2. Loop through all arguments
# -------------------------------
for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: '$FILE' is not an existing file"
        continue
    fi

    BASENAME="$(basename "$FILE")"
    echo "Uploading $BASENAME..."

    if ! scp "$FILE" "${SELF}@${GATEWAY_IP}:${REMOTE_DIR}/"; then
        echo "ERROR: upload failed for $FILE"
        continue
    fi
    uploaded_any=1

    # -------------------------------
    # 3. Apply Example 1 ACLs on gateway
    # -------------------------------
    echo "Applying Example 1 ACLs on gateway for $BASENAME..."
    if ! ssh "${SELF}@${GATEWAY_IP}" "sudo apply_acl_exam1.sh ${REMOTE_DIR}/${BASENAME} ${SELF}"; then
        echo "ERROR: could not apply ACLs for $BASENAME on gateway"
        continue
    fi

    # -------------------------------
    # 4. Read ACLs back from gateway to verify
    # -------------------------------
    ACL_OUTPUT="$(ssh ${SELF}@${GATEWAY_IP} "getfacl ${REMOTE_DIR}/${BASENAME}")"
    echo "----- Checking ACLs for ${BASENAME} -----"

    # -------------------------------
    # 5. Expected permissions for Example 1
    # owner:     rw-
    # other of jack/jill: r--
    # tay:       ---
    # aba-hadi:  rw-  (always)
    # -------------------------------
    acl_ok=1

    case "$SELF" in
        jack)
            EXPECT_jack="rw-"
            EXPECT_jill="r--"
            EXPECT_tay="---"
            EXPECT_aba="rw-"
            ;;
        jill)
            EXPECT_jack="r--"
            EXPECT_jill="rw-"
            EXPECT_tay="---"
            EXPECT_aba="rw-"
            ;;
        tay)
            EXPECT_jack="---"
            EXPECT_jill="---"
            EXPECT_tay="rw-"
            EXPECT_aba="rw-"
            ;;
        aba-hadi)
            EXPECT_jack="rw-"
            EXPECT_jill="rw-"
            EXPECT_tay="rw-"
            EXPECT_aba="rw-"
            ;;
    esac

    # -------------------------------
    # 6. Check each user's ACL
    # -------------------------------
    check_acl() {
        local USER="$1"
        local EXPECT="$2"
        if ! echo "$ACL_OUTPUT" | grep -q "user:${USER}:${EXPECT}"; then
            echo "WARNING: ${USER} does NOT have ${EXPECT} on ${BASENAME}"
            acl_ok=0
        fi
    }

    check_acl "jack"     "$EXPECT_jack"
    check_acl "jill"     "$EXPECT_jill"
    check_acl "tay"      "$EXPECT_tay"
    check_acl "aba-hadi" "$EXPECT_aba"

    # -------------------------------
    # 7. Final result for this file
    # -------------------------------
    if [ "$acl_ok" -eq 1 ]; then
        echo "----- Permissions correctly set for ${BASENAME} -----"
    else
        echo "WARNING: Some permissions are wrong for ${BASENAME} — check above"
    fi
done

# -------------------------------
# 8. Final summary
# -------------------------------
if [ "$uploaded_any" -eq 0 ]; then
    echo "No valid files were uploaded."
fi
