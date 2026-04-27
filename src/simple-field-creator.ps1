# Simple Field Creator - Direct approach
param(
    [string]$ConfigPath = "config/servicenow-config.json"
)

# Load configuration
$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
$Headers = @{
    "Authorization" = "Basic $Credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$FieldName = "windsurf_sn"
$TableName = "x_2022294_incident_ai_table"

Write-Host "Creating field: $FieldName in table: $TableName" -ForegroundColor Yellow

# Check if field already exists
Write-Host "Checking if field exists..." -ForegroundColor Cyan
try {
    $CheckUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $CheckParams = @{
        sysparm_query = "name=$FieldName^table=$TableName"
        sysparm_fields = "name,table,active"
    }
    $CheckResponse = Invoke-RestMethod -Uri $CheckUrl -Headers $Headers -Method Get -Body $CheckParams
    
    if ($CheckResponse.result -and $CheckResponse.result.Count -gt 0) {
        Write-Host "Field already exists!" -ForegroundColor Green
        $CheckResponse.result | Format-Table
        exit
    }
} catch {
    Write-Host "Field does not exist (expected)" -ForegroundColor White
}

# Create the field
Write-Host "Creating new field..." -ForegroundColor Cyan
$FieldData = @{
    name = $FieldName
    element = $FieldName
    column_label = "Windsurf SN"
    label = "Windsurf SN"
    type = "string"
    max_length = 255
    mandatory = $false
    read_only = $false
    table = $TableName
    active = $true
} | ConvertTo-Json

try {
    $CreateUrl = "$($Config.instance.url)/api/now/table/sys_dictionary"
    $CreateResponse = Invoke-RestMethod -Uri $CreateUrl -Headers $Headers -Method Post -Body $FieldData
    
    Write-Host "Field created successfully!" -ForegroundColor Green
    Write-Host "Sys ID: $($CreateResponse.result.sys_id)" -ForegroundColor Cyan
    Write-Host "Name: $($CreateResponse.result.name)" -ForegroundColor Cyan
    Write-Host "Table: $($CreateResponse.result.table)" -ForegroundColor Cyan
    
    # Verify immediately
    Write-Host "Verifying field..." -ForegroundColor Yellow
    $VerifyUrl = "$($Config.instance.url)/api/now/table/sys_dictionary/$($CreateResponse.result.sys_id)"
    $VerifyResponse = Invoke-RestMethod -Uri $VerifyUrl -Headers $Headers -Method Get
    
    if ($VerifyResponse.result) {
        Write-Host "Field verified in database!" -ForegroundColor Green
        Write-Host "Field is active: $($VerifyResponse.result.active)" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "Field creation failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $ErrorBody = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($ErrorBody)
        $ErrorText = $Reader.ReadToEnd()
        Write-Host "Error: $ErrorText" -ForegroundColor Red
    }
}
