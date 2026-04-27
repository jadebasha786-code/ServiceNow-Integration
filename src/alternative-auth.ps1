# Alternative Authentication Methods
# Try different approaches to authenticate with ServiceNow

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

# Method 1: Standard Basic Auth
Write-Host "`n=== Method 1: Standard Basic Authentication ===" -ForegroundColor Yellow
try {
    $Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
    $Headers = @{
        "Authorization" = "Basic $Credentials"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    
    $Url = "$($Config.instance.url)/api/now/table/sys_user?sysparm_limit=1"
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get
    Write-Host "✅ Standard Basic Auth successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Standard Basic Auth failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 2: Try with different user agent
Write-Host "`n=== Method 2: Basic Auth with Custom User-Agent ===" -ForegroundColor Yellow
try {
    $Credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.instance.username):$($Config.instance.password)"))
    $Headers = @{
        "Authorization" = "Basic $Credentials"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
        "User-Agent" = "ServiceNow-Integration/1.0"
    }
    
    $Url = "$($Config.instance.url)/api/now/table/sys_user?sysparm_limit=1"
    $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get
    Write-Host "✅ Custom User-Agent successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Custom User-Agent failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 3: Try with session-based authentication
Write-Host "`n=== Method 3: Session-based Authentication ===" -ForegroundColor Yellow
try {
    # First try to get a session
    $SessionBody = @{
        "user_name" = $Config.instance.username
        "user_password" = $Config.instance.password
    } | ConvertTo-Json
    
    $LoginUrl = "$($Config.instance.url)/api/now/table/login"
    $LoginResponse = Invoke-RestMethod -Uri $LoginUrl -Method Post -Body $SessionBody -ContentType "application/json"
    Write-Host "✅ Session-based auth successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Session-based auth failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 4: Check if we can access the web interface
Write-Host "`n=== Method 4: Web Interface Check ===" -ForegroundColor Yellow
try {
    $WebUrl = "$($Config.instance.url)/login.do"
    $WebResponse = Invoke-WebRequest -Uri $WebUrl -Method Get
    if ($WebResponse.StatusCode -eq 200) {
        Write-Host "✅ Web interface accessible" -ForegroundColor Green
        Write-Host "Try logging in manually at: $($Config.instance.url)" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "❌ Web interface check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Manual Steps Required ===" -ForegroundColor Yellow
Write-Host "1. Try logging into ServiceNow manually at: $($Config.instance.url)" -ForegroundColor White
Write-Host "2. Check if your account has 'rest_service' role" -ForegroundColor White
Write-Host "3. Verify if two-factor authentication is enabled" -ForegroundColor White
Write-Host "4. Check if API access is enabled for your account" -ForegroundColor White
Write-Host "5. Contact your ServiceNow admin if issues persist" -ForegroundColor White
