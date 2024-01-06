param($Agent, $Mock = $false)

if (!$Agent) {
    # Read the current agent from the settings.json file.
    $settings = Get-Content -Path 'settings.json' -Raw | ConvertFrom-Json
    $Agent = $settings.CurrentAgent

    if (!$Agent) {
        Write-Host 'No agent specified and no agent found in settings.json'

        exit
    }
}

if ($Mock) {
    $api = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
} else {
    $api = 'https://api.spacetraders.io/v2'
}

# Register.token must exist in the agent's directory.
if (!(Test-Path -Path "Agents\$Agent\Register.token")) {
    Write-Host "No register token found for agent: $Agent"

    exit
}

$secureToken = Get-Content -Path "Agents\$Agent\Register.token" | ConvertTo-SecureString
$uri = $api + '/my/agent'
$response = Invoke-RestMethod -Authentication Bearer -Token $secureToken -Uri $uri -Method Get -SkipHttpErrorCheck -StatusCodeVariable status

if ($status -eq 200) {
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath "Agents\$Agent\MyAgent.json"
    $statusColor = 'Green'
} else {
    $statusColor = 'Red'
}

Write-Host "Status code: $status" -ForegroundColor $statusColor
ConvertTo-Json $response -Depth 100