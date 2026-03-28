#!/bin/bash
set -euo pipefail

# Replace this MySeneca username if different
MY="aba-hadi"

# Packages
apt update
apt install -y openssh-server acl sudo

# Create team groups
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
  # create primary group if missing
  getent group "$primary" >/dev/null || groupadd "$primary"
  # create user if missing with primary group
  if ! id -u "$u" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$primary" "$u"
    echo "$u:ChangeMe123" | chpasswd
  fi
  # set supplementary groups (replace existing supplementary groups)
  if [ -n "$teams" ]; then
    # convert comma list to comma-separated for usermod -aG
    IFS=',' read -ra TG <<< "$teams"
    # ensure each team group exists
    for tg in "${TG[@]}"; do getent group "$tg" >/dev/null || groupadd "$tg"; done
    usermod -G "$teams" "$u"
  fi
  # remove from generic 'users' group if present
  if getent group users >/dev/null; then
    gpasswd -d "$u" users >/dev/null 2>&1 || true
  fi
done

# Give MySeneca sudo
usermod -aG sudo "$MY"

# Create /public with safe defaults
mkdir -p /public
chown root:root /public
chmod 2770 /public            # setgid so files inherit directory group
# default ACLs: others none; MySeneca full by default
setfacl -m d:o:--- /public
setfacl -m o:--- /public
setfacl -m d:u:$MY:rwx /public
setfacl -m u:$MY:rwx /public

# Disable root SSH login (append or replace)
if grep -q '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi
systemctl restart sshd

echo "Bootstrap complete. Users and groups created. /public ready."
echo "Temporary passwords set to ChangeMe123 — change them with passwd."
