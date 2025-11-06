# Local Network Access Configuration

This document explains how to access your homeserver services from your local network (LAN) using the same domain names as Tailscale VPN access.

## Overview

The homeserver supports seamless access from both Tailscale VPN and your local network using **the same domain names**:

- **Tailscale VPN Access**: `https://media.home.lucy31.cloud` → Routes via Tailscale (100.x.x.x)
- **Local Network Access**: `https://media.home.lucy31.cloud` → Routes via LAN (172.16.1.162)

The routing happens automatically based on DNS resolution:
- When connected to Tailscale, DNS resolves to the Tailscale IP
- When on your local network, DNS resolves to the server's LAN IP

## How It Works

### DNS Resolution

The key to this setup is **DNS-based routing**:

1. **Tailscale DNS**: When connected to Tailscale VPN, `*.home.lucy31.cloud` resolves to the server's Tailscale IP (e.g., `100.64.1.5`)
2. **Local DNS**: When on your local network, your DNS server (router/Pi-hole/etc.) resolves `*.home.lucy31.cloud` to the server's LAN IP (`172.16.1.162`)

### Caddy Configuration

Caddy is configured with domain-based virtual hosts for each service:

```nix
"media.home.lucy31.cloud" = {
  extraConfig = ''
    reverse_proxy localhost:8096
  '';
};
```

These virtual hosts work for **both** Tailscale and LAN access because:
- Caddy listens on all network interfaces (no bind address restriction)
- The firewall trusts both the Tailscale interface and the LAN interface
- The same Let's Encrypt certificates work for both access methods

### Firewall Configuration

The firewall is configured to trust:
- ✅ `tailscale0` - Tailscale VPN interface
- ✅ `enp24s0` - LAN interface (when `enableLocalAccess = true`)
- ✅ `docker0` - Docker bridge interface

This allows HTTPS traffic from both Tailscale and your local network to reach Caddy.

## Configuration

### 1. Enable Local Access

In your `vars.nix` file, configure the following settings:

```nix
networking = {
  # ... existing domain configuration ...
  
  # Local network access
  lanInterface = "enp24s0";                # Your LAN network interface
  enableLocalAccess = true;                # Enable access from local network
};
```

### 2. Configure Local DNS

You need to configure your local DNS server to resolve `*.home.lucy31.cloud` to your server's LAN IP address.

#### Option A: Router DNS (Recommended)

Most routers allow you to add custom DNS entries:

