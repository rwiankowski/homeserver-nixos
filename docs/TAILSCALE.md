# Tailscale Configuration Guide

Tailscale provides zero-config VPN access to your home server. All services are accessible only via Tailscale - no ports exposed to the internet.

## What is Tailscale?

Tailscale creates a secure, encrypted network between your devices using WireGuard. It's:
- **Zero-config** - Works through firewalls and NATs automatically
- **Secure** - End-to-end encrypted with WireGuard
- **Fast** - Direct connections when possible
- **Free** - Personal use tier includes everything you need

## Prerequisites

- Tailscale account (sign up at https://tailscale.com)
- Server deployed with this NixOS configuration

## Initial Setup

### Step 1: Create Tailscale Account

1. Go to https://tailscale.com
2. Sign up (free personal account)
3. You can use: Google, Microsoft, GitHub, or email

### Step 2: Connect Your Server

```bash
# SSH to your server
ssh root@your-server-ip

# Start Tailscale
sudo tailscale up

# Follow the URL to authenticate
# Opens: https://login.tailscale.com/a/xxxx
```

### Step 3: Verify Connection

```bash
# Check status
tailscale status

# Output shows:
# homeserver    yourusername@  linux   -
#   100.115.92.10   homeserver.tail-scale.ts.net

# Your Tailscale IP: 100.115.92.10
# Your Tailscale hostname: homeserver.tail-scale.ts.net
```

**Save these values!** You'll need them for DNS configuration.

## Install Tailscale on Your Devices

### Linux

```bash
# Ubuntu/Debian
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### macOS

```bash
# Download from https://tailscale.com/download/mac
# Or use Homebrew
brew install --cask tailscale
```

### Windows

1. Download from https://tailscale.com/download/windows
2. Install and run
3. Sign in with your Tailscale account

### iOS

1. App Store → Search "Tailscale"
2. Install
3. Sign in

### Android

1. Play Store → Search "Tailscale"
2. Install
3. Sign in

## Accessing Your Services

Once connected to Tailscale, access services at:

```
https://home.home.yourdomain.com
https://jellyfin.home.yourdomain.com
https://immich.home.yourdomain.com
... etc
```

Or via Tailscale IP directly:
```
https://100.x.x.x
```

## Enabling MagicDNS (Recommended)

MagicDNS allows you to use short names instead of IP addresses.

### Step 1: Enable in Admin Console

1. Go to https://login.tailscale.com/admin/dns
2. Click "Enable MagicDNS"
3. Confirm

### Step 2: Use Short Names

Now you can access your server as:
```bash
ssh homeserver
ping homeserver
```

Instead of:
```bash
ssh 100.x.x.x
```

Your services remain at full URLs:
```
https://jellyfin.home.yourdomain.com
```

## Advanced Configuration

### Split DNS

To use your custom domain (`home.yourdomain.com`) with Tailscale:

1. Admin console → DNS → Add nameserver
2. Enable "Override local DNS"
3. Your custom DNS is already configured via Azure

### Subnet Router (Optional)

Make your entire home network accessible via Tailscale:

```bash
# On your server
sudo tailscale up --advertise-routes=192.168.1.0/24

# In admin console
# Approve the route
```

Now devices on your home network are accessible from anywhere!

### Exit Node (Optional)

Use your home server as VPN exit node:

```bash
# On server
sudo tailscale up --advertise-exit-node

# On client
tailscale up --exit-node=homeserver
```

All internet traffic now goes through your home server.

## Security Best Practices

### 1. Use ACLs (Access Control Lists)

Control who can access what:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["homeserver:*"]
    }
  ]
}
```

### 2. Enable Two-Factor Authentication

1. Admin console → Settings → Account
2. Enable 2FA
3. Use authenticator app

### 3. Key Expiry

Enable automatic key expiry for devices:

1. Admin console → Settings
2. Key expiry → 180 days
3. Devices must re-authenticate periodically

### 4. Review Devices Regularly

1. Admin console → Machines
2. Remove old/unused devices
3. Check last seen timestamps

## Sharing Access with Family/Friends

### Option 1: Tailscale Account (Recommended)

1. Admin console → Settings → Users
2. Share invite link
3. They create their own Tailscale account
4. They get access to shared machines

### Option 2: Share Node

1. Admin console → Machines
2. Select your server
3. Share → Create shareable link
4. Send to friend
5. They can access without Tailscale account

**Note**: Use ACLs to control what shared users can access!

## Troubleshooting

### Can't Connect to Server

```bash
# Check Tailscale status on server
ssh root@server-original-ip
sudo tailscale status

# Check if service is running
sudo systemctl status tailscaled

# Restart if needed
sudo systemctl restart tailscaled
sudo tailscale up
```

### Connection is Slow

```bash
# Check if direct connection
tailscale status

# Look for "direct" or "relay"
# If relay, might be firewall issues

# Try enabling UPnP on router
# Or configure port forwarding: UDP 41641
```

### Can't Access Services

```bash
# Verify DNS resolution
dig jellyfin.home.yourdomain.com

# Should resolve to 100.x.x.x

# Check from server
curl -I http://localhost:8096  # Jellyfin example

# Check Caddy is running
sudo systemctl status caddy
```

### MagicDNS Not Working

```bash
# Check MagicDNS is enabled
tailscale status | grep "MagicDNS"

# Check search domains
tailscale status | grep "Search"

# Restart Tailscale
sudo tailscale down
sudo tailscale up
```

## Mobile App Tips

### iOS

- Enable "Always On" in app settings
- Allow location access for automatic connection
- Add services to home screen as web apps

### Android

- Enable "Always On VPN" in settings
- Disable battery optimization for Tailscale
- Use widget for quick on/off

## Monitoring

### Check Connected Devices

```bash
# On any device
tailscale status

# Shows all connected devices in your network
```

### View Traffic

Admin console shows:
- Active connections
- Data transfer
- Connection types (direct/relay)
- Device last seen

## Cost

**Free tier includes:**
- Up to 100 devices
- 3 users
- Unlimited traffic
- All features (MagicDNS, subnet router, exit node)

**Paid plans** ($5/user/month) add:
- More users
- Better ACLs
- Longer logs
- Support

For personal home server: **Free tier is perfect!**

## Integration with This Config

This NixOS configuration automatically:
- ✅ Installs Tailscale
- ✅ Configures firewall to trust Tailscale
- ✅ Allows Caddy to work with Tailscale IPs
- ✅ No exposed ports (only Tailscale + SSH)

You just need to:
1. `sudo tailscale up`
2. Authenticate
3. Done!

## Alternatives to Tailscale

If you prefer other solutions:

- **WireGuard** - Manual configuration, more control
- **ZeroTier** - Similar to Tailscale
- **OpenVPN** - Traditional VPN (complex)
- **Cloudflare Tunnel** - Zero-trust tunnel (different model)

This config uses Tailscale for simplicity and security.

## Resources

- Official docs: https://tailscale.com/kb/
- Status page: https://status.tailscale.com/
- Blog: https://tailscale.com/blog/
- GitHub: https://github.com/tailscale

## Quick Reference

```bash
# Start Tailscale
sudo tailscale up

# Stop Tailscale
sudo tailscale down

# Check status
tailscale status

# Get IP
tailscale ip

# Check version
tailscale version

# Update (on non-NixOS)
sudo tailscale update

# On NixOS: rebuild system
sudo nixos-rebuild switch
```

---

**Your home server is now securely accessible from anywhere! 🌍**
