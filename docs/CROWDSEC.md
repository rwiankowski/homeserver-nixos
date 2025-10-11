# CrowdSec Setup and Usage Guide

## 🛡️ What CrowdSec Does For You

CrowdSec protects your server by:
- **Analyzing logs** from SSH, Caddy, Docker containers
- **Detecting attacks** (brute force, probing, CVE exploits)
- **Blocking malicious IPs** automatically via firewall
- **Sharing threat intel** with the community (you benefit from attacks seen by others)
- **Providing metrics** for monitoring

## 📋 What's Included

The configuration includes:

### Protection Layers
1. **SSH Brute Force** - Blocks SSH login attacks
2. **Slow SSH Brute Force** - Catches slower, stealthier attacks
3. **HTTP Probing** - Blocks scanning for vulnerabilities
4. **Sensitive Files** - Protects against accessing sensitive files (.env, .git, etc.)
5. **HTTP CVEs** - Blocks known HTTP vulnerability exploits
6. **Port Scanning** - Detects and blocks port scans

### Monitoring
- **Prometheus metrics** at `http://localhost:6060`
- **Grafana dashboard** at `https://grafana.homeserver.local`
- Real-time decision tracking

### Components
- **CrowdSec Engine** - Analyzes logs and makes decisions
- **Firewall Bouncer** - Enforces bans using nftables
- **Collections** - Pre-configured parsers and scenarios

## 🚀 Initial Setup

### Step 1: Add CrowdSec Module

Update your `configuration.nix`:

```nix
imports = [
  # ... other modules ...
  ./modules/crowdsec.nix
];
```

### Step 2: Add Secrets

Add to your `secrets/secrets.yaml`:

```yaml
crowdsec:
  enroll_key: ""  # Leave empty initially

grafana:
  admin_password: "your-secure-grafana-password"
```

Re-encrypt with sops:
```bash
sops secrets/secrets.yaml
```

### Step 3: Deploy

```bash
sudo nixos-rebuild switch --flake .#homeserver
```

### Step 4: Enroll in Console (Recommended)

Enrolling gives you access to the web console and enables community blocklists:

```bash
# Sign up at https://app.crowdsec.net (free)
# You'll get an enrollment key

# Enroll your instance
sudo cscli console enroll <your-enrollment-key>

# Or save it to secrets for automatic enrollment
sops secrets/secrets.yaml
# Add the enrollment key to: crowdsec.enroll_key

# Rebuild to apply
sudo nixos-rebuild switch --flake .#homeserver
```

**Benefits of enrolling:**
- Access to web dashboard showing your alerts
- Community blocklists (IPs seen attacking others)
- Historical analytics
- Multi-instance management

### Step 5: Verify Installation

```bash
# Check CrowdSec status
sudo systemctl status crowdsec
sudo cscli metrics

# Check installed collections
sudo cscli collections list

# Check bouncers
sudo cscli bouncers list

# Check if logs are being parsed
sudo cscli metrics show acquisition
```

## 📊 Using CrowdSec

### Monitoring Decisions

```bash
# View all active bans
sudo cscli decisions list

# View alerts (detections)
sudo cscli alerts list

# View alerts with details
sudo cscli alerts list -o json | jq

# View specific alert
sudo cscli alerts inspect <alert-id>
```

### Managing IPs

```bash
# Manually ban an IP
sudo cscli decisions add --ip 1.2.3.4 --duration 24h --reason "Manual ban"

# Remove a ban
sudo cscli decisions delete --ip 1.2.3.4

# Add IP to whitelist (never ban)
sudo cscli decisions add --ip 192.168.1.100 --type whitelist

# Add Tailscale range to whitelist
sudo cscli decisions add --ip 100.64.0.0/10 --type whitelist --reason "Tailscale"
```

### Viewing Metrics

```bash
# Overall metrics
sudo cscli metrics

# Parser metrics (how many logs processed)
sudo cscli metrics show parsers

# Scenario metrics (what attacks detected)
sudo cscli metrics show scenarios

# Acquisition metrics (log sources)
sudo cscli metrics show acquisition

# Local API metrics
sudo cscli metrics show lapi
```