1. Log into your router's admin interface
2. Find the DNS or DHCP settings
3. Add a DNS entry:
   - **Hostname**: `*.home.lucy31.cloud` (or individual entries for each service)
   - **IP Address**: `172.16.1.162` (your server's LAN IP)

#### Option B: Pi-hole

If you're using Pi-hole for DNS:

1. Log into Pi-hole admin interface
2. Go to **Local DNS** → **DNS Records**
3. Add entries for each service:
   - `media.home.lucy31.cloud` → `172.16.1.162`
   - `photos.home.lucy31.cloud` → `172.16.1.162`
   - `docs.home.lucy31.cloud` → `172.16.1.162`
   - etc.

Or use a wildcard entry if your Pi-hole version supports it:
- `*.home.lucy31.cloud` → `172.16.1.162`

#### Option C: /etc/hosts (Per-Device)

If you can't configure DNS server-wide, you can add entries to each device's `/etc/hosts` file:

**Linux/macOS**:
```bash
sudo nano /etc/hosts
```

**Windows**:
```
notepad C:\Windows\System32\drivers\etc\hosts
```

Add entries:
```
172.16.1.162 media.home.lucy31.cloud
172.16.1.162 photos.home.lucy31.cloud
172.16.1.162 docs.home.lucy31.cloud
# ... add all services you want to access
```

### 3. Find Your LAN Interface Name

To find your network interface name, run:

```bash
ip link
```

Common interface names:
- **Proxmox VMs**: `ens18`, `ens19`
- **Physical servers**: `eth0`, `enp0s3`, `eno1`, `enp24s0`
- **Wireless**: `wlan0`, `wlp2s0`

Look for the interface that's connected to your local network (usually shows `state UP`).

### 4. Apply Configuration

After updating `vars.nix`, rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Accessing Services

All services use the **same URLs** regardless of network:

| Service | URL | Works On |
|---------|-----|----------|
| Homepage | `https://dash.home.lucy31.cloud` | Tailscale + LAN |
| Jellyfin | `https://media.home.lucy31.cloud` | Tailscale + LAN |
| Immich | `https://photos.home.lucy31.cloud` | Tailscale + LAN |
| Nextcloud | `https://docs.home.lucy31.cloud` | Tailscale + LAN |
| Mealie | `https://recipes.home.lucy31.cloud` | Tailscale + LAN |
| Home Assistant | `https://assistant.home.lucy31.cloud` | Tailscale + LAN |
| LLM Assistant | `https://chat.home.lucy31.cloud` | Tailscale + LAN |
| Sonarr | `https://sonarr.home.lucy31.cloud` | Tailscale + LAN |
| Radarr | `https://radarr.home.lucy31.cloud` | Tailscale + LAN |
| Prowlarr | `https://prowlarr.home.lucy31.cloud` | Tailscale + LAN |
| Bazarr | `https://bazarr.home.lucy31.cloud` | Tailscale + LAN |
| Readarr | `https://books.home.lucy31.cloud` | Tailscale + LAN |
| Lidarr | `https://music.home.lucy31.cloud` | Tailscale + LAN |
| qBittorrent | `https://downloads.home.lucy31.cloud` | Tailscale + LAN |
| Jellyseerr | `https://discover.home.lucy31.cloud` | Tailscale + LAN |
| Homarr | `https://watch.home.lucy31.cloud` | Tailscale + LAN |
| Paperless | `https://scans.home.lucy31.cloud` | Tailscale + LAN |
| Audiobookshelf | `https://audiobooks.home.lucy31.cloud` | Tailscale + LAN |
| Authentik SSO | `https://sso.home.lucy31.cloud` | Tailscale + LAN |
| pgAdmin | `https://pgadmin.home.lucy31.cloud` | Tailscale + LAN |
| Grafana | `https://monitor.home.lucy31.cloud` | Tailscale + LAN |

### How Routing Works

**When you access `https://media.home.lucy31.cloud`:**

1. **DNS Resolution**:
   - On Tailscale: Resolves to `100.x.x.x` (Tailscale IP)
   - On LAN: Resolves to `172.16.1.162` (LAN IP)

2. **Network Routing**:
   - On Tailscale: Traffic goes through VPN tunnel
   - On LAN: Traffic goes directly over local network (faster!)

3. **Caddy Receives Request**:
   - Same virtual host handles both requests
   - Same reverse proxy configuration
   - Same Let's Encrypt certificate

4. **Service Responds**:
   - Identical experience on both networks
   - No configuration changes needed in services

## SSL Certificates

### Let's Encrypt Certificates

All services use **Let's Encrypt** certificates obtained via Azure DNS challenge:

- ✅ Trusted by all browsers automatically
- ✅ No manual certificate installation needed
- ✅ Works for both Tailscale and LAN access
- ✅ Automatically renewed every 90 days

Since the certificates are issued for `*.home.lucy31.cloud`, they work regardless of how the DNS resolves (Tailscale IP or LAN IP).

### No Self-Signed Certificates

Unlike traditional local network setups, you **don't need** to:
- ❌ Generate self-signed certificates
- ❌ Trust a local CA
- ❌ Deal with browser warnings
- ❌ Install certificates on every device

The same trusted certificates work everywhere!

## Security Considerations

### What's Protected

✅ **Internet access is completely blocked**
- No ports exposed to the internet
- Firewall only trusts specific interfaces (Tailscale + LAN)
- Services remain private and secure

✅ **Interface-specific access control**
- Only Tailscale and configured LAN interface can access services
- Other interfaces remain blocked
- Docker containers can communicate internally

✅ **CrowdSec protection**
- Monitors access logs for suspicious activity
- Automatically blocks repeated failed login attempts
- Protects both Tailscale and LAN access

### What's Not Protected

⚠️ **Anyone on your local network can access services**
- If someone connects to your WiFi, they can access the homeserver
- Use strong WiFi passwords (WPA3 recommended)
- Consider enabling service-level authentication (Authentik SSO)
- Use guest WiFi networks for untrusted devices

⚠️ **DNS-based routing can be bypassed**
- Users can manually edit `/etc/hosts` to override DNS
- This is generally not a concern for home networks
- Use Authentik SSO for additional authentication layer

## Advantages of This Approach

### 1. **Consistent URLs**
- Same bookmarks work everywhere
- No need to remember different URLs for different networks
- Mobile apps work seamlessly on both networks

### 2. **Faster Local Access**
- LAN traffic doesn't go through Tailscale VPN
- Lower latency for local devices
- Better streaming performance (Jellyfin, Immich)

### 3. **Automatic Failover**
- If Tailscale is down, local access still works
- If local DNS is down, Tailscale access still works
- No single point of failure

### 4. **Trusted Certificates**
- No browser warnings
- No manual certificate installation
- Works on all devices (phones, tablets, smart TVs)

### 5. **Simple Configuration**
- No path-based routing complexity
- No service-specific configuration needed
- Services don't need to know about base paths

## Troubleshooting

### Cannot access services from LAN

**Problem**: Services work on Tailscale but not on local network

**Solutions**:

1. **Verify DNS resolution**:
   ```bash
   # From a device on your LAN
   nslookup media.home.lucy31.cloud
   # Should return 172.16.1.162
   ```

2. **Check if local DNS is configured**:
   - Verify your router/Pi-hole has the DNS entries
   - Try accessing by IP: `https://172.16.1.162` (will show certificate error but should connect)

3. **Verify firewall rules**:
   ```bash
   # On the server
   sudo nft list ruleset | grep enp24s0
   # Should show enp24s0 in trusted interfaces
   ```

4. **Check Caddy is listening**:
   ```bash
   sudo ss -tlnp | grep caddy
   # Should show :443 LISTEN
   ```

5. **Verify `enableLocalAccess` is true**:
   ```bash
   grep enableLocalAccess /home/rwiankowski/Projects/HomeServer/homeserver-nixos/vars.nix
   # Should show: enableLocalAccess = true;
   ```

### DNS resolves to wrong IP

**Problem**: `nslookup` shows Tailscale IP instead of LAN IP when on local network

**Solutions**:

1. **Check DNS server priority**:
   - Your device might be using Tailscale DNS instead of local DNS
   - On most devices, local DNS should take priority
   - Try disabling Tailscale temporarily to test

2. **Configure split DNS**:
   - In Tailscale admin console, configure split DNS
   - Set `*.home.lucy31.cloud` to use local DNS when on LAN
   - See [Tailscale Split DNS documentation](https://tailscale.com/kb/1054/dns/)

3. **Use local DNS override**:
   - Configure your router to override Tailscale DNS for local devices
   - Most routers allow forcing DHCP clients to use router DNS

### Certificate errors when accessing by IP

**Problem**: Browser shows certificate error when accessing `https://172.16.1.162`

**Solutions**:

1. **This is expected behavior**:
   - Let's Encrypt certificates are issued for domain names, not IP addresses
   - The certificate is for `*.home.lucy31.cloud`, not `172.16.1.162`

2. **Use domain names instead**:
   - Always access services via domain names: `https://media.home.lucy31.cloud`
   - Configure local DNS properly (see Configuration section)

3. **For testing only**:
   - You can click through the certificate warning
   - Or use `curl -k https://172.16.1.162` to bypass certificate validation

### Services work but are slow on LAN

**Problem**: Services are accessible but slower than expected on local network

**Solutions**:

1. **Verify traffic is going over LAN**:
   ```bash
   # On the server
   sudo tcpdump -i enp24s0 port 443
   # Should show traffic when accessing services from LAN
   ```

2. **Check if traffic is going through Tailscale**:
   - If DNS resolves to Tailscale IP, traffic goes through VPN (slower)
   - Fix DNS configuration to resolve to LAN IP

3. **Check network performance**:
   ```bash
   # From a LAN device to server
   iperf3 -c 172.16.1.162
   # Should show near-gigabit speeds on gigabit LAN
   ```

### Wrong network interface

**Problem**: Local access doesn't work after configuration

**Solutions**:

1. **Verify your interface name**:
   ```bash
   ip link
   # Look for the interface connected to your LAN
   ```

2. **Check interface is UP**:
   ```bash
   ip addr show dev enp24s0
   # Should show state UP and have an IP address
   ```

3. **Update `vars.nix` with correct interface**:
   ```nix
   lanInterface = "enp24s0";  # Use your actual interface name
   ```

4. **Rebuild system**:
   ```bash
   sudo nixos-rebuild switch
   ```

## Disabling Local Access

If you want to disable local network access and only use Tailscale:

1. Edit `vars.nix`:
   ```nix
   networking = {
     # ... other settings ...
     enableLocalAccess = false;  # Disable local access
   };
   ```

2. Rebuild system:
   ```bash
   sudo nixos-rebuild switch
   ```

This will:
- Remove LAN interface from firewall trusted interfaces
- Block HTTPS traffic from LAN
- Keep Tailscale access working
- Services will only be accessible via Tailscale VPN

## Best Practices

### For Home Users
- ✅ Enable local access for convenience and performance
- ✅ Use strong WiFi passwords (WPA3 if available)
- ✅ Keep Tailscale access for remote access
- ✅ Configure DNS at router level for all devices

### For Advanced Users
- ✅ Use VLANs to isolate homeserver traffic
- ✅ Set up Pi-hole for network-wide DNS and ad-blocking
- ✅ Enable Authentik SSO for centralized authentication
- ✅ Monitor access logs regularly
- ✅ Use guest WiFi networks for untrusted devices

### For Paranoid Users
- ✅ Disable local access (`enableLocalAccess = false`)
- ✅ Use Tailscale exclusively (even on LAN)
- ✅ Enable Authentik SSO with 2FA
- ✅ Use hardware security keys (YubiKey)
- ✅ Enable CrowdSec for intrusion detection
- ✅ Regular security audits and updates

## Comparison with Path-Based Routing

This configuration uses **domain-based routing** instead of path-based routing:

| Feature | Domain-Based (Current) | Path-Based (Alternative) |
|---------|----------------------|-------------------------|
| **URLs** | `https://media.home.lucy31.cloud` | `https://homeserver.local/jellyfin` |
| **Consistency** | ✅ Same URLs everywhere | ❌ Different URLs per network |
| **Certificates** | ✅ Let's Encrypt (trusted) | ⚠️ Self-signed (warnings) |
| **Service Compatibility** | ✅ All services work | ⚠️ Some need base path config |
| **Mobile Apps** | ✅ Work seamlessly | ❌ May not support paths |
| **Bookmarks** | ✅ Work everywhere | ❌ Need separate bookmarks |
| **Configuration** | ✅ Simple | ⚠️ More complex |

Domain-based routing is recommended for most users.

## Related Documentation

- [Networking Configuration](./SETUP.md#networking)
- [Tailscale Setup](./TAILSCALE.md)
- [Security Configuration](./SETUP.md#security)
- [Service Configuration](./SERVICES.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
