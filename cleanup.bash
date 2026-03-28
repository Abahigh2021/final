#!/usr/bin/env bash
set -euo pipefail

# Cleanup script for old bootstrap artifacts
# Run as root: sudo bash cleanup_old_bootstrap.sh

TS=$(date +%Y%m%d-%H%M%S)
BACKDIR="/root/cleanup_backup_${TS}"
mkdir -p "$BACKDIR"

echo "Backup directory: $BACKDIR"

# 1) Backup important state
echo "Backing up /etc/ssh/sshd_config to $BACKDIR/sshd_config.bak"
cp -a /etc/ssh/sshd_config "$BACKDIR/sshd_config.bak" 2>/dev/null || true

echo "Backing up /etc/group and /etc/passwd excerpts for target users/groups"
grep -E '^(jack|jill|tay|aba-hadi):' /etc/passwd > "$BACKDIR"/passwd_users_$(date +%s).txt 2>/dev/null || true
grep -E '^(attack|defend|bot|jack|jill|tay|aba-hadi):' /etc/group > "$BACKDIR"/groups_$(date +%s).txt 2>/dev/null || true

echo "Backing up /public ACLs and listing (if present)"
if [ -d /public ]; then
  getfacl -R /public > "$BACKDIR"/public_getfacl_${TS}.txt 2>/dev/null || true
  ls -ld /public > "$BACKDIR"/public_ls_${TS}.txt 2>/dev/null || true
  tar -czf "$BACKDIR"/public_contents_${TS}.tgz /public 2>/dev/null || true
fi

echo "Backing up home directories (if present)"
tar -czf "$BACKDIR"/home_backup_${TS}.tgz /home/jack /home/jill /home/tay /home/aba-hadi 2>/dev/null || true

# 2) Remove users and their home directories
USERS=(jack jill tay aba-hadi)
for u in "${USERS[@]}"; do
  if id -u "$u" >/dev/null 2>&1; then
    echo "Removing user and home: $u"
    # prefer deluser on Debian/Ubuntu, fallback to userdel
    if command -v deluser >/dev/null 2>&1; then
      deluser --remove-home "$u" 2>/dev/null || true
    else
      userdel -r "$u" 2>/dev/null || true
    fi
  else
    echo "User $u not present"
  fi
done

# 3) Remove groups created by the bootstrap
GROUPS=(attack defend bot jack jill tay aba-hadi)
for g in "${GROUPS[@]}"; do
  if getent group "$g" >/dev/null 2>&1; then
    echo "Deleting group: $g"
    groupdel "$g" 2>/dev/null || echo "Could not delete group $g (may be in use)"
  else
    echo "Group $g not present"
  fi
done

# 4) Remove /public safely (move to backup)
if [ -d /public ]; then
  echo "Moving /public to $BACKDIR/public_removed_${TS}"
  mv /public "$BACKDIR"/public_removed_${TS} 2>/dev/null || { echo "Move failed, attempting rm -rf /public"; rm -rf /public || true; }
else
  echo "/public not present"
fi

# 5) Remove ACL and helper scripts installed earlier
echo "Removing helper scripts from /usr/local/bin and /usr/local/sbin"
rm -f /usr/local/bin/apply_acl_*.sh /usr/local/sbin/apply_acl_*.sh 2>/dev/null || true
rm -f /usr/local/bin/upload-*.sh /usr/local/sbin/upload-*.sh 2>/dev/null || true

# 6) Remove any per-user ~/bin upload scripts
echo "Removing upload scripts from user home bin directories"
for d in /home/*/bin; do
  if [ -d "$d" ]; then
    rm -f "$d"/upload-*.sh "$d"/upload_*.sh 2>/dev/null || true
  fi
done

# 7) Remove temporary files in /tmp created by bootstrap
echo "Cleaning /tmp bootstrap files"
rm -f /tmp/bootstrap_gateway.* /tmp/bootstrap_run.log 2>/dev/null || true

# 8) Optional: restore sshd_config from backup if you want to revert changes
# Uncomment the following lines to restore the backed up sshd_config
# if [ -f "$BACKDIR/sshd_config.bak" ]; then
#   echo "Restoring sshd_config from backup"
#   cp -a "$BACKDIR/sshd_config.bak" /etc/ssh/sshd_config
#   systemctl restart sshd || true
# fi

# 9) Final verification output
echo "Verification: users and groups"
for u in "${USERS[@]}"; do
  id "$u" >/dev/null 2>&1 && echo "ERROR: user $u still exists" || echo "OK: user $u removed"
done

for g in "${GROUPS[@]}"; do
  getent group "$g" >/dev/null 2>&1 && echo "ERROR: group $g still exists" || echo "OK: group $g removed"
done

if [ -d /public ]; then
  echo "WARNING: /public still exists at $(ls -ld /public)"
else
  echo "OK: /public removed or moved to backup"
fi

echo "Cleanup complete. Backups stored in $BACKDIR"
