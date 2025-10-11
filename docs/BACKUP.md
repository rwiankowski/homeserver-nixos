# Backup Management Guide

Your server automatically backs up to Azure Blob Storage using Restic with encryption and deduplication.

## What Gets Backed Up

### ✅ Included (~100-300GB)
- **Photos** (`/mnt/photos`) - Immich library
- **Documents** (`/mnt/docs`) - NextCloud and Paperless files
- **Application data** (`/mnt/shared`) - Databases, configs, settings
- **Home Assistant** - Automations and configs
- **Mealie** - Your recipes
- **Audiobook progress** - Listening positions

### ❌ Excluded (saves ~500GB+)
- **Media** (`/mnt/media`) - Jellyfin movies/TV (can be re-downloaded)
- **Thumbnails** - Automatically regenerated
- **Transcoding temp files** - Temporary
- **Download temp files** - In-progress downloads
- **Cache directories** - Not needed

**Why exclude media?**
- Saves $5-10/month in backup costs
- Media can be re-acquired
- Critical data (photos, documents) is protected

## Backup Schedule

**Automatic backups run:**
- **Time**: Daily at 2:00 AM
- **Duration**: 20-60 minutes (depending on changes)
- **Retention**:
  - Last 7 daily backups
  - Last 4 weekly backups
  - Last 6 monthly backups
  - Last 2 yearly backups

## Manual Backup

### Run Backup Now

```bash
# Trigger immediate backup
sudo systemctl start restic-backups-homeserver

# Watch progress
journalctl -u restic-backups-homeserver -f
```

### Check Last Backup

```bash
# View service status
systemctl status restic-backups-homeserver

# View timer schedule
systemctl list-timers restic-backups-homeserver
```

## Viewing Backups

### Set Environment Variables

```bash
# Set Azure credentials
export AZURE_ACCOUNT_NAME=$(sudo cat /run/secrets/restic/azure_account_name)
export AZURE_ACCOUNT_KEY=$(sudo cat /run/secrets/restic/azure_account_key)
export RESTIC_PASSWORD=$(sudo cat /run/secrets/restic/password)
export RESTIC_REPOSITORY=azure:restic-backups:/

# Or create an alias
alias restic-server='sudo -E restic'
```

### List Snapshots

```bash
# List all backups
sudo -E restic snapshots

# Output:
# ID        Time                 Host        Tags        Paths
# ---------------------------------------------------------------
# abc123    2025-01-15 02:00:00  homeserver              /mnt/photos
#                                                         /mnt/docs
#                                                         /mnt/shared
```

### Show Backup Statistics

```bash
# Total size and file count
sudo -E restic stats

# Latest snapshot size
sudo -E restic stats latest

# Statistics by snapshot
sudo -E restic stats abc123
```

## Restoring Files

### Restore Everything

```bash
# Restore latest backup to /restore
sudo mkdir -p /restore
sudo -E restic restore latest --target /restore

# Check restored files
ls -la /restore/
```

### Restore Specific Directory

```bash
# Restore just photos
sudo -E restic restore latest \
  --target /restore \
  --include /mnt/photos

# Restore just a specific folder
sudo -E restic restore latest \
  --target /restore \
  --include /mnt/docs/nextcloud/Documents
```

### Restore Specific File

```bash
# Find file in backups
sudo -E restic find "important.pdf"

# Restore that file
sudo -E restic restore latest \
  --target /restore \
  --include /mnt/docs/paperless/media/documents/2024/important.pdf
```

### Restore from Specific Date

```bash
# List snapshots
sudo -E restic snapshots

# Restore from specific snapshot ID
sudo -E restic restore abc123 --target /restore
```

## Disaster Recovery

If you need to rebuild your entire server:

### 1. Fresh NixOS Install

Follow [SETUP.md](SETUP.md) to install NixOS and deploy configuration.

### 2. Restore Latest Backup

```bash
# Set environment variables
export AZURE_ACCOUNT_NAME="your-storage-account"
export AZURE_ACCOUNT_KEY="your-account-key"
export RESTIC_PASSWORD="your-backup-password"
export RESTIC_REPOSITORY=azure:restic-backups:/

# Restore to original locations
sudo -E restic restore latest --target /
```

### 3. Fix Permissions

```bash
# Photos
sudo chown -R root:root /mnt/photos

# Docs
sudo chown -R nextcloud:nextcloud /mnt/docs/nextcloud
sudo chown -R paperless:paperless /mnt/docs/paperless

# Shared
sudo chown -R postgres:postgres /mnt/shared/postgresql
```

### 4. Restart Services

```bash
sudo systemctl restart postgresql
sudo systemctl restart nextcloud-setup
sudo systemctl restart paperless-scheduler
docker restart immich-server
```

**Recovery time**: 1-3 hours depending on backup size

## Backup Verification

### Monthly Health Check

```bash
# Check repository integrity
sudo -E restic check

# Deep check (reads all data, takes longer)
sudo -E restic check --read-data
```

