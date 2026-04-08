param(
    [Parameter(Mandatory = $true)]
    [string]$SetupContextJson
)

$errorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if ([string]::IsNullOrWhiteSpace($SetupContextJson)) {
    throw "ZST_SETUP_CONTEXT secret is empty. Add it to the GitHub Environment secrets."
}

$ctx = $SetupContextJson | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($ctx.soapBaseUrl)) {
    throw "ZST_SETUP_CONTEXT is missing required field: soapBaseUrl"
}

$baseUrl = $ctx.soapBaseUrl.TrimEnd('/')

$isSaaS = -not [string]::IsNullOrWhiteSpace($ctx.clientId)

if ($isSaaS) {
    $missing = @()
    if ([string]::IsNullOrWhiteSpace($ctx.tenantId))     { $missing += 'tenantId' }
    if ([string]::IsNullOrWhiteSpace($ctx.clientId))     { $missing += 'clientId' }
    if ([string]::IsNullOrWhiteSpace($ctx.clientSecret)) { $missing += 'clientSecret' }
    if ($missing.Count -gt 0) {
        throw "ZST_SETUP_CONTEXT SaaS mode is missing fields: $($missing -join ', '). Expected: { soapBaseUrl, tenantId, clientId, clientSecret, company? }"
    }

    Write-Host "SaaS mode - fetching OAuth token for tenant $($ctx.tenantId) ..."
    $tokenResponse = Invoke-RestMethod `
        -Uri "https://login.microsoftonline.com/$($ctx.tenantId)/oauth2/v2.0/token" `
        -Method POST `
        -Body @{
            grant_type    = "client_credentials"
            client_id     = $ctx.clientId
            client_secret = $ctx.clientSecret
            scope         = "https://api.businesscentral.dynamics.com/.default"
        }
    $authHeader = "Bearer $($tokenResponse.access_token)"
    Write-Host "OAuth token acquired."
} else {
    $missing = @()
    if ([string]::IsNullOrWhiteSpace($ctx.username)) { $missing += 'username' }
    if ([string]::IsNullOrWhiteSpace($ctx.password)) { $missing += 'password' }
    if ($missing.Count -gt 0) {
        throw "ZST_SETUP_CONTEXT on-prem mode is missing fields: $($missing -join ', '). Expected: { soapBaseUrl, username, password, company? }"
    }

    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($ctx.username):$($ctx.password)"))
    $authHeader = "Basic $token"
    Write-Host "On-prem mode - using Basic auth."
}

$company = $ctx.company
if ([string]::IsNullOrWhiteSpace($company)) {
    Write-Host "No company specified, auto-detecting from $baseUrl/api/v2.0/companies ..."
    try {
        $companiesResponse = Invoke-RestMethod `
            -Uri "$baseUrl/api/v2.0/companies" `
            -Method GET `
            -Headers @{ Authorization = $authHeader }
        $companies = $companiesResponse.value
        if ($companies.Count -eq 1) {
            $company = $companies[0].name
            Write-Host "Auto-detected company: $company"
        } elseif ($companies.Count -eq 0) {
            throw "No companies found at $baseUrl. Check soapBaseUrl and credentials."
        } else {
            $names = ($companies | ForEach-Object { $_.name }) -join ', '
            throw "Multiple companies found: $names. Add 'company' to ZST_SETUP_CONTEXT to specify which one."
        }
    } catch {
        throw "Failed to auto-detect company: $_"
    }
}

$encodedCompany = [Uri]::EscapeDataString($company)
$soapUrl = "$baseUrl/WS/$encodedCompany/Codeunit/ZSTSetupInitialization"

$soapBody = @"
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <RunFullSetup xmlns="urn:microsoft-dynamics-schemas/codeunit/ZSTSetupInitialization" />
  </s:Body>
</s:Envelope>
"@

$headers = @{
    "Content-Type"  = "text/xml; charset=utf-8"
    "SOAPAction"    = '"urn:microsoft-dynamics-schemas/codeunit/ZSTSetupInitialization:RunFullSetup"'
    "Authorization" = $authHeader
}

Write-Host "Calling BC setup endpoint: $soapUrl"

try {
    $response = Invoke-WebRequest -Uri $soapUrl -Method POST -Headers $headers -Body $soapBody -UseBasicParsing
    Write-Host "Setup completed successfully (HTTP $($response.StatusCode))"
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_STEP_SUMMARY -Value "ZST Setup completed successfully on company **$company**."
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $detail = $_.Exception.Message
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        $detail = "$detail - $responseBody"
    } catch {}
    Write-Error "BC setup call failed (HTTP $statusCode): $detail"
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_STEP_SUMMARY -Value "ZST Setup FAILED on company **$company**: HTTP $statusCode - $detail"
    }
    throw
}
