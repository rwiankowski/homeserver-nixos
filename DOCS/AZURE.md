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

### Step 3: Create Resource Group

```bash
# Set variables (customize these)
LOCATION="westeurope"          # Or your preferred region
RG_NAME="homeserver-resources"
DOMAIN="yourdomain.com"        # YOUR domain

# Create resource group
az group create --name $RG_NAME --location $LOCATION
```

### Step 4: Create DNS Zone

If your domain DNS is not yet in Azure:

```bash
# Create DNS zone
az network dns zone create \
  --resource-group $RG_NAME \
  --name $DOMAIN

# Show nameservers (you'll need these)
az network dns zone show \
  --resource-group $RG_NAME \
  --name $DOMAIN \
  --query nameServers \
  --output table
```

**Important**: Update your domain registrar to use Azure's nameservers (from above command).

Wait 1-24 hours for DNS propagation.

### Step 5: Get Your Tailscale Hostname

```bash
# On your server
tailscale status

# Look for line like:
# homeserver    linux   100.x.x.x   homeserver.tail-scale.ts.net

# Save the hostname: homeserver.tail-scale.ts.net
```

### Step 6: Create CNAME Record

```bash
# Set your Tailscale hostname
TAILSCALE_HOSTNAME="homeserver.tail-scale.ts.net"

# Create wildcard CNAME
az network dns record-set cname create \
  --resource-group $RG_NAME \
  --zone-name $DOMAIN \
  --name "*.home"

az network dns record-set cname set-record \
  --resource-group $RG_NAME \
  --zone-name $DOMAIN \
  --record-set-name "*.home" \
  --cname $TAILSCALE_HOSTNAME

# Verify
az network dns record-set cname show \
  --resource-group $RG_NAME \
  --zone-name $DOMAIN \
  --name "*.home"
```

### Step 7: Test DNS Resolution

```bash
# Wait a few minutes, then test
dig jellyfin.home.$DOMAIN

# Should show CNAME to your Tailscale hostname
```

---

## Part 2: Service Principal for DNS-01 Challenge

Caddy needs permission to create TXT records for Let's Encrypt validation.

### Method 1: Automated Script (Recommended)

```bash
# Get DNS zone ID
DNS_ZONE_ID=$(az network dns zone show \
  --name $DOMAIN \
  --resource-group $RG_NAME \
  --query id \
  --output tsv)

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
echo "resource_group: $RG_NAME"
echo "=============================="
```

**Save all 5 values:**
- `tenant_id`
- `client_id`
- `client_secret`
- `subscription_id`
- `resource_group`

### Method 2: Azure Portal (If You Prefer UI)

<details>
<summary>Click to expand Azure Portal instructions</summary>

1. **Create App Registration:**
   - Azure Portal → Azure Active Directory
   - App registrations → + New registration
   - Name: `caddy-dns-challenge`
   - Supported account types: Single tenant
   - Register
   - **Copy Application (client) ID**
   - **Copy Directory (tenant) ID**