### Checking What's Protected

```bash
# List all scenarios (attack types detected)
sudo cscli scenarios list

# List all parsers (log formats understood)
sudo cscli parsers list

# Hub update (get latest scenarios)
sudo cscli hub update
sudo cscli hub upgrade
```

## 🎯 Common Use Cases

### Someone is Attacking Your Server

```bash
# View recent alerts
sudo cscli alerts list --limit 10

# See what attacks were detected
sudo cscli metrics show scenarios

# Check active bans
sudo cscli decisions list

# View specific attack details
sudo cscli alerts inspect <alert-id>
```

### False Positive (Legitimate User Blocked)

```bash
# Remove the ban immediately
sudo cscli decisions delete --ip <ip-address>

# Add to whitelist permanently
sudo cscli decisions add --ip <ip-address> --type whitelist --reason "Legitimate user"

# Check what triggered the ban
sudo cscli alerts list --ip <ip-address>
```

### Testing Your Protection

```bash
# From another machine, try SSH brute force
# This will trigger after 5 failed attempts in 2 minutes

# Watch CrowdSec detect it
sudo tail -f /var/log/crowdsec/crowdsec.log

# Or watch metrics live
watch -n 1 'sudo cscli metrics'

# Then check if IP was banned
sudo cscli decisions list
```

### Monitoring via Grafana

1. Access Grafana at `https://grafana.homeserver.local`
2. Login with `admin` and password from secrets
3. Import CrowdSec dashboard:
   - Go to Dashboards → Import
   - Dashboard ID: `14524` (Official CrowdSec dashboard)
   - Select Prometheus datasource
4. View real-time metrics and attack patterns

### Viewing Community Blocklists

```bash
# Check if you're enrolled
sudo cscli console status

# View community blocklists you're using
sudo cscli capi status

# Manual pull of community IPs (automatic every hour)
sudo cscli capi pull
```

## 🔧 Configuration Tuning

### Adjust Ban Duration

Edit `/etc/crowdsec/profiles.yaml`:

```yaml
# Extend SSH brute force ban
name: ssh_bruteforce_long
filters:
  - Alert.Remediation == true && Alert.GetScenario() contains "ssh-bf"
decisions:
  - type: ban
    duration: 24h  # Change from 4h to 24h
```

Then reload:
```bash
sudo systemctl reload crowdsec
```

### Add Custom Scenario

Example: Ban after 3 failed Jellyfin logins

```bash
# Create custom scenario
sudo cscli scenarios install crowdsecurity/http-bad-user-agent

# Or create your own in /etc/crowdsec/scenarios/
```

### Whitelist Your IPs

```bash
# Your home IP
sudo cscli decisions add --ip <your-home-ip> --type whitelist

# Your Tailscale network
sudo cscli decisions add --ip 100.64.0.0/10 --type whitelist

# Local network
sudo cscli decisions add --ip 192.168.0.0/16 --type whitelist
```

### Configure Notifications

Edit `/etc/crowdsec/notifications/http.yaml` to send alerts to:
- Discord webhook
- Slack webhook  
- Custom HTTP endpoint
- Email (via webhook service)

Example Discord notification:

```yaml
type: http
name: discord_notifications
log_level: info

format: |
  {
    "username": "CrowdSec",
    "content": "🚨 **Attack Detected**",
    "embeds": [{
      "title": "{{range . }}{{.Scenario}}{{end}}",
      "description": "{{range . }}IP: {{.Source.IP}}\nCountry: {{.Source.Cn}}\nAS: {{.Source.AsName}}{{end}}",
      "color": 15158332
    }]
  }

url: https://discord.com/api/webhooks/YOUR/WEBHOOK/URL
method: POST
headers:
  Content-Type: application/json
```

Then reload CrowdSec to apply.

## 📈 Performance Impact

CrowdSec is lightweight:
- **CPU**: ~1-2% on average
- **RAM**: ~50-100MB
- **Disk**: Minimal (log parsing is efficient)

The firewall bouncer adds negligible overhead as it uses nftables sets.

## 🐛 Troubleshooting

### CrowdSec Not Starting

