#!/usr/bin/env bash
set -euo pipefail

MY="aba-hadi"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as: sudo bash bootstrap.sh" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ===========================================================
echo "Installing packages..."
# ===========================================================
# NOTE: sudo is already installed manually before running this script
apt install -y openssh-server acl

# ===========================================================
echo "Creating team groups..."
# ===========================================================
for g in attack defend bot; do
  getent group "$g" >/dev/null 2>&1 || groupadd "$g"
  echo "  [OK] group: $g"
done

# ===========================================================
echo "Creating per-user groups and users..."
# ===========================================================
declare -A USERS
USERS[jack]="jack:attack"
USERS[jill]="jill:defend"
USERS[tay]="tay:bot"
USERS["$MY"]="$MY:attack,defend,bot"

for u in "${!USERS[@]}"; do
  IFS=':' read -r primary teams <<< "${USERS[$u]}"
  echo "  Processing $u (primary: $primary  teams: $teams)"

  # Create primary group if missing
  getent group "$primary" >/dev/null 2>&1 || groupadd "$primary"

  if ! id -u "$u" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g "$primary" "$u"
    echo "$u:6638157" | chpasswd
    echo "  [OK] Created $u with password 6638157"
  else
    echo "  [INFO] User $u already exists — updating primary group"
    usermod -g "$primary" "$u"
    # Reset password for all except aba-hadi (already set manually)
    if [ "$u" != "$MY" ]; then
      echo "$u:6638157" | chpasswd
    fi
  fi

  # Add supplementary/team groups
  if [ -n "$teams" ]; then
    usermod -aG "$teams" "$u"
    echo "  [OK] $u added to: $teams"
  fi
done

# ===========================================================
echo "Setting up /public..."
# ===========================================================
mkdir -p /public
chown root:root /public
chmod 755 /public

# Per-user access on /public directory
for u in jack jill tay "$MY"; do
  setfacl -m u:"$u":rwx /public
  echo "  [OK] $u has rwx on /public"
done

# Default ACLs inherited by every new file created in /public
setfacl -d -m u::rw-      /public   # file owner gets rw
setfacl -d -m g::---      /public   # owning group gets nothing
setfacl -d -m o::---      /public   # others get nothing
setfacl -d -m u:"$MY":rw- /public   # aba-hadi always gets rw on new files
echo "  [OK] /public default ACLs set"

# ===========================================================
echo "Configuring SSH..."
# ===========================================================
SSHD="/etc/ssh/sshd_config"

# Disable root login
if grep -qE '^\s*PermitRootLogin' "$SSHD" 2>/dev/null; then
  sed -i 's/^\s*PermitRootLogin.*/PermitRootLogin no/' "$SSHD"
else
  echo "PermitRootLogin no" >> "$SSHD"
fi

# Enable password authentication
if grep -qE '^\s*PasswordAuthentication' "$SSHD" 2>/dev/null; then
  sed -i 's/^\s*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD"
else
  echo "PasswordAuthentication yes" >> "$SSHD"
fi

# Ubuntu 24.04 sshd_config.d override (wins over cloud-init defaults)
SSHD_D="/etc/ssh/sshd_config.d"
if [ -d "$SSHD_D" ]; then
  echo "PermitRootLogin no"         >  "$SSHD_D/99-ops105.conf"
  echo "PasswordAuthentication yes" >> "$SSHD_D/99-ops105.conf"
  echo "PubkeyAuthentication yes"   >> "$SSHD_D/99-ops105.conf"
  echo "  [OK] Wrote $SSHD_D/99-ops105.conf"
fi

systemctl restart ssh
echo "  [OK] SSH restarted"

# ===========================================================
echo ""
echo "============================================="
echo "Bootstrap complete."
echo "============================================="
echo "  Users and groups:"
echo "    jack     -> primary: jack,    teams: attack"
echo "    jill     -> primary: jill,    teams: defend"
echo "    tay      -> primary: tay,     teams: bot"
echo "    $MY  -> primary: $MY,  teams: attack, defend, bot"
echo ""
echo "  jack / jill / tay password: 6638157"
echo "  aba-hadi password: unchanged (set manually)"
echo ""
echo "  Next steps:"
echo "    1. Copy apply_acl_exam1.sh and apply_acl_exam2.sh to /usr/local/bin/"
echo "       sudo cp apply_acl_exam1.sh apply_acl_exam2.sh /usr/local/bin/"
echo "       sudo chmod +x /usr/local/bin/apply_acl_exam*.sh"
echo "    2. Create test files:"
echo "       sudo -u jack bash -c 'echo jack file > /public/jack.txt'"
echo "       sudo -u jill bash -c 'echo jill file > /public/jill.txt'"
echo "       sudo -u tay  bash -c 'echo tay  file > /public/tay.txt'"
echo "============================================="
