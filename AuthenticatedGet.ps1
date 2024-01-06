param($Agent, $Route, $OutputFile, $Mock = $false)

if (!$Agent) {
    $settings = Get-Content -Path 'settings.json' -Raw | ConvertFrom-Json
    $Agent = $settings.CurrentAgent

    if (!$Agent) {
        Write-Host 'No agent specified and no agent found in settings.json'

        exit
    }
}

if (!$Route) {
    Write-Host 'No route specified'

    exit
}

# If no output file is specified, we'll infer it from the route, e.g. my/ships -> MyShips.json.
if (!$OutputFile) {
    $OutputFile = ($Route -split '/' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join ''
}

if ($Mock) {
    $api = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
}
else {
    $api = 'https://api.spacetraders.io/v2'
}

if (!(Test-Path -Path "Agents\$Agent\Register.token")) {
    Write-Host "No register token found for agent: $Agent"

    exit
}

$secureToken = Get-Content -Path "Agents\$Agent\Register.token" | ConvertTo-SecureString

if (!$secureToken) {
    Write-Host "Failed to load the token for agent: $Agent"

    exit
}

$response = Invoke-RestMethod -Authentication Bearer -Token $secureToken -Uri "$api/$Route" -Method Get -SkipHttpErrorCheck -StatusCodeVariable status

if ($status -eq 200) {
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath "Agents\$Agent\$OutputFile.json"
    $statusColor = 'Green'
}
else {
    $statusColor = 'Red'
}

Write-Host "Status code: $status" -ForegroundColor $statusColor
ConvertTo-Json $response -Depth 100