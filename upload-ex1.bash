#!/usr/bin/env bash
set -u

GATEWAY_IP="192.168.99.1"
REMOTE_DIR="/public"
SELF="$(id -un)"

# Determine permissions based on Example 1 rules
case "$SELF" in
  jack)
    OWNER_PERM="rw-"
    JACK_PERM="rw-"
    JILL_PERM="r--"
    TAY_PERM="---"
    ABA_PERM="rw-"
    ;;
  jill)
    OWNER_PERM="rw-"
    JACK_PERM="r--"
    JILL_PERM="rw-"
    TAY_PERM="---"
    ABA_PERM="rw-"
    ;;
  tay)
    OWNER_PERM="rw-"
    JACK_PERM="---"
    JILL_PERM="---"
    TAY_PERM="rw-"
    ABA_PERM="rw-"
    ;;
  aba-hadi)
    OWNER_PERM="rw-"
    JACK_PERM="rw-"
    JILL_PERM="rw-"
    TAY_PERM="rw-"
    ABA_PERM="rw-"
    ;;
  *)
    echo "Error: unsupported user $SELF"
    exit 1
    ;;
esac

usage() {
  echo "Usage: $0 file1 [file2 ...]"
  echo "Uploads files to $REMOTE_DIR on $GATEWAY_IP"
  echo "Example 1 permissions applied automatically."
}

# No arguments
if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

uploaded_any=0

for FILE in "$@"; do

  # Not a file
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

  # Apply ACLs on gateway
  ssh "${SELF}@${GATEWAY_IP}" bash <<EOF
FILE_PATH="${REMOTE_DIR}/${BASENAME}"

# Reset permissions
chmod 600 "\$FILE_PATH"
setfacl -b "\$FILE_PATH"
setfacl -k "\$FILE_PATH"

# Owner
setfacl -m u::${OWNER_PERM} "\$FILE_PATH"

# Users
setfacl -m u:jack:${JACK_PERM} "\$FILE_PATH"
setfacl -m u:jill:${JILL_PERM} "\$FILE_PATH"
setfacl -m u:tay:${TAY_PERM} "\$FILE_PATH"
setfacl -m u:aba-hadi:${ABA_PERM} "\$FILE_PATH"

# Mask
setfacl -m m:rw- "\$FILE_PATH"

echo "----- ACL for \$FILE_PATH -----"
getfacl "\$FILE_PATH"
EOF

done

if [ "$uploaded_any" -eq 0 ]; then
  echo "No valid files were uploaded."
  exit 1
fi
