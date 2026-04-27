# Admin Field Check - Comprehensive Field Investigation
# For users with admin permissions to investigate field creation issues

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

Write-Host "=== Admin Field Investigation ===" -ForegroundColor Yellow
Write-Host "Field: $FieldName" -ForegroundColor Cyan
Write-Host "Table: $TableName" -ForegroundColor Cyan

# Check 1: Look for any recently created fields with similar names
Write-Host "`n=== Check 1: Recently created fields ===" -ForegroundColor Yellow
try {
    $Url = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Params = @{
        sysparm_query = "sys_created_onONToday@javascript:gs.beginningOfToday()@javascript:gs.endOfToday()"
        sysparm_fields = "name,element,label,type,table,sys_created_on,sys_created_by"
        sysparm_order_by = "sys_created_on"
        sysparm_limit = 20
    }
    
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -Body $Params
    
    if ($Response.result -and $Response.result.Count -gt 0) {
        Write-Host "📋 Recently created fields today:" -ForegroundColor Green
        foreach ($Field in $Response.result) {
            $CreatedTime = [DateTime]$Field.sys_created_on
            Write-Host "  $($Field.table).$($Field.name) - Created: $($CreatedTime.ToString('HH:mm:ss')) by $($Field.sys_created_by)" -ForegroundColor Cyan
            if ($Field.name -like "*windsurf*" -or $Field.label -like "*windsurf*") {
                Write-Host "    ⭐ WINDSURF RELATED FIELD FOUND!" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "No fields created today found" -ForegroundColor White
    }
}
catch {
    Write-Host "Error checking recent fields: $_" -ForegroundColor Red
}

# Check 2: Search for fields with 'windsurf' in any part of the name
Write-Host "`n=== Check 2: Search for any 'windsurf' fields ===" -ForegroundColor Yellow
try {
    $Url = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Params = @{
        sysparm_query = "nameLIKEwindsurf^ORlabelLIKEwindsurf^ORcolumn_labelLIKEwindsurf"
        sysparm_fields = "name,element,label,type,table,active,sys_created_on"
    }
    
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -Body $Params
    
    if ($Response.result -and $Response.result.Count -gt 0) {
        Write-Host "🔍 Found $($Response.result.Count) fields with 'windsurf':" -ForegroundColor Green
        foreach ($Field in $Response.result) {
            Write-Host "  Table: $($Field.table)" -ForegroundColor Cyan
            Write-Host "  Name: $($Field.name)" -ForegroundColor Cyan
            Write-Host "  Label: $($Field.label)" -ForegroundColor Cyan
            Write-Host "  Active: $($Field.active)" -ForegroundColor Cyan
            Write-Host "  Created: $($Field.sys_created_on)" -ForegroundColor Cyan
            Write-Host "  ---" -ForegroundColor Gray
        }
    } else {
        Write-Host "No fields with 'windsurf' found" -ForegroundColor White
    }
}
catch {
    Write-Host "Error searching windsurf fields: $_" -ForegroundColor Red
}

# Check 3: Get all fields in the target table to see structure
Write-Host "`n=== Check 3: All fields in target table ===" -ForegroundColor Yellow
try {
    $Url = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Params = @{
        sysparm_query = "table=$TableName"
        sysparm_fields = "name,element,label,type,active"
        sysparm_order_by = "name"
        sysparm_limit = 100
    }
    
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get -Body $Params
    
    if ($Response.result -and $Response.result.Count -gt 0) {
        Write-Host "📊 Found $($Response.result.Count) fields in table ${TableName}:" -ForegroundColor Green
        foreach ($Field in $Response.result) {
            $Status = if ($Field.active) { "✅" } else { "❌" }
            Write-Host "  $Status $($Field.name) ($($Field.label)) - Type: $($Field.type)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "No fields found in table $TableName" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error getting table fields: $_" -ForegroundColor Red
}

# Check 4: Try to create field with different approach
Write-Host "`n=== Check 4: Attempt field creation with admin verification ===" -ForegroundColor Yellow
try {
    $FieldData = @{
        name = $FieldName
        element = $FieldName
        column_label = "Windsurf SN"
        label = "Windsurf SN"
        type = "string"
        max_length = 255
        mandatory = $false
        read_only = $false
        default_value = ""
        table = $TableName
        active = $true
    } | ConvertTo-Json -Depth 10

    Write-Host "Creating field with admin permissions..." -ForegroundColor Cyan
    
    $CreateUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $Response = Invoke-RestMethod -Uri $CreateUrl -Headers $Headers -Method Post -Body $FieldData
    
    if ($Response.result) {
        Write-Host "✅ Field created successfully!" -ForegroundColor Green
        Write-Host "Sys ID: $($Response.result.sys_id)" -ForegroundColor Cyan
        Write-Host "Name: $($Response.result.name)" -ForegroundColor Cyan
        Write-Host "Table: $($Response.result.table)" -ForegroundColor Cyan
        
        # Immediately verify the field
        Write-Host "`n🔍 Verifying field creation..." -ForegroundColor Yellow
        $VerifyUrl = "$($Config.instance.url)/api/now/table/sys_dictionary/$($Response.result.sys_id)"
        $VerifyResponse = Invoke-RestMethod -Uri $VerifyUrl -Headers $Headers -Method Get
        
        if ($VerifyResponse.result) {
            Write-Host "✅ Field verified in database!" -ForegroundColor Green
            Write-Host "Field details:" -ForegroundColor Cyan
            Write-Host ($VerifyResponse.result | ConvertTo-Json -Depth 5) -ForegroundColor White
        }
    }
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

Write-Host "`n=== Manual Verification Steps ===" -ForegroundColor Yellow
Write-Host "1. Go to ServiceNow UI: System Definition > Dictionary" -ForegroundColor White
Write-Host "2. Filter by Table: $TableName" -ForegroundColor White
Write-Host "3. Look for field: $FieldName" -ForegroundColor White
Write-Host "4. If found, check if it's active and visible" -ForegroundColor White
Write-Host "5. Check Form Configuration to add field to layout" -ForegroundColor White
