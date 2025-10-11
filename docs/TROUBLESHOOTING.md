# Troubleshooting Guide

Common issues and their solutions.

## General Debugging

### Check Service Status

```bash
# NixOS service
systemctl status servicename

# Docker container
docker ps
docker logs containername

# All failed services
systemctl --failed
```

### View Logs

```bash
# Recent logs
journalctl -xe

# Specific service
journalctl -u servicename -n 100

# Follow logs
journalctl -u servicename -f

# Since today
journalctl --since today

# Errors only
journalctl -p err -b
```

### Rollback Configuration

If something breaks after rebuild:

```bash
# Rollback to previous configuration
sudo nixos-rebuild switch --rollback

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to specific generation
sudo nixos-rebuild switch --rollback --profile-name system-42-link
```

---

## Deployment Issues

### Build Fails

**Error**: `error: attribute 'X' missing`

**Solution**: Check your `vars.nix` is properly formatted and all required fields are set.

```bash
# Validate Nix syntax
nix-instantiate --parse configuration.nix

# Check flake
nix flake check
```

**Error**: `sops: failed to decrypt`

**Solution**: Age key not found or incorrect.

```bash
# Check age key exists
sudo ls -la /var/lib/sops-nix/key.txt

# Verify it's the right key
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Compare with .sops.yaml
cat secrets/.sops.yaml
```

### First Boot Issues

**Symptom**: Services not starting after first deploy

**Solution**: Some services need manual first-time setup:

```bash
# Restart all services
sudo systemctl restart postgresql
sudo systemctl restart authentik-server
sudo systemctl restart caddy

# Check what failed
systemctl --failed
```

---

## Network & Connectivity

### Can't Access Services

**Check Tailscale**:

```bash
# Is Tailscale running?
tailscale status

# Am I connected?
tailscale ip

# Can I ping server?
ping 100.x.x.x
```

**Check Caddy**:

```bash
# Is Caddy running?
systemctl status caddy

# Check configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# View Caddy logs
journalctl -u caddy -n 50
```

**Check Firewall**:

```bash
# Is service listening?
sudo ss -tlnp | grep :8096  # Jellyfin example

# Check firewall rules
sudo nft list ruleset

# Test locally
curl -I http://localhost:8096
```

### Certificate Errors

**Symptom**: Browser shows "Not Secure" or certificate warnings

**Check certificates obtained**:

```bash
# List certificates
sudo caddy list-certificates

# Should show certificates for all services
```

**If no certificates**:

```bash
# Check Caddy logs
journalctl -u caddy -n 100

# Common issues:
# - Azure credentials wrong
# - DNS not propagated
# - Rate limit hit
```

**Check Azure DNS**:

```bash
# Test DNS resolution
dig jellyfin.home.yourdomain.com

# Should resolve to Tailscale hostname
# Then to 100.x.x.x IP
```

**Check Azure Service Principal**:

```bash
# Test authentication
az login --service-principal \
  -u $(sudo cat /run/secrets/azure/client_id) \
  -p $(sudo cat /run/secrets/azure/client_secret) \
  --tenant $(sudo cat /run/secrets/azure/tenant_id)

# Should succeed without error
```

---

## Database Issues

### PostgreSQL Won't Start

```bash
# Check logs
journalctl -u postgresql -n 50

# Check disk space
df -h /mnt/shared

# Check permissions
ls -la /mnt/shared/postgresql

# Restart
sudo systemctl restart postgresql
```

### Can't Connect to Database

```bash
# Test local connection
sudo -u postgres psql -l

# Check if listening
sudo ss -tlnp | grep :5432

# Check authentication
sudo cat /var/lib/postgresql/16/data/pg_hba.conf
```

### Database Corruption

```bash
# Check integrity
sudo -u postgres postgres --single -D /var/lib/postgresql/16/data

# Restore from backup (see BACKUP.md)
```

---

## Docker Container Issues

### Container Won't Start

```bash
# Check status
docker ps -a | grep containername

# View logs
docker logs containername --tail 50

# Check for errors
docker inspect containername

# Restart
docker restart containername
```

