# ServiceNow Field Creator PowerShell Script
# Creates the windsurf_sn field in the x_2022294_incident_ai_table

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
    exit 1
}

# Create base64 encoded credentials for basic auth
$Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
$Headers = @{
    "Authorization" = "Basic $Credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

# Test connection to ServiceNow
Write-Host "Testing connection to ServiceNow..." -ForegroundColor Yellow
try {
    $TestUrl = "$($Config.instance.url)/api/now/table/sys_user?sysparm_limit=1"
    $Response = Invoke-RestMethod -Uri $TestUrl -Headers $Headers -Method Get
    Write-Host "Connection successful!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to ServiceNow instance: $_" -ForegroundColor Red
    exit 1
}

# Prepare field data
$FieldConfig = $Config.table.field_to_create
$TableName = $Config.table.name

$FieldData = @{
    name = $FieldConfig.name
    element = $FieldConfig.name
    column_label = $FieldConfig.column_label
    label = $FieldConfig.label
    type = $FieldConfig.type
    max_length = $FieldConfig.max_length
    mandatory = $FieldConfig.mandatory
    read_only = $FieldConfig.read_only
    default_value = $FieldConfig.default_value
    table = $TableName
    active = $true
} | ConvertTo-Json

# Create the field
Write-Host "Creating field '$($FieldConfig.name)'..." -ForegroundColor Yellow
try {
    $CreateUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Response = Invoke-RestMethod -Uri $CreateUrl -Headers $Headers -Method Post -Body $FieldData
    
    Write-Host "Field '$($FieldConfig.name)' created successfully!" -ForegroundColor Green
    Write-Host "Field Sys ID: $($Response.result.sys_id)" -ForegroundColor Cyan
}
catch {
    Write-Host "Error creating field: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $ErrorBody = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($ErrorBody)
        $ErrorText = $Reader.ReadToEnd()
        Write-Host "Response: $ErrorText" -ForegroundColor Red
    }
    exit 1
}

# Verify the field was created
Write-Host "Verifying field creation..." -ForegroundColor Yellow
try {
    $VerifyUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $VerifyParams = @{
        sysparm_query = "name=$($FieldConfig.name)^table=$TableName"
        sysparm_fields = "name,element,label,type,active"
    }
    
    $VerifyResponse = Invoke-RestMethod -Uri $VerifyUrl -Headers $Headers -Method Get -Body $VerifyParams
    
    if ($VerifyResponse.result -and $VerifyResponse.result.Count -gt 0) {
        $FieldInfo = $VerifyResponse.result[0]
        Write-Host "Field verification successful:" -ForegroundColor Green
        Write-Host "  Name: $($FieldInfo.name)" -ForegroundColor Cyan
        Write-Host "  Label: $($FieldInfo.label)" -ForegroundColor Cyan
        Write-Host "  Type: $($FieldInfo.type)" -ForegroundColor Cyan
        Write-Host "  Active: $($FieldInfo.active)" -ForegroundColor Cyan
        Write-Host "`n✅ Field created and verified successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "Field not found in table" -ForegroundColor Red
        Write-Host "⚠️  Field creation may have failed - verification failed" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Verification error: $_" -ForegroundColor Red
    Write-Host "⚠️  Could not verify field creation" -ForegroundColor Yellow
}

Write-Host "`nScript completed. You can now check the ServiceNow instance to confirm the field appears in the table." -ForegroundColor Cyan
