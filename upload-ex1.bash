#!/usr/bin/env bash
set -u

GATEWAY_IP="192.168.99.4"
REMOTE_DIR="/public"
SELF="$(id -un)"

usage() {
  echo "Usage: $(basename "$0") file1 [file2 ...]"
  echo "Uploads files to $REMOTE_DIR on $GATEWAY_IP"
  echo "Example 1 permissions applied automatically."
}

# -------------------------------
# 1. No arguments
# -------------------------------
if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

uploaded_any=0

# -------------------------------
# 2. Determine ACL rules for this user
# -------------------------------
case "$SELF" in
  jack)
    OWNER="rw-"
    JACK="rw-"
    JILL="r--"
    TAY="---"
    ABA="rw-"
    ;;
  jill)
    OWNER="rw-"
    JACK="r--"
    JILL="rw-"
    TAY="---"
    ABA="rw-"
    ;;
  tay)
    OWNER="rw-"
    JACK="---"
    JILL="---"
    TAY="rw-"
    ABA="rw-"
    ;;
  aba-hadi)
    OWNER="rw-"
    JACK="rw-"
    JILL="rw-"
    TAY="rw-"
    ABA="rw-"
    ;;
  *)
    echo "Error: unsupported user $SELF"
    exit 1
    ;;
esac

# -------------------------------
# 3. Process each argument
# -------------------------------
for FILE in "$@"; do

  if [ ! -f "$FILE" ]; then
    echo "ERROR: '$FILE' is not an existing file"
    continue
  fi

  BASENAME="$(basename "$FILE")"

  echo "Uploading $FILE..."
  if ! scp "$FILE" "${SELF}@${GATEWAY_IP}:${REMOTE_DIR}/"; then
    echo "ERROR: upload failed for $FILE"
    continue
  fi

  uploaded_any=1

  # -------------------------------
  # 4. Apply ACLs on gateway
  # -------------------------------
  ssh "${SELF}@${GATEWAY_IP}" bash <<EOF
FILE_PATH="${REMOTE_DIR}/${BASENAME}"

chmod 600 "\$FILE_PATH"
setfacl -b "\$FILE_PATH"
setfacl -k "\$FILE_PATH"

setfacl -m u::${OWNER} "\$FILE_PATH"
setfacl -m u:jack:${JACK} "\$FILE_PATH"
setfacl -m u:jill:${JILL} "\$FILE_PATH"
setfacl -m u:tay:${TAY} "\$FILE_PATH"
setfacl -m u:aba-hadi:${ABA} "\$FILE_PATH"

setfacl -m m:rw- "\$FILE_PATH"

echo "----- ACL for \$FILE_PATH -----"
getfacl "\$FILE_PATH"
EOF

  # -------------------------------
  # 5. ACL VERIFICATION FOR THIS USER
  # -------------------------------
  ACL_OUTPUT="$(ssh ${SELF}@${GATEWAY_IP} "getfacl ${REMOTE_DIR}/${BASENAME}")"

  # Verify each expected ACL
  echo "$ACL_OUTPUT" | grep -q "user:jack:${JACK}" || \
    echo "WARNING: jack does NOT have ${JACK} on ${BASENAME}"

  echo "$ACL_OUTPUT" | grep -q "user:jill:${JILL}" || \
    echo "WARNING: jill does NOT have ${JILL} on ${BASENAME}"

  echo "$ACL_OUTPUT" | grep -q "user:tay:${TAY}" || \
    echo "WARNING: tay does NOT have ${TAY} on ${BASENAME}"

  echo "$ACL_OUTPUT" | grep -q "user:aba-hadi:${ABA}" || \
    echo "WARNING: aba-hadi does NOT have ${ABA} on ${BASENAME}"

done

if [ "$uploaded_any" -eq 0 ]; then
  echo "No valid files were uploaded."
  exit 1
fi