### Container Keeps Restarting

```bash
# Check logs
docker logs containername

# Common issues:
# - Missing environment variables
# - Volume permissions
# - Port conflicts
```

### Fix Volume Permissions

```bash
# Check permissions
ls -la /mnt/shared/containername

# Fix permissions
sudo chown -R 1000:1000 /mnt/shared/containername

# Restart container
docker restart containername
```

---

## Service-Specific Issues

### Jellyfin

**Can't play media**:

```bash
# Check file permissions
ls -la /mnt/media/jellyfin/movies

# Fix permissions
sudo chown -R media:media /mnt/media/jellyfin

# Check logs
journalctl -u jellyfin -n 50
```

**Transcoding fails**:

```bash
# Check ffmpeg
ffmpeg -version

# Check GPU (if using)
nvidia-smi  # NVIDIA
rocm-smi    # AMD

# Disable hardware transcoding and test
```

### Immich

**Upload fails**:

```bash
# Check logs
docker logs immich-server

# Check disk space
df -h /mnt/photos

# Check permissions
ls -la /mnt/photos/immich/upload
```

### NextCloud

**Can't login**:

```bash
# Check admin password
sudo cat /run/secrets/nextcloud/admin_password

# Reset password
sudo -u nextcloud nextcloud-occ user:resetpassword admin

# Check logs
journalctl -u nextcloud-setup -n 50
```

**Slow/timeout**:

```bash
# Check PHP settings
# Increase timeouts in modules/nextcloud.nix

# Check database
sudo -u postgres psql -d nextcloud -c "SELECT * FROM oc_appconfig WHERE configkey='maintenance';"
```

### Paperless

**OCR not working**:

```bash
# Check OCR languages
journalctl -u paperless-consumer -n 50

# Test OCR
sudo -u paperless paperless-manage document_ocr 1
```

**Documents not consuming**:

```bash
# Check consumption directory
ls -la /mnt/docs/paperless/consume

# Check permissions
sudo chown -R paperless:paperless /mnt/docs/paperless

# Check logs
journalctl -u paperless-consumer -f
```

### Home Assistant

**Integration won't connect**:

```bash
# Check logs
journalctl -u home-assistant -n 50

# Check network
# Some integrations require mDNS/broadcast
```

### Open WebUI (Ollama)

**Model not loading**:

```bash
# Check Ollama service
systemctl status ollama

# List models
ollama list

# Check model exists
ls -la /var/lib/ollama/models

# Pull model again
ollama pull llama3.1:8b
```

**Out of memory**:

```bash
# Check RAM usage
free -h

# 8B models need ~6GB RAM
# 70B models need ~64GB RAM

# Use smaller model or add more RAM
```

---

## Storage Issues

### Disk Full

```bash
# Check disk usage
df -h

# Find largest directories
du -sh /mnt/*/* | sort -rh | head -20

# Clean Docker
docker system prune -a
docker volume prune

# Clean Nix
sudo nix-collect-garbage -d
sudo nix-store --optimize

# Clean logs
sudo journalctl --vacuum-time=7d
```

### Slow Disk Performance

```bash
# Check I/O
iotop

# Check disk health
smartctl -a /dev/sda

# Check if SSD/HDD is correct
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,MODEL
```

---

## Backup Issues

### Backup Failing

See [BACKUP.md](BACKUP.md) for detailed backup troubleshooting.

Quick check:

```bash
# Check last backup
systemctl status restic-backups-homeserver

# Check logs
journalctl -u restic-backups-homeserver -n 50

# Test Azure connection
az storage account show --name yourstorageaccount
```

---

## Security Issues

### CrowdSec Not Blocking

```bash
# Check CrowdSec status
systemctl status crowdsec

# Check decisions
sudo cscli decisions list

# Check bouncer
systemctl status crowdsec-firewall-bouncer

# Check metrics
sudo cscli metrics
```

### Fail2ban Not Working

```bash
# Check status
systemctl status fail2ban

# Check jails
sudo fail2ban-client status

# Check SSH jail
sudo fail2ban-client status sshd

# Unban IP
sudo fail2ban-client unban 1.2.3.4
```

