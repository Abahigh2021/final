#!/usr/bin/env bash
set -euo pipefail
 
MY="aba-hadi"
 
if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root or with sudo" >&2
  exit 1
fi
 
export DEBIAN_FRONTEND=noninteractive
 
# ===========================================================
echo "Installing packages..."
# ===========================================================
apt update -q
apt install -y openssh-server acl sudo
 
# ===========================================================
echo "Creating team groups..."
# ===========================================================
for g in attack defend bot; do
  getent group "$g" >/dev/null 2>&1 || groupadd "$g"
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
    # User does not exist — create fresh
    useradd -m -s /bin/bash -g "$primary" "$u"
    echo "$u:6638157" | chpasswd
    echo "  [OK] Created $u with password 6638157"
  else
    # FIX 1: User already exists (aba-hadi case)
    # Make sure primary group is correctly set even for existing users
    echo "  [INFO] User $u already exists — updating primary group and password"
    usermod -g "$primary" "$u"
    # Only reset password for aba-hadi if you want to keep the original, comment next line
    echo "$u:6638157" | chpasswd
  fi
 
  # Add supplementary/team groups
  if [ -n "$teams" ]; then
    usermod -aG "$teams" "$u"
    echo "  [OK] $u added to: $teams"
  fi
done
 
# ===========================================================
echo "Granting sudo to $MY..."
# ===========================================================
usermod -aG sudo "$MY"
 
# ===========================================================
echo "Creating /public..."
# ===========================================================
mkdir -p /public
chown root:root /public
 
# FIX 2: Use 755 + ACLs instead of 1777
# 1777 (world-writable + sticky) lets tay write to the directory freely.
# 755 + named ACLs gives precise per-user control on who can enter/create files.
chmod 755 /public
 
# Allow each user to enter /public and create their own files
for u in jack jill tay "$MY"; do
  setfacl -m u:"$u":rwx /public
  echo "  [OK] $u has rwx on /public (can enter, list, create files)"
done
 
# Default ACLs: inherited by every NEW file created inside /public.
# The ACL scripts (exam1/exam2) will override these per-file,
# but this ensures aba-hadi always gets rw even before ACL scripts run.
setfacl -d -m u::rw-      /public   # file owner gets rw by default
setfacl -d -m g::---      /public   # owning group gets nothing
setfacl -d -m o::---      /public   # others get nothing
setfacl -d -m u:"$MY":rw- /public   # aba-hadi always gets rw on new files
 
echo "  [OK] /public permissions set (755 + ACLs)"
 
# ===========================================================
echo "Configuring SSH..."
# ===========================================================
SSHD="/etc/ssh/sshd_config"
 
# Edit main sshd_config
if grep -qE '^\s*PermitRootLogin' "$SSHD" 2>/dev/null; then
  sed -i 's/^\s*PermitRootLogin.*/PermitRootLogin no/' "$SSHD"
else
  echo "PermitRootLogin no" >> "$SSHD"
fi
 
if grep -qE '^\s*PasswordAuthentication' "$SSHD" 2>/dev/null; then
  sed -i 's/^\s*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD"
else
  echo "PasswordAuthentication yes" >> "$SSHD"
fi
 
# FIX 3: Ubuntu 24.04 uses sshd_config.d/ — a drop-in file overrides the main config.
# Without this, 50-cloud-init.conf may silently override PasswordAuthentication.
SSHD_D="/etc/ssh/sshd_config.d"
if [ -d "$SSHD_D" ]; then
  echo "PermitRootLogin no"        >  "$SSHD_D/99-ops105.conf"
  echo "PasswordAuthentication yes" >> "$SSHD_D/99-ops105.conf"
  echo "PubkeyAuthentication yes"  >> "$SSHD_D/99-ops105.conf"
  echo "  [OK] Wrote $SSHD_D/99-ops105.conf (overrides cloud-init defaults)"
fi
 
systemctl restart ssh
echo "  [OK] SSH restarted"
 
# ===========================================================
echo ""
echo "============================================="
echo "Bootstrap complete."
echo "============================================="
echo "  Users and groups:"
echo "    jack  -> primary: jack,  teams: attack"
echo "    jill  -> primary: jill,  teams: defend"
echo "    tay   -> primary: tay,   teams: bot"
echo "    $MY -> primary: $MY, teams: attack, defend, bot + sudo"
echo ""
echo "  All users have password: 6638157"
echo ""
echo "  Next steps:"
echo "    1. Place apply_acl_exam1.sh and apply_acl_exam2.sh in /usr/local/bin/"
echo "    2. chmod +x /usr/local/bin/apply_acl_exam*.sh"
echo "    3. Create test files:"
echo "       sudo -u jack bash -c 'echo jack file > /public/jack.txt'"
echo "       sudo -u jill bash -c 'echo jill file > /public/jill.txt'"
echo "       sudo -u tay  bash -c 'echo tay  file > /public/tay.txt'"
echo "    4. Apply ACLs:"
echo "       sudo apply_acl_exam1.sh /public/jack.txt jack"
echo "       sudo apply_acl_exam1.sh /public/jill.txt jill"
echo "       sudo apply_acl_exam1.sh /public/tay.txt  tay"
echo "============================================="
