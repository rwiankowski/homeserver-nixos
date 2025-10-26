# Azure Setup Guide

This guide covers setting up Azure for:
1. **DNS** - Custom domain with Let's Encrypt certificates
2. **Blob Storage** - Encrypted backups
3. **Service Principal** - Automated certificate management

## Prerequisites

- Azure account (free $200 credit available)
- Azure CLI installed (`brew install azure-cli` or https://aka.ms/installazurecli)
- Domain name registered (can be at any registrar)

---

## Part 1: Azure DNS Setup

### Step 1: Install Azure CLI

```bash
# macOS
brew install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
# Download from: https://aka.ms/installazurecliwindows
```

### Step 2: Login to Azure

```bash
az login
# Opens browser for authentication
```

### Step 3: Create Resource Groups

**IMPORTANT:** This setup uses TWO separate resource groups for better organization:
- One for DNS management
- One for backup storage

```bash
# Set variables (customize these)
LOCATION="westeurope"          # Or your preferred region
RG_DNS="homeserver-dns"        # Resource group for DNS
RG_BACKUPS="homeserver-backups"  # Resource group for backups
DOMAIN="yourdomain.com"        # YOUR domain

# Create DNS resource group
az group create --name $RG_DNS --location $LOCATION

# Create Backups resource group
az group create --name $RG_BACKUPS --location $LOCATION
```

### Step 4: Create DNS Zone

If your domain DNS is not yet in Azure:

```bash
# Create DNS zone in DNS resource group
az network dns zone create \
  --resource-group $RG_DNS \
  --name $DOMAIN

# Show nameservers (you'll need these)
az network dns zone show \
  --resource-group $RG_DNS \
  --name $DOMAIN \
  --query nameServers \
  --output table
```

**Important**: Update your domain registrar to use Azure's nameservers (from above command).

Wait 1-24 hours for DNS propagation.

### Step 5: Create Child Zone (Recommended Approach)

Instead of creating a wildcard CNAME directly on your main domain, create a dedicated child zone for home services. This allows Caddy to create TXT records for Let's Encrypt validation without conflicts.

```bash
# Create child zone for home services
az network dns zone create \
  --resource-group $RG_DNS \
  --name home.$DOMAIN \
  --parent-name $DOMAIN

# Azure automatically creates NS records in parent zone

# Verify child zone exists
az network dns zone show \
  --resource-group $RG_DNS \
  --name home.$DOMAIN
```

### Step 6: Get Your Tailscale Hostname

```bash
# On your server
tailscale status

# Look for line like:
# homeserver    linux   100.x.x.x   homeserver.tail-scale.ts.net

# Save the hostname: homeserver.tail-scale.ts.net
```

### Step 7: Create CNAME Record in Child Zone

```bash
# Set your Tailscale hostname
TAILSCALE_HOSTNAME="homeserver.tail-scale.ts.net"

# Create wildcard CNAME in CHILD zone
az network dns record-set cname create \
  --resource-group $RG_DNS \
  --zone-name home.$DOMAIN \
  --name "*"

az network dns record-set cname set-record \
  --resource-group $RG_DNS \
  --zone-name home.$DOMAIN \
  --record-set-name "*" \
  --cname $TAILSCALE_HOSTNAME

# Verify
az network dns record-set cname show \
  --resource-group $RG_DNS \
  --zone-name home.$DOMAIN \
  --name "*"
```

**Why use a child zone?**
- ✅ Caddy can create TXT records for certificate validation
- ✅ Cleaner separation of home services from main domain
- ✅ No conflicts with existing DNS records
- ✅ Better security and management

### Step 8: Test DNS Resolution

```bash
# Wait a few minutes, then test
dig jellyfin.home.$DOMAIN

# Should show:
# jellyfin.home.yourdomain.com. 3600 IN CNAME homeserver.tail-scale.ts.net.
# homeserver.tail-scale.ts.net. 300 IN A 100.x.x.x
```

---

## Part 2: Service Principal for DNS-01 Challenge

Caddy needs permission to create TXT records in the child zone for Let's Encrypt validation.

### Method 1: Automated Script (Recommended)

```bash
# Get DNS child zone ID
DNS_ZONE_ID=$(az network dns zone show \
  --name home.$DOMAIN \
  --resource-group $RG_DNS \
  --query id \
  --output tsv)

echo "DNS Zone ID: $DNS_ZONE_ID"

# Create service principal with DNS Zone Contributor role
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "caddy-dns-challenge" \
  --role "DNS Zone Contributor" \
  --scopes $DNS_ZONE_ID \
  --query "{tenant_id:tenant, client_id:appId, client_secret:password}" \
  --output json)

# Display credentials
echo $SP_OUTPUT | jq

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Display all credentials you need
echo "=== Save these credentials ==="
echo $SP_OUTPUT | jq
echo "subscription_id: $SUBSCRIPTION_ID"
echo "resource_group: $RG_DNS"
echo "=============================="
```

**Save all 5 values:**
- `tenant_id`
- `client_id`
- `client_secret`
- `subscription_id`
- `resource_group` (use $RG_DNS)

### Step 9: Verify Service Principal Works

```bash
# Test login as service principal
az login --service-principal \
  --username <client_id> \
  --password <client_secret> \
  --tenant <tenant_id>

# Should succeed

# Test permissions - try to list DNS records in CHILD zone
az network dns record-set list \
  --zone-name home.$DOMAIN \
  --resource-group $RG_DNS

# Should list your records (proves read access)

# Test creating TXT record
az network dns record-set txt create \
  --zone-name home.$DOMAIN \
  --resource-group $RG_DNS \
  --name "_acme-challenge.test"

az network dns record-set txt add-record \
  --zone-name home.$DOMAIN \
  --resource-group $RG_DNS \
  --record-set-name "_acme-challenge.test" \
  --value "test-value"

# If successful, you have correct permissions!

# Clean up test record
az network dns record-set txt delete \
  --zone-name home.$DOMAIN \
  --resource-group $RG_DNS \
  --name "_acme-challenge.test" \
  --yes

# Logout from service principal, login as yourself
az logout
az login
```

---

## Part 3: Azure Blob Storage for Backups

### Step 1: Create Storage Account in Backups Resource Group

```bash
# Storage account name (must be globally unique, lowercase, no dashes)
STORAGE_ACCOUNT="homeserverbackup$(date +%s)"  # Adds timestamp for uniqueness

# Create storage account in BACKUPS resource group
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG_BACKUPS \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Cool \
  --https-only true

# Note: Cool tier is cheaper for backups ($0.01/GB vs $0.018/GB for Hot)
```

### Step 2: Create Blob Container

```bash
# Create container
az storage container create \
  --name "restic-backups" \
  --account-name $STORAGE_ACCOUNT \
  --public-access off

# Verify
az storage container show \
  --name "restic-backups" \
  --account-name $STORAGE_ACCOUNT
```

### Step 3: Get Access Keys

```bash
# Get account name and key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RG_BACKUPS \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' \
  --output tsv)

# Display for copying
echo "=== Storage Credentials ==="
echo "account_name: $STORAGE_ACCOUNT"
echo "account_key: $ACCOUNT_KEY"
echo "=========================="
```

### Step 4: Configure Lifecycle Management (Optional but Recommended)

Automatically move old backups to cheaper storage tiers:

```bash
# Create lifecycle policy
cat > lifecycle-policy.json << 'EOF'
{
  "rules": [
    {
      "enabled": true,
      "name": "archive-old-backups",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 180
            },
            "delete": {
              "daysAfterModificationGreaterThan": 730
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["restic-backups/"]
        }
      }
    }
  ]
}
EOF

# Apply policy
az storage account management-policy create \
  --account-name $STORAGE_ACCOUNT \
  --policy @lifecycle-policy.json \
  --resource-group $RG_BACKUPS

# Verify
az storage account management-policy show \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RG_BACKUPS
```

**Lifecycle policy effect:**
- After 30 days: Move to Cool tier (already there, no change)
- After 180 days: Move to Archive tier (very cheap, $0.002/GB)
- After 730 days (2 years): Delete

**Cost savings**: ~80% on 2+ year old backups

---

## Part 4: Add Credentials to Secrets

Now add all the Azure credentials to your secrets file:

```bash
# On your laptop
cd /path/to/nixos-homeserver
sops secrets/secrets.yaml
```

Add Azure section:

```yaml
azure:
  # DNS-01 challenge (from Part 2)
  tenant_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_secret: "your-client-secret-value"
  subscription_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  resource_group: "homeserver-dns"  # Use DNS resource group name

restic:
  # Backups (from Part 3)
  password: "generate-with-openssl-rand-base64-32"
  repository: "azure:restic-backups:/"
  azure_account_name: "homeserverbackup1234567890"
  azure_account_key: "your-long-storage-account-key"
```

Save and exit (automatically encrypts).

---

## Summary of Resource Groups

| Resource Group | Purpose | Resources |
|---------------|---------|-----------|
| `homeserver-dns` | DNS management | • DNS Zone: `yourdomain.com`<br>• Child Zone: `home.yourdomain.com`<br>• Service Principal for Caddy |
| `homeserver-backups` | Backup storage | • Storage Account<br>• Blob Container: `restic-backups`<br>• Lifecycle policies |

---

## Next Steps

Continue with [SETUP.md](SETUP.md) to deploy your configuration.