### SSH Access Lost

**Prevention**: Always keep a console/VNC access to your server!

**Recovery**:

1. Access via Proxmox console
2. Login as root
3. Check firewall: `nft list ruleset`
4. Temporarily allow your IP
5. Fix configuration
6. Rebuild

---

## Performance Issues

### High CPU Usage

```bash
# Check processes
htop

# Check systemd
systemd-cgtop

# Common culprits:
# - Immich ML processing
# - Jellyfin transcoding
# - Paperless OCR
# - Ollama inference
```

### High Memory Usage

```bash
# Check memory
free -h

# Check per-process
ps aux --sort=-%mem | head -20

# Clear page cache (safe)
sudo sync && sudo sysctl -w vm.drop_caches=3
```

### Network Slow

```bash
# Check bandwidth
iftop

# Check Tailscale connection type
tailscale status

# Look for "relay" vs "direct"
# Relay is slower, might be firewall issue
```

---

## Update Issues

### System Won't Update

```bash
# Check channel
nix-channel --list

# Update flake
nix flake update

# Try building without switching
nixos-rebuild build --flake .#homeserver

# Check logs for specific error
```

### Service Breaks After Update

```bash
# Rollback
sudo nixos-rebuild switch --rollback

# Check what changed
nix store diff-closures /run/current-system /nix/var/nix/profiles/system-43-link

# Fix and rebuild
```

---

## Emergency Recovery

### System Won't Boot

1. Boot from NixOS ISO
2. Mount system:
   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mount /dev/disk/by-label/boot /mnt/boot
   ```
3. Chroot:
   ```bash
   nixos-enter
   ```
4. Rollback or fix configuration
5. Rebuild:
   ```bash
   nixos-rebuild switch
   ```
6. Reboot

### Lost Configuration

If you lost your configuration but have it in GitHub:

```bash
# Clone from GitHub
git clone https://github.com/yourusername/nixos-homeserver /etc/nixos

# Regenerate hardware config
nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix

# Setup secrets again (see SOPS.md)

# Rebuild
nixos-rebuild switch --flake .#homeserver
```

### Lost Age Key

If you lost `/var/lib/sops-nix/key.txt`:

1. You **cannot** decrypt existing secrets
2. Generate new age key
3. Update `.sops.yaml` with new public key
4. Re-encrypt secrets: `sops updatekeys secrets/secrets.yaml`
5. Rebuild system

**Prevention**: Keep age key in password manager!

---

## Getting More Help

### Enable Debug Logging

```bash
# For specific service
systemctl edit servicename

# Add:
[Service]
Environment="DEBUG=*"

# Restart
systemctl restart servicename
```

### Collect Debug Info

```bash
# Create debug bundle
mkdir debug-info
journalctl -b > debug-info/journal.log
systemctl status > debug-info/services.txt
docker ps -a > debug-info/docker.txt
nix-info > debug-info/nix-info.txt
df -h > debug-info/disk.txt
free -h > debug-info/memory.txt

# Tar it up
tar czf debug-info.tar.gz debug-info/
```

### Where to Ask

1. **This Repository**: Open an issue on GitHub
2. **NixOS Discourse**: https://discourse.nixos.org
3. **NixOS Matrix**: #nixos:nixos.org
4. **Reddit**: r/NixOS, r/selfhosted
5. **Service-specific**: Each service's GitHub/Discord

### What to Include

When asking for help:

1. **What you're trying to do**
2. **What's happening** (error messages, logs)
3. **What you've tried**
4. **Your environment** (NixOS version, hardware)
5. **Relevant config** (redact secrets!)

---

## Prevention Tips

1. **Test changes** - Use `nixos-rebuild build` before `switch`
2. **Small changes** - One change at a time
3. **Git commits** - Commit working states
4. **Backups** - Test restores monthly
5. **Documentation** - Document customizations
6. **Monitoring** - Check Grafana regularly
7. **Updates** - Keep system updated
8. **Logs** - Check logs occasionally

---

**Remember**: Every problem is solvable. Take a breath, read logs, and debug systematically. 🔧**
