# sops-nix Setup Guide

## 📖 Overview

**sops-nix** encrypts your secrets using age or GPG keys. The encrypted secrets can be safely committed to Git, and only your server (with the private key) can decrypt them.

## 🔑 Initial Setup

### Step 1: Install sops and age

On your local machine (where you'll manage secrets):

```bash
# On NixOS
nix-shell -p sops age

# On macOS with Homebrew
brew install sops age

# On other Linux
# Download from: https://github.com/getsops/sops/releases
# and: https://github.com/FiloSottile/age/releases
```

### Step 2: Generate age Key

On your **server** (after NixOS is installed):

```bash
# Generate age key for the server
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt

# View the public key (you'll need this)
sudo age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Set permissions
sudo chmod 600 /var/lib/sops-nix/key.txt
```

**IMPORTANT**: Back up `/var/lib/sops-nix/key.txt` securely! Without it, you can't decrypt your secrets.

Alternative: Use SSH host key (automatically available):

```bash
# Get SSH host key public key
ssh-keyscan -t ed25519 localhost 2>/dev/null | ssh-to-age
# Output: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Step 3: Create .sops.yaml Configuration

On your **local machine** in your config directory:

```bash
cd /path/to/your/nixos-config

# Create .sops.yaml
cat > .sops.yaml << 'EOF'
keys:
  # Your age public key from Step 2
  - &server age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  
  # Optionally, add your personal key for local decryption
  # Generate with: age-keygen (on your laptop)
  # - &admin age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *server
          # - *admin  # If you added your personal key
EOF
```

### Step 4: Create and Edit Secrets File

```bash
# Create secrets directory
mkdir -p secrets

# Create/edit encrypted secrets file
sops secrets/secrets.yaml
```

This opens your editor with a template. Add your secrets:

```yaml
# secrets/secrets.yaml (before encryption)
database:
  authentik_password: "super-secret-password-here"
  immich_password: "another-secure-password"
  paperless_password: "yet-another-password"

authentik:
  secret_key: "long-random-string-here"

openwebui:
  secret_key: "another-long-random-string"

nextcloud:
  admin_password: "nextcloud-admin-password"

paperless:
  admin_password: "paperless-admin-password"

pgadmin:
  admin_password: "pgadmin-password"

restic:
  password: "backup-encryption-password"
  repository: "b2:my-bucket:path"  # or s3:... or /local/path
  b2_account_id: "your-b2-account-id"
  b2_account_key: "your-b2-account-key"
```

When you save and exit, sops automatically encrypts the file.

### Step 5: Verify Encryption

```bash
# View the encrypted file
cat secrets/secrets.yaml
# You'll see encrypted gibberish with metadata

# Edit again (it decrypts in your editor)
sops secrets/secrets.yaml

# View decrypted on command line
sops -d secrets/secrets.yaml
```

### Step 6: Commit to Git

```bash
# Update .gitignore
cat >> .gitignore << 'EOF'
# Secrets
key.txt
/var/lib/sops-nix/key.txt

# But DO commit the encrypted secrets!
EOF

# Add and commit
git add .sops.yaml secrets/secrets.yaml
git commit -m "Add encrypted secrets"
git push
```

## 🚀 Using on the Server

### First Deployment

```bash
# On server, after git clone
cd /etc/nixos

# The age key should already exist at /var/lib/sops-nix/key.txt
# (created in Step 2)

# Build the system
sudo nixos-rebuild switch --flake .#homeserver

# sops-nix will automatically decrypt secrets at build time
# and place them in /run/secrets/
```

### Accessing Secrets

Secrets are available at:
```bash
# Example paths (read-only, secured)
/run/secrets/database/authentik_password
/run/secrets/authentik/secret_key
/run/secrets/nextcloud/admin_password
# etc.
```

Services automatically read from these paths using the updated configuration.

## 🔄 Managing Secrets

### Adding New Secrets

```bash
# Edit secrets file
sops secrets/secrets.yaml

# Add new entry, save, commit
git add secrets/secrets.yaml
git commit -m "Add new secret"
git push

# On server
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake .#homeserver
```

### Rotating Secrets

```bash
# Same as adding - edit the file
sops secrets/secrets.yaml

# Change the password/key
# Save, commit, push, rebuild on server
```

### Adding Team Members

To let others decrypt secrets (for team management):

```bash
# Get their age public key
# They generate with: age-keygen

# Add to .sops.yaml
keys:
  - &server age1xxx...
  - &admin age1yyy...
  - &teammate age1zzz...  # Add this

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *server
          - *admin
          - *teammate  # Add this

# Rotate all secrets (re-encrypt with new keys)
sops updatekeys secrets/secrets.yaml

# Commit and push
git add .sops.yaml secrets/secrets.yaml
git commit -m "Add teammate to secrets access"
git push
```

## 🛠️ Troubleshooting

### Secret Not Found

```bash
# Check if secret exists
sops -d secrets/secrets.yaml | grep -A2 "secret_name"

# Check secret path in module
grep -r "sops.secrets" modules/

# Check if secret is defined in modules/secrets.nix
grep "secret_name" modules/secrets.nix
```

### Permission Denied

```bash
# Check secret file permissions on server
ls -la /run/secrets/

# Verify owner in modules/secrets.nix
# Each secret should have correct owner and mode

secrets = {
  "database/authentik_password" = {
    owner = "authentik";  # Must match service user
    mode = "0400";
  };
};
```

### Age Key Issues

```bash
# Verify age key exists
sudo ls -la /var/lib/sops-nix/key.txt

# Check public key
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Verify this matches .sops.yaml
cat .sops.yaml
```

### Can't Decrypt Locally

If you want to decrypt secrets on your laptop:

```bash
# Generate your own age key
age-keygen -o ~/.config/sops/age/keys.txt

# Get your public key
age-keygen -y ~/.config/sops/age/keys.txt

# Add to .sops.yaml (see "Adding Team Members")

# Re-encrypt secrets with your key included
sops updatekeys secrets/secrets.yaml

# Now you can decrypt
sops -d secrets/secrets.yaml
```

## 📋 Best Practices

1. **Backup the server key**: Store `/var/lib/sops-nix/key.txt` securely offline
2. **Use separate keys per environment**: Dev, staging, prod should have different keys
3. **Rotate secrets regularly**: Change passwords periodically
4. **Never commit unencrypted secrets**: Always verify with `git diff` before committing
5. **Use specific secret names**: `database/postgres/authentik_password` is better than `db_pass1`
6. **Document secrets**: Add comments in secrets.yaml about what each secret is for
7. **Audit access**: Review who has decrypt access regularly

## 🔍 Verifying Security

```bash
# Verify secrets are encrypted in git
git show HEAD:secrets/secrets.yaml
# Should show encrypted content

# Verify secrets aren't in git history unencrypted
git log -p --all -S 'super-secret-password' -- secrets/

# Check file permissions on server
sudo ls -la /run/secrets/
# Should be 0400 or 0440, owned by correct user
```

## 📚 Additional Resources

- [sops-nix GitHub](https://github.com/Mic92/sops-nix)
- [sops Documentation](https://github.com/getsops/sops)
- [age Documentation](https://age-encryption.org/)
- [NixOS Wiki - sops-nix](https://nixos.wiki/wiki/Sops-nix)

## 🎯 Quick Reference

```bash
# Edit secrets
sops secrets/secrets.yaml

# View decrypted
sops -d secrets/secrets.yaml

# Update keys after adding users
sops updatekeys secrets/secrets.yaml

# Check server secrets
ls -la /run/secrets/

# Rotate a specific secret
sops secrets/secrets.yaml  # Edit the value
git commit -am "Rotate secret"
git push
# On server: git pull && sudo nixos-rebuild switch
```
