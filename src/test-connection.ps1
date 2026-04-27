# Test ServiceNow Connection PowerShell Script
# Tests connection to ServiceNow instance and verifies table access

param(
    [string]$ConfigPath = "config/servicenow-config.json"
)

# Load configuration
try {
    $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error loading configuration: $_" -ForegroundColor Red
    exit 1
}

# Check if credentials are configured
if (-not $Config.instance.username -or -not $Config.instance.password) {
    Write-Host "Error: Please update the configuration file with your ServiceNow credentials" -ForegroundColor Red
    Write-Host "File: $ConfigPath" -ForegroundColor Yellow
    Write-Host "Add your username and password to the instance section" -ForegroundColor Yellow
    exit 1
}

# Create base64 encoded credentials for basic auth
$Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
$Headers = @{
    "Authorization" = "Basic $Credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

# Test basic connection
Write-Host "Testing basic connection to ServiceNow..." -ForegroundColor Yellow
try {
    $TestUrl = "$($Config.instance.url)/api/now/table/sys_user?sysparm_limit=1"
    $Response = Invoke-RestMethod -Uri $TestUrl -Headers $Headers -Method Get
    Write-Host "✅ Basic connection successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to connect to ServiceNow instance: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    exit 1
}

# Test table access
Write-Host "Testing access to target table..." -ForegroundColor Yellow
$TableName = $Config.table.name
try {
    $TableUrl = "$($Config.instance.url)/api/now/table/$TableName?sysparm_limit=1"
    $TableResponse = Invoke-RestMethod -Uri $TableUrl -Headers $Headers -Method Get
    Write-Host "✅ Table access successful!" -ForegroundColor Green
    Write-Host "Table: $TableName" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to access table: $_" -ForegroundColor Red
    Write-Host "This might mean the table doesn't exist or you don't have permissions" -ForegroundColor Yellow
}

# Check if field already exists
Write-Host "Checking if field already exists..." -ForegroundColor Yellow
$FieldName = $Config.table.field_to_create.name
try {
    $FieldUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $FieldParams = @{
        sysparm_query = "name=$FieldName^table=$TableName"
        sysparm_fields = "name,element,label,type,active"
    }
    
    $FieldResponse = Invoke-RestMethod -Uri $FieldUrl -Headers $Headers -Method Get -Body $FieldParams
    
    if ($FieldResponse.result -and $FieldResponse.result.Count -gt 0) {
        $FieldInfo = $FieldResponse.result[0]
        Write-Host "⚠️  Field '$FieldName' already exists!" -ForegroundColor Yellow
        Write-Host "Field details:" -ForegroundColor Cyan
        Write-Host "  Name: $($FieldInfo.name)" -ForegroundColor Cyan
        Write-Host "  Label: $($FieldInfo.label)" -ForegroundColor Cyan
        Write-Host "  Type: $($FieldInfo.type)" -ForegroundColor Cyan
        Write-Host "  Active: $($FieldInfo.active)" -ForegroundColor Cyan
    }
    else {
        Write-Host "✅ Field '$FieldName' does not exist - ready to create" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Error checking field existence: $_" -ForegroundColor Red
}

Write-Host "`nConnection test completed!" -ForegroundColor Green
Write-Host "If all tests passed, you can run the field creation script:" -ForegroundColor Cyan
Write-Host "powershell -ExecutionPolicy Bypass -File src/servicenow-field-creator.ps1" -ForegroundColor White
