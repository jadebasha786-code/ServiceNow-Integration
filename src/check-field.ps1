# Check Field Creation Status
# Verify if the windsurf_sn field was created and where it exists

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

# Create authentication headers
$Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
$Headers = @{
    "Authorization" = "Basic $Credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$FieldName = $Config.table.field_to_create.name
$TableName = $Config.table.name

Write-Host "Checking field: $FieldName" -ForegroundColor Cyan
Write-Host "Target table: $TableName" -ForegroundColor Cyan

# Check 1: Look for the field in any table
Write-Host "`n=== Check 1: Search for field in all tables ===" -ForegroundColor Yellow
try {
    $Url = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Params = @{
        sysparm_query = "name=$FieldName"
        sysparm_fields = "name,element,label,type,table,active"
    }
    
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -Body $Params
    
    if ($Response.result -and $Response.result.Count -gt 0) {
        Write-Host "✅ Found field '$FieldName' in $($Response.result.Count) location(s):" -ForegroundColor Green
        foreach ($Field in $Response.result) {
            Write-Host "  Table: $($Field.table)" -ForegroundColor Cyan
            Write-Host "  Label: $($Field.label)" -ForegroundColor Cyan
            Write-Host "  Type: $($Field.type)" -ForegroundColor Cyan
            Write-Host "  Active: $($Field.active)" -ForegroundColor Cyan
            Write-Host "  ---" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ Field '$FieldName' not found in any table" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error checking field: $_" -ForegroundColor Red
}

# Check 2: Look for the specific table
Write-Host "`n=== Check 2: Search for table '$TableName' ===" -ForegroundColor Yellow
try {
    $Url = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Params = @{
        sysparm_query = "table=$TableName"
        sysparm_fields = "name,element,label,type,table,active"
        sysparm_limit = 50
    }
    
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -Body $Params
    
    if ($Response.result -and $Response.result.Count -gt 0) {
        Write-Host "✅ Found table '$TableName' with $($Response.result.Count) fields:" -ForegroundColor Green
        foreach ($Field in $Response.result) {
            Write-Host "  $($Field.name) ($($Field.label))" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ Table '$TableName' not found or has no fields" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error checking table: $_" -ForegroundColor Red
}

# Check 3: Try to create the field again with more detailed error handling
Write-Host "`n=== Check 3: Attempt field recreation with detailed logging ===" -ForegroundColor Yellow
try {
    $FieldData = @{
        name = $FieldName
        element = $FieldName
        column_label = $Config.table.field_to_create.column_label
        label = $Config.table.field_to_create.label
        type = $Config.table.field_to_create.type
        max_length = $Config.table.field_to_create.max_length
        mandatory = $Config.table.field_to_create.mandatory
        read_only = $Config.table.field_to_create.read_only
        default_value = $Config.table.field_to_create.default_value
        table = $TableName
        active = $true
    } | ConvertTo-Json -Depth 10

    Write-Host "Field data being sent:" -ForegroundColor Cyan
    Write-Host $FieldData -ForegroundColor White
    
    $CreateUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Response = Invoke-RestMethod -Uri $CreateUrl -Headers $Headers -Method Post -Body $FieldData
    
    Write-Host "✅ Field creation response:" -ForegroundColor Green
    Write-Host ($Response | ConvertTo-Json -Depth 10) -ForegroundColor White
}
catch {
    Write-Host "❌ Field creation failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $ErrorBody = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($ErrorBody)
        $ErrorText = $Reader.ReadToEnd()
        Write-Host "Error Details: $ErrorText" -ForegroundColor Red
    }
}