### Test Restore

Regularly test that you can restore:

```bash
# Restore a random file
sudo -E restic find "*.jpg" | shuf -n 1
sudo -E restic restore latest --target /tmp/test --include <file-path>

# Verify it works
ls -la /tmp/test/

# Clean up
rm -rf /tmp/test
```

## Backup Management

### View What Would Be Backed Up

```bash
# Dry run
sudo -E restic backup \
  /mnt/photos /mnt/docs /mnt/shared \
  --dry-run
```

### Manually Prune Old Backups

Happens automatically, but you can run manually:

```bash
# Preview what would be deleted
sudo -E restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --keep-yearly 2 \
  --dry-run

# Actually prune
sudo -E restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --keep-yearly 2 \
  --prune
```

### Compare Snapshots

```bash
# See what changed between two backups
sudo -E restic diff snapshot1 snapshot2

# See what changed in latest backup
sudo -E restic diff
```

## Monitoring Backups

### Check Backup Age

```bash
# Get last backup time
sudo -E restic snapshots --latest 1 --json | jq -r '.[0].time'

# Check if older than 48 hours (alert!)
```

### Backup Logs

```bash
# View recent backup logs
journalctl -u restic-backups-homeserver -n 100

# View today's logs
journalctl -u restic-backups-homeserver --since today

# Follow live
journalctl -u restic-backups-homeserver -f
```

### Backup Size Over Time

```bash
# Show size progression
sudo -E restic snapshots --json | \
  jq -r '.[] | "\(.time) - \(.id[:8]) - Size: \(.size)"'
```

## Cost Optimization

### Current Costs

```bash
# Check backup size
sudo -E restic stats

# Typical: 100-300GB = $1-3/month in Azure Cool tier
```

### Reduce Backup Size

If costs are too high:

1. **Exclude more directories**:
   ```nix
   # In modules/backups.nix
   exclude = [
     # Add more exclusions
     "**/cache"
     "**/*.tmp"
     "/mnt/shared/sonarr/MediaCover"  # Cover art
   ];
   ```

2. **Adjust retention**:
   ```nix
   pruneOpts = [
     "--keep-daily 5"    # Reduce from 7
     "--keep-weekly 3"   # Reduce from 4
     "--keep-monthly 3"  # Reduce from 6
   ];
   ```

3. **Use lifecycle management** in Azure (automatic after 6 months)

## Alternative Backup Destinations

### Multiple Backup Locations

Add a second backup for critical data:

```nix
# modules/backups.nix
services.restic.backups = {
  azure = {
    # Existing Azure backup
  };
  
  local = {
    # Additional local backup
    repository = "/mnt/backup-drive/restic";
    paths = [ "/mnt/photos" "/mnt/docs" ];  # Critical only
    timerConfig.OnCalendar = "weekly";
  };
};
```

### Change Provider

To switch from Azure to Backblaze B2:

```yaml
# secrets.yaml
restic:
  repository: "b2:bucket-name:/"
  b2_account_id: "your-b2-id"
  b2_account_key: "your-b2-key"
```

Update `modules/backups.nix` to use B2 credentials.

## Troubleshooting

### Backup Failing

```bash
# Check logs
journalctl -u restic-backups-homeserver -n 50

# Common issues:
# - Azure credentials expired/wrong
# - Network connectivity
# - Disk full
# - Repository locked
```

### Repository Locked

If backup crashed and left lock:

```bash
# Check locks
sudo -E restic list locks

# Remove stale locks (be careful!)
sudo -E restic unlock

# Try backup again
```

### Out of Space

```bash
# Check disk usage
df -h

# Clean up
docker system prune -a
sudo nix-collect-garbage -d

# Exclude more from backups (see Cost Optimization)
```

### Slow Backups

```bash
# Check what's being uploaded
journalctl -u restic-backups-homeserver -f

# Exclude large unnecessary files
# Check Azure bandwidth limits
```

## Best Practices

1. **Test restores monthly** - Backups are useless if you can't restore
2. **Monitor backup age** - Alert if > 48 hours old
3. **Check repository health** - Run `restic check` monthly
4. **Keep multiple copies** - 3-2-1 rule (3 copies, 2 media, 1 offsite)
5. **Document recovery** - Keep recovery notes in password manager
6. **Encrypt separately** - Restic encryption + Azure encryption = double protection

## Quick Reference

```bash
# Backup now
sudo systemctl start restic-backups-homeserver

# List backups
sudo -E restic snapshots

# Restore everything
sudo -E restic restore latest --target /restore

# Restore specific path
sudo -E restic restore latest --target /restore --include /mnt/photos

# Find file
sudo -E restic find "filename"

# Check health
sudo -E restic check

# View size
sudo -E restic stats

# Prune old backups
sudo -E restic forget --keep-daily 7 --keep-weekly 4 --prune
```

---

**Your data is safe! Remember: backups are insurance - test them before you need them. 🔐**
