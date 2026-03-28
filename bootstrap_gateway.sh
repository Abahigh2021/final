#!/usr/bin/env bash
set -euo pipefail

# MySeneca username (change if needed)
MY="aba-hadi"

export DEBIAN_FRONTEND=noninteractive

echo "Installing packages..."
apt update
apt install -y openssh-server acl sudo

echo "Creating team groups..."
for g in attack defend bot; do
  getent group "$g" >/dev/null || groupadd "$g"
done

echo "Creating per-user groups and users..."
declare -A USERS=(
  [jack]="jack:attack"
  [jill]="jill:defend"
  [tay]="tay:bot"
  [$MY]="$MY:attack,defend,bot"
)

for u in "${!USERS[@]}"; do
  IFS=':' read -r primary teams <<< "${USERS[$u]}"
  echo "Processing $u (primary:$primary teams:$teams)"
  getent group "$primary" >/dev/null || groupadd "$primary"
  if ! id -u "$u" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$primary" "$u"
    echo "$u:ChangeMe123" | chpasswd
    echo "Created $u with temporary password ChangeMe123"
  else
    echo "User $u already exists"
  fi
  if [ -n "$teams" ]; then
    usermod -aG "$teams" "$u"
  fi
  # remove from generic 'users' group if present
  if getent group users >/dev/null; then
    gpasswd -d "$u" users >/dev/null 2>&1 || true
  fi
done

echo "Granting sudo to $MY"
usermod -aG sudo "$MY"

echo "Creating /public and allowing users to enter and create files..."
mkdir -p /public
chown root:root /public
chmod 2770 /public            # setgid so files inherit directory group

# Make /public accessible to the four users and set defaults so new files inherit named-user ACLs
setfacl -m u:jack:rwx,u:jill:rwx,u:tay:rwx,u:$MY:rwx /public
setfacl -d -m u:jack:rwx,u:jill:rwx,u:tay:rwx,u:$MY:rwx /public

# Keep others denied
setfacl -m o:--- /public
setfacl -m d:o:--- /public

echo "Disabling root SSH login (keeps pubkey/password for users)"
if grep -q '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi
systemctl restart sshd

echo "Bootstrap complete."
echo "Temporary passwords set to ChangeMe123 — change them with passwd or use SSH keys."
