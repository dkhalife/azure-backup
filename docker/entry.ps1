$envVars = @(
    "AZURE_TENANT_ID",
    "AZURE_SUBSCRIPTION_ID",
    "AZURE_RESOURCE_GROUP",
    "AZURE_APP_ID",
    "AZURE_SPN_CERT_PATH",
    "AZURE_IP_ADDRESS_NAME",
    "AZURE_VM_NAME",
    "SSH_USER",
    "SSH_KEY"
)

foreach ($var in $envVars) {
    if (-not $env:$var) {
        throw "Environment variable $var must be set."
    }
}

$tenantId = $env:AZURE_TENANT_ID
$subscriptionId = $env:AZURE_SUBSCRIPTION_ID
$resourceGroup = $env:AZURE_RESOURCE_GROUP

$appId = $env:AZURE_APP_ID
$spnCert = $env:AZURE_SPN_CERT_PATH

if (-not (Test-Path $spnCert)) {
    throw "SPN certificate file $spnCert does not exist."
}

$ipAddressName = $env:AZURE_IP_ADDRESS_NAME
$vmName = $env:AZURE_VM_NAME

$sshUser = $env:SSH_USER
$sshKey = $env:SSH_KEY

$ErrorActionPreference = "Stop"

Write-Host "Connecting to Azure"
az login --service-principal --username $appId --tenant $tenantId --certificate $spnCert > $null

Write-Host "Selecting subscription"
az account set --subscription $subscriptionId > $null

Write-Host "Looking up backup agent"
$ipAddress = $(az network public-ip show --resource-group $resourceGroup --name $ipAddressName --query "ipAddress" --output tsv)

Write-Host "IP address: $ipAddress"

Write-Host "Spawning agent"
az vm start --resource-group $resourceGroup --name $vmName > $null

$maxRetries = 5
$retryCount = 0
Write-Host "Waiting for SSH to become available"
while ($retryCount -lt $maxRetries) {
    try {
        Start-Sleep -Seconds 10
        ssh -i ${sshKey} -o StrictHostKeyChecking=no ${sshUser}@${ipAddress} "echo 'Connection successful'"
        if ($LASTEXITCODE -ne 0) {
            throw "SSH connection failed with exit code $LASTEXITCODE"
        }
        break
    } catch {
        ++$retryCount
        $sleepSeconds = [math]::Pow(2, $retryCount)

        Write-Host "SSH connection failed. Retrying in $sleepSeconds seconds..."
        Start-Sleep -Seconds $sleepSeconds
    }
}

if ($retryCount -eq $maxRetries) {
    throw "SSH connection failed after $maxRetries attempts."
}

$retryCount = 0

Write-Host "Starting backup"
while ($retryCount -lt $maxRetries) {
    try {
        rsync -aqz --stats -e "ssh -i ${sshKey} -o StrictHostKeyChecking=no" /backup/ "${sshUser}@${ipAddress}:/backup/"
        if ($LASTEXITCODE -ne 0) {
            throw "rsync failed with exit code $LASTEXITCODE"
        }
        break
    } catch {
        ++$retryCount
        $sleepSeconds = [math]::Pow(2, $retryCount)

        Write-Host "Backup failed. Retrying in $sleepSeconds seconds..."
        Start-Sleep -Seconds $sleepSeconds
    }
}

if ($retryCount -eq $maxRetries) {
    throw "Backup failed after $maxRetries attempts."
}

Write-Host "Deallocating agent"
az vm deallocate --resource-group $resourceGroup --name $vmName > $null
