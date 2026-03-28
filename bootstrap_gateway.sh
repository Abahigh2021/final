#!/usr/bin/env bash
set -euo pipefail

MY="aba-hadi"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root or with sudo" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Installing packages..."
apt update
apt install -y openssh-server acl sudo

echo "Creating team groups..."
for g in attack defend bot; do
  getent group "$g" >/dev/null || groupadd "$g"
done

echo "Creating per-user groups and users..."
declare -A USERS
USERS[jack]="jack:attack"
USERS[jill]="jill:defend"
USERS[tay]="tay:bot"
USERS["$MY"]="$MY:attack,defend,bot"

for u in "${!USERS[@]}"; do
  IFS=':' read -r primary teams <<< "${USERS[$u]}"
  echo "Processing $u (primary:$primary teams:$teams)"

  getent group "$primary" >/dev/null || groupadd "$primary"

  if ! id -u "$u" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$primary" "$u"
    echo "$u:6638157" | chpasswd
    echo "Created $u with password 6638157"
  else
    echo "User $u already exists"
  fi

  if [ -n "$teams" ]; then
    usermod -aG "$teams" "$u"
  fi
done

echo "Granting sudo to $MY"
usermod -aG sudo "$MY" || true

echo "Creating /public..."
mkdir -p /public
chown root:root /public
chmod 1777 /public   # world-writable + sticky bit (safe for setup)

echo "Disabling root SSH login..."
if grep -qE '^\s*PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null; then
  sed -i 's/^\s*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

echo "Ensuring password authentication is enabled..."
if grep -qE '^\s*PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null; then
  sed -i 's/^\s*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

systemctl restart ssh

echo "Bootstrap complete."
echo "All users have password: 6638157"
