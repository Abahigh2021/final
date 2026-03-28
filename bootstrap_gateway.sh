#!/usr/bin/env bash
set -euo pipefail

# Replace this MySeneca username if different
MY="aba-hadi"

export DEBIAN_FRONTEND=noninteractive

echo "Installing packages..."
apt update
apt install -y openssh-server acl sudo

echo "Creating team groups..."
for g in attack defend bot; do
  getent group "$g" >/dev/null || groupadd "$g"
done

# Create per-user groups and users
# Format: username:primarygroup:teamsupplementary
declare -A USERS=(
  [jack]="jack:attack"
  [jill]="jill:defend"
  [tay]="tay:bot"
  [$MY]="$MY:attack,defend,bot"
)

for u in "${!USERS[@]}"; do
  IFS=':' read -r primary teams <<< "${USERS[$u]}"
  echo "Processing user: $u (primary: $primary, teams: $teams)"
  # create primary group if missing
  getent group "$primary" >/dev/null || groupadd "$primary"
  # create user if missing with primary group
  if ! id -u "$u" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$primary" "$u"
    # Optional: set a temporary password for testing (remove for production)
    echo "$u:ChangeMe123" | chpasswd
    echo "Created user $u with temporary password ChangeMe123"
  else
    echo "User $u already exists"
  fi
  # set supplementary groups (choose replace or append)
  if [ -n "$teams" ]; then
    # Use -aG to append; change to -G to replace if you prefer
    usermod -aG "$teams" "$u"
  fi
  # remove from generic 'users' group if present
  if getent group users >/dev/null; then
    gpasswd -d "$u" users >/dev/null 2>&1 || true
  fi
done

echo "Granting sudo to $MY"
usermod -aG sudo "$MY"

echo "Creating /public with safe defaults..."
mkdir -p /public
chown root:root /public
chmod 2770 /public            # setgid so files inherit directory group
# default ACLs: others none; MySeneca full by default
setfacl -m d:o:--- /public
setfacl -m o:--- /public
setfacl -m d:u:$MY:rwx /public
setfacl -m u:$MY:rwx /public

echo "Disabling root SSH login..."
if grep -q '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi
systemctl restart sshd

echo "Bootstrap complete. Users and groups created. /public ready."
echo "Temporary passwords (if set) are ChangeMe123 — change them with passwd."