2. **Create Client Secret:**
   - In the app → Certificates & secrets
   - + New client secret
   - Description: `caddy-dns`
   - Expires: 24 months
   - Add
   - **Copy the secret VALUE** (you won't see it again!)

3. **Grant DNS Permissions:**
   - Navigate to your DNS Zone
   - Access control (IAM)
   - + Add → Add role assignment
   - Role: **DNS Zone Contributor**
   - Members: Select `caddy-dns-challenge`
   - Review + assign

4. **Get Additional Info:**
   - Subscription ID: Portal → Subscriptions → Copy ID
   - Resource Group: DNS Zone → Overview → Resource group name

</details>

### Step 8: Verify Service Principal Works

```bash
# Test login as service principal
az login --service-principal \
  --username <client_id> \
  --password <client_secret> \
  --tenant <tenant_id>

# Should succeed

# Test permissions - try to list DNS records
az network dns record-set list \
  --zone-name $DOMAIN \
  --resource-group $RG_NAME

# Should list your records (proves read access)

# Test creating TXT record
az network dns record-set txt create \
  --zone-name $DOMAIN \
  --resource-group $RG_NAME \
  --name "_acme-challenge.test"

az network dns record-set txt add-record \
  --zone-name $DOMAIN \
  --resource-group $RG_NAME \
  --record-set-name "_acme-challenge.test" \
  --value "test-value"

# If successful, you have correct permissions!

# Clean up test record
az network dns record-set txt delete \
  --zone-name $DOMAIN \
  --resource-group $RG_NAME \
  --name "_acme-challenge.test" \
  --yes

# Logout from service principal, login as yourself
az logout
az login
```

---

## Part 3: Azure Blob Storage for Backups

### Step 1: Create Storage Account

```bash
# Storage account name (must be globally unique, lowercase, no dashes)
STORAGE_ACCOUNT="homeserverbackup$(date +%s)"  # Adds timestamp for uniqueness

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG_NAME \
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
  --resource-group $RG_NAME \
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
  --resource-group $RG_NAME

# Verify
az storage account management-policy show \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RG_NAME
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
  resource_group: "homeserver-resources"

restic:
  # Backups (from Part 3)
  password: "generate-with-openssl-rand-base64-32"
  repository: "azure:restic-backups:/"
  azure_account_name: "homeserverbackup1234567890"
  azure_account_key: "your-long-storage-account-key"
```

Save and exit (automatically encrypts).

---

## Part 5: Deploy and Test

### Deploy Configuration

```bash
# Commit changes
git add secrets/secrets.yaml
git commit -m "Add Azure credentials"
git push

# On server
cd /etc/nixos
git pull
sudo nixos-rebuild switch --flake .#homeserver
```

### Test DNS-01 Challenge

```bash
# Wait 2-3 minutes for Caddy to request certificates

# Check certificates obtained
sudo caddy list-certificates

# Should show certificates for:
# - jellyfin.home.yourdomain.com
# - immich.home.yourdomain.com
# - etc.
```

### Test Backups

```bash
# On server

# Run manual backup
sudo systemctl start restic-backups-homeserver

# Check status
sudo systemctl status restic-backups-homeserver

# View logs
journalctl -u restic-backups-homeserver -f

# Verify in Azure
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name "restic-backups" \
  --output table
```

---

## Cost Estimation

### DNS Costs

- **DNS Zone**: $0.50/month
- **Queries**: First 1 billion free, then $0.40/million
- **TXT record operations**: ~500/month (negligible)

**Total**: ~$0.50/month

### Backup Storage Costs

Assuming ~200GB backed up:

- **Cool tier**: $0.01/GB/month = $2.00/month
- **Archive tier** (after 6 months): $0.002/GB/month = $0.40/month
- **Operations**: < $0.10/month

**Total**: ~$2-3/month initially, less over time

### Total Azure Costs

**~$2.50-3.50/month** for DNS + Backups

Compare to:
- Dropbox 2TB: $11.99/month
- Google One 200GB: $2.99/month (but no encryption, no privacy)

---

## Monitoring Costs

### View Current Costs

```bash
# Show costs for resource group
az consumption usage list \
  --query "[?contains(instanceName, 'homeserver')]" \
  --output table
```

### Set Budget Alert

```bash
# Create budget alert at $5/month
az consumption budget create \
  --budget-name "homeserver-budget" \
  --resource-group $RG_NAME \
  --amount 5 \
  --time-grain Monthly \
  --time-period start=2025-01-01 \
  --category Cost
```

---

## Troubleshooting

### DNS Not Resolving

```bash
# Check zone exists
az network dns zone show --name $DOMAIN --resource-group $RG_NAME

# Check CNAME record
az network dns record-set cname show \
  --zone-name $DOMAIN \
  --resource-group $RG_NAME \
  --name "*.home"

# Test from outside
dig @8.8.8.8 jellyfin.home.$DOMAIN
```

### Service Principal Authentication Failed

```bash
# Verify credentials
az login --service-principal \
  -u <client_id> \
  -p <client_secret> \
  --tenant <tenant_id>

# Check role assignment
az role assignment list \
  --assignee <client_id> \
  --all
```

### Backup Failing

```bash
# Check storage account accessible
az storage account show \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG_NAME

# Test upload
echo "test" | az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name "restic-backups" \
  --name "test.txt" \
  --data "test"

# Delete test
az storage blob delete \
  --account-name $STORAGE_ACCOUNT \
  --container-name "restic-backups" \
  --name "test.txt"
```

---

## Cleanup (If Needed)

To remove everything:

```bash
# Delete entire resource group (careful!)
az group delete --name $RG_NAME --yes --no-wait

# Or delete individual resources
az storage account delete --name $STORAGE_ACCOUNT --resource-group $RG_NAME --yes
az network dns zone delete --name $DOMAIN --resource-group $RG_NAME --yes
az ad sp delete --id <client_id>
```

---

## Summary

You've now configured:
- ✅ DNS zone with wildcard CNAME
- ✅ Service principal for automated certificate management
- ✅ Blob storage for encrypted backups
- ✅ Lifecycle policies for cost optimization
- ✅ All credentials added to secrets

**Monthly cost**: ~$2.50-3.50

**Next**: Continue with [SETUP.md](SETUP.md) to deploy your configuration.
