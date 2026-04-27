# Debug Authentication Script
# Helps troubleshoot ServiceNow authentication issues

param(
    [string]$ConfigPath = "config/servicenow-config.json"
)

# Load configuration
try {
    $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
    Write-Host "Instance URL: $($Config.instance.url)" -ForegroundColor Cyan
    Write-Host "Username: $($Config.instance.username)" -ForegroundColor Cyan
}
catch {
    Write-Host "Error loading configuration: $_" -ForegroundColor Red
    exit 1
}

# Create base64 encoded credentials
$Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
$Headers = @{
    "Authorization" = "Basic $Credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Write-Host "`nTesting authentication..." -ForegroundColor Yellow

# Test with different endpoints
$Endpoints = @(
    "/api/now/table/sys_user?sysparm_limit=1",
    "/api/now/v2/table/sys_user?sysparm_limit=1",
    "/api/now/table/sys_dictionary?sysparm_query=name=windsurf_sn^table=x_2022294_incident_ai_table"
)

foreach ($Endpoint in $Endpoints) {
    Write-Host "`nTesting endpoint: $Endpoint" -ForegroundColor Yellow
    try {
        $Url = "$($Config.instance.url)$Endpoint"
        $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get
        Write-Host "✅ Success! Response received" -ForegroundColor Green
        if ($Response.result) {
            Write-Host "Records found: $($Response.result.Count)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "❌ Failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            $ErrorBody = $_.Exception.Response.GetResponseStream()
            $Reader = New-Object System.IO.StreamReader($ErrorBody)
            $ErrorText = $Reader.ReadToEnd()
            Write-Host "Error Details: $ErrorText" -ForegroundColor Red
        }
    }
}

Write-Host "`nTroubleshooting Tips:" -ForegroundColor Yellow
Write-Host "1. Verify username and password are correct" -ForegroundColor White
Write-Host "2. Ensure user has 'rest_service' role in ServiceNow" -ForegroundColor White
Write-Host "3. Check if two-factor authentication is enabled" -ForegroundColor White
Write-Host "4. Verify the instance URL is correct" -ForegroundColor White
Write-Host "5. Try logging into ServiceNow web interface first" -ForegroundColor White
