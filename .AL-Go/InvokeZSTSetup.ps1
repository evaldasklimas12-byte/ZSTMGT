param(
    [Parameter(Mandatory = $true)]
    [string]$SoapBaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$Company,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password
)

$errorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$encodedCompany = [Uri]::EscapeDataString($Company)
$soapUrl = "$($SoapBaseUrl.TrimEnd('/'))/WS/$encodedCompany/Codeunit/ZSTSetupInitialization"

$soapBody = @"
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <RunFullSetup xmlns="urn:microsoft-dynamics-schemas/codeunit/ZSTSetupInitialization" />
  </s:Body>
</s:Envelope>
"@

$token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$headers = @{
    "Content-Type" = "text/xml; charset=utf-8"
    "SOAPAction"   = '"urn:microsoft-dynamics-schemas/codeunit/ZSTSetupInitialization:RunFullSetup"'
    "Authorization" = "Basic $token"
}

Write-Host "Calling BC setup endpoint: $soapUrl"

try {
    $response = Invoke-WebRequest -Uri $soapUrl -Method POST -Headers $headers -Body $soapBody -UseBasicParsing
    Write-Host "Setup completed successfully (HTTP $($response.StatusCode))"
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_STEP_SUMMARY -Value "ZST Setup completed successfully on company **$Company**."
    }
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $detail = $_.Exception.Message
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        $detail = "$detail`n$responseBody"
    } catch {}
    Write-Error "BC setup call failed (HTTP $statusCode): $detail"
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_STEP_SUMMARY -Value "ZST Setup FAILED on company **$Company**: HTTP $statusCode — $detail"
    }
    throw
}