```bash
# Check service status
sudo systemctl status crowdsec

# View logs
sudo journalctl -u crowdsec -n 100

# Validate configuration
sudo cscli config validate

# Test connection to LAPI
sudo cscli lapi status
```

### No Alerts Being Generated

```bash
# Check if logs are being read
sudo cscli metrics show acquisition

# Verify log files exist
ls -la /var/log/auth.log
sudo journalctl -u sshd | head

# Test log parsing manually
echo 'Jan 1 12:00:00 host sshd[123]: Failed password for invalid user test from 1.2.3.4' | \
  sudo cscli parsers test -e syslog -t sshlog
```

### Bouncer Not Blocking

```bash
# Check bouncer status
sudo systemctl status crowdsec-firewall-bouncer

# Verify bouncer is registered
sudo cscli bouncers list

# Check nftables rules
sudo nft list tables
sudo nft list table inet crowdsec

# Manually test blocking
sudo cscli decisions add --ip 1.2.3.4 --duration 1h
# Then check if nftables rule was created
sudo nft list table inet crowdsec
```

### High Memory Usage

```bash
# Check database size
du -h /var/lib/crowdsec/data/crowdsec.db

# Clean old decisions
sudo cscli decisions delete --all

# Reduce decision retention in config
# Edit /etc/crowdsec/config.yaml
db_config:
  flush:
    max_age: "3d"  # Reduce from 7d
```

### Prometheus Metrics Not Available

```bash
# Check if Prometheus is running
sudo systemctl status prometheus

# Test CrowdSec metrics endpoint
curl http://localhost:6060/metrics

# Check Prometheus config
sudo cat /etc/prometheus/prometheus.yml
```

## 📚 Understanding the Dashboard

When you access Grafana's CrowdSec dashboard, you'll see:

1. **Overview**: Total alerts, decisions, top attackers
2. **Scenarios**: Which attacks are most common
3. **Geographic Map**: Where attacks originate
4. **Timeline**: Attack patterns over time
5. **Top IPs**: Most aggressive attackers
6. **Parsers**: Log parsing efficiency
7. **Bouncers**: Firewall enforcement status

## 🎓 Learning More

### View Attack Patterns

```bash
# What attacks are happening?
sudo cscli metrics show scenarios

# Who's attacking?
sudo cscli alerts list -o json | jq -r '.[].source.ip' | sort | uniq -c | sort -rn

# Geographic distribution
sudo cscli alerts list -o json | jq -r '.[].source.cn' | sort | uniq -c | sort -rn
```

### Simulate Attacks (Testing)

```bash
# SSH brute force (from another machine)
for i in {1..10}; do ssh fake-user@<your-server>; done

# Then check CrowdSec response
sudo cscli alerts list --limit 1
sudo cscli decisions list
```

## 🔐 Best Practices

1. **Whitelist your IPs** before testing
2. **Monitor the console** for first few days to tune false positives
3. **Enable enrollment** to benefit from community blocklists
4. **Set up notifications** for Discord/Slack to stay informed
5. **Review metrics weekly** to understand attack patterns
6. **Keep collections updated**: `sudo cscli hub update && sudo cscli hub upgrade`
7. **Backup decisions** if you've created custom whitelists

## 📖 Resources

- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [Hub Browser](https://hub.crowdsec.net/) - Explore scenarios and parsers
- [Console](https://app.crowdsec.net/) - Web dashboard
- [Community Discord](https://discord.gg/crowdsec)

## 🎯 Quick Reference

```bash
# Daily checks
sudo cscli metrics                    # Overall stats
sudo cscli alerts list --limit 10     # Recent alerts
sudo cscli decisions list             # Active bans

# Weekly maintenance
sudo cscli hub update                 # Update scenario definitions
sudo cscli hub upgrade                # Upgrade installed items

# When needed
sudo cscli decisions add --ip X --type whitelist  # Whitelist IP
sudo cscli decisions delete --ip X                 # Unban IP
sudo cscli alerts inspect <id>                     # Investigate alert
```

---

With CrowdSec running, your server is now part of a global security community, benefiting from crowd-sourced threat intelligence while contributing to protecting others! 🛡️
