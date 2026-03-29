#!/usr/bin/env bash
set -u

GATEWAY_IP="192.168.99.4"
REMOTE_DIR="/public"
SELF="$(id -un)"

usage() {
  echo "Usage: $(basename "$0") file1 [file2 ...]"
  echo "Uploads files to $REMOTE_DIR on $GATEWAY_IP"
  echo "Then verifies permissions for Example 1."
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
# 2. Expected ACLs for this user
# -------------------------------
case "$SELF" in
  jack)
    EXP_JACK="rw-"
    EXP_JILL="r--"
    EXP_TAY="---"
    EXP_ABA="rw-"
    ;;
  jill)
    EXP_JACK="r--"
    EXP_JILL="rw-"
    EXP_TAY="---"
    EXP_ABA="rw-"
    ;;
  tay)
    EXP_JACK="---"
    EXP_JILL="---"
    EXP_TAY="rw-"
    EXP_ABA="rw-"
    ;;
  aba-hadi)
    EXP_JACK="rw-"
    EXP_JILL="rw-"
    EXP_TAY="rw-"
    EXP_ABA="rw-"
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
  # 4. Read ACLs from gateway
  # -------------------------------
  ACL_OUTPUT="$(ssh ${SELF}@${GATEWAY_IP} "getfacl ${REMOTE_DIR}/${BASENAME}")"

  echo "----- Checking ACLs for ${BASENAME} -----"

  # -------------------------------
  # 5. Verify expected ACLs
  # -------------------------------
  echo "$ACL_OUTPUT" | grep -q "user:jack:${EXP_JACK}" || \
    echo "WARNING: jack does NOT have ${EXP_JACK} on ${BASENAME}"

  echo "$ACL_OUTPUT" | grep -q "user:jill:${EXP_JILL}" || \
    echo "WARNING: jill does NOT have ${EXP_JILL} on ${BASENAME}"

  echo "$ACL_OUTPUT" | grep -q "user:tay:${EXP_TAY}" || \
    echo "WARNING: tay does NOT have ${EXP_TAY} on ${BASENAME}"

  echo "$ACL_OUTPUT" | grep -q "user:aba-hadi:${EXP_ABA}" || \
    echo "WARNING: aba-hadi does NOT have ${EXP_ABA} on ${BASENAME}"

done

if [ "$uploaded_any" -eq 0 ]; then
  echo "No valid files were uploaded."
  exit 1
fi
