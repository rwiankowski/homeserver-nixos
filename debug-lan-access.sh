#!/usr/bin/env bash
#
# Debug script for local network access issues
# Run this on your homeserver to diagnose LAN connectivity problems
#

set -e

echo "=========================================="
echo "Local Network Access Debugging Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get LAN interface from vars.nix
LAN_INTERFACE=$(grep 'lanInterface' /home/rwiankowski/Projects/HomeServer/homeserver-nixos/vars.nix | sed 's/.*"\(.*\)".*/\1/')
ENABLE_LOCAL=$(grep 'enableLocalAccess' /home/rwiankowski/Projects/HomeServer/homeserver-nixos/vars.nix | grep -o 'true\|false')

echo "Configuration:"
echo "  LAN Interface: $LAN_INTERFACE"
echo "  Local Access Enabled: $ENABLE_LOCAL"
echo ""

# 1. Verify interface exists and is UP
echo "=========================================="
echo "1. Checking network interface: $LAN_INTERFACE"
echo "=========================================="
if ip addr show "$LAN_INTERFACE" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Interface $LAN_INTERFACE exists"
    
    # Get IP address
    LAN_IP=$(ip addr show "$LAN_INTERFACE" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    if [ -n "$LAN_IP" ]; then
        echo -e "${GREEN}✓${NC} Interface has IP address: $LAN_IP"
    else
        echo -e "${RED}✗${NC} Interface has no IP address!"
    fi
    
    # Check if interface is UP
    if ip addr show "$LAN_INTERFACE" | grep -q "state UP"; then
        echo -e "${GREEN}✓${NC} Interface is UP"
    else
        echo -e "${RED}✗${NC} Interface is DOWN!"
    fi
else
    echo -e "${RED}✗${NC} Interface $LAN_INTERFACE does not exist!"
    echo "Available interfaces:"
    ip link show | grep -E '^[0-9]+:' | awk '{print "  - " $2}' | sed 's/:$//'
fi
echo ""

# 2. Check firewall rules
echo "=========================================="
echo "2. Checking firewall rules"
echo "=========================================="
if sudo nft list ruleset | grep -q "$LAN_INTERFACE"; then
    echo -e "${GREEN}✓${NC} Firewall rules include $LAN_INTERFACE"
    echo "Relevant rules:"
    sudo nft list ruleset | grep -A 2 -B 2 "$LAN_INTERFACE" | sed 's/^/  /'
else
    echo -e "${RED}✗${NC} No firewall rules found for $LAN_INTERFACE"
    echo "This might mean the configuration hasn't been applied yet."
fi
echo ""

# 3. Check what Caddy is listening on
echo "=========================================="
echo "3. Checking Caddy listening ports"
echo "=========================================="
if systemctl is-active --quiet caddy; then
    echo -e "${GREEN}✓${NC} Caddy service is running"
    
    # Check listening ports
    CADDY_PORTS=$(sudo ss -tlnp | grep caddy || true)
    if [ -n "$CADDY_PORTS" ]; then
        echo "Caddy is listening on:"
        echo "$CADDY_PORTS" | sed 's/^/  /'
        
        # Check if listening on 0.0.0.0:443 or :::443
        if echo "$CADDY_PORTS" | grep -q -E '(0.0.0.0:443|\*:443|:::443)'; then
            echo -e "${GREEN}✓${NC} Caddy is listening on all interfaces (port 443)"
        else
            echo -e "${YELLOW}⚠${NC} Caddy might not be listening on all interfaces"
        fi
        
        if echo "$CADDY_PORTS" | grep -q -E '(0.0.0.0:80|\*:80|:::80)'; then
            echo -e "${GREEN}✓${NC} Caddy is listening on all interfaces (port 80)"
        else
            echo -e "${YELLOW}⚠${NC} Caddy might not be listening on all interfaces (port 80)"
        fi
    else
        echo -e "${RED}✗${NC} Caddy is not listening on any ports!"
    fi
else
    echo -e "${RED}✗${NC} Caddy service is not running!"
    echo "Start it with: sudo systemctl start caddy"
fi
echo ""

# 4. Check Caddy logs for errors
echo "=========================================="
echo "4. Recent Caddy logs (last 20 lines)"
echo "=========================================="
sudo journalctl -u caddy -n 20 --no-pager | sed 's/^/  /'
echo ""

# 5. Test local connectivity
echo "=========================================="
echo "5. Testing local connectivity"
echo "=========================================="

# Test localhost
echo "Testing localhost:443..."
if timeout 2 bash -c "echo > /dev/tcp/localhost/443" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Port 443 is accessible on localhost"
else
    echo -e "${RED}✗${NC} Port 443 is NOT accessible on localhost"
fi

# Test LAN IP if available
if [ -n "$LAN_IP" ]; then
    echo "Testing $LAN_IP:443..."
    if timeout 2 bash -c "echo > /dev/tcp/$LAN_IP/443" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Port 443 is accessible on LAN IP ($LAN_IP)"
    else
        echo -e "${RED}✗${NC} Port 443 is NOT accessible on LAN IP ($LAN_IP)"
    fi
fi
echo ""

# 6. DNS resolution test
echo "=========================================="
echo "6. DNS Resolution Test"
echo "=========================================="
echo "Testing DNS resolution for media.home.lucy31.cloud..."
DNS_RESULT=$(nslookup media.home.lucy31.cloud 2>/dev/null | grep -A 1 "Name:" | tail -1 | awk '{print $2}' || echo "FAILED")
if [ "$DNS_RESULT" != "FAILED" ]; then
    echo "  Resolves to: $DNS_RESULT"
    if [ "$DNS_RESULT" = "$LAN_IP" ]; then
        echo -e "${GREEN}✓${NC} DNS resolves to LAN IP (correct for local access)"
    elif echo "$DNS_RESULT" | grep -q "^100\."; then
        echo -e "${YELLOW}⚠${NC} DNS resolves to Tailscale IP (traffic will go through VPN)"
    else
        echo -e "${YELLOW}⚠${NC} DNS resolves to unexpected IP"
    fi
else
    echo -e "${RED}✗${NC} DNS resolution failed"
fi
echo ""

# 7. Summary and recommendations
echo "=========================================="
echo "7. Summary and Recommendations"
echo "=========================================="
echo ""

if [ "$ENABLE_LOCAL" = "false" ]; then
    echo -e "${YELLOW}⚠${NC} Local access is DISABLED in vars.nix"
    echo "To enable it, set: enableLocalAccess = true"
    echo ""
fi

echo "Next steps to test from another device on your LAN:"
echo ""
echo "1. Test direct IP access (will show certificate warning):"
echo "   curl -k https://$LAN_IP"
echo ""
echo "2. Test domain access (requires local DNS configuration):"
echo "   curl https://media.home.lucy31.cloud"
echo ""
echo "3. If domain access fails, check DNS resolution on that device:"
echo "   nslookup media.home.lucy31.cloud"
echo "   (Should resolve to $LAN_IP)"
echo ""
echo "4. If DNS is wrong, configure your router/Pi-hole to resolve"
echo "   *.home.lucy31.cloud to $LAN_IP"
echo ""
echo "=========================================="
echo "Debug script completed"
echo "=========================================="
