param(
    $OutputFile,
    $Route,
    [Parameter(Mandatory = $true)] [ValidateSet('Get', 'Post')] [string]$Method,
    $Authentication,
    $Agent,
    $Body,
    $Mock = $false
)

# If no output file is specified, we'll infer it from the route, e.g. my/ships -> MyShips.json.
if (!$OutputFile) {
    # Root route is the API status.
    if (!$Route) {
        $OutputFile = 'GetStatus'
    }
    else {
        $OutputFile = ($Route -split '/' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join ''
    }
}

if ($Mock) {
    $uri = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
}
else {
    $uri = 'https://api.spacetraders.io/v2'
}

if ($Route) {
    $uri += "/$Route"
}

$invokeParams = @{
    Uri                = $uri
    Method             = $Method
    SkipHttpErrorCheck = $true
    StatusCodeVariable = 'status'
    Headers            = @{
        'Content-Type' = 'application/json'
        'Accept'       = 'application/json'
    }
}

if ($Authentication) {
    if (!$Agent) {
        $settings = Get-Content -Path 'settings.json' -Raw | ConvertFrom-Json
        $Agent = $settings.CurrentAgent
    
        if (!$Agent) {
            Write-Host 'No agent specified and no agent found in settings.json'
    
            exit
        }
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

    $invokeParams.Add('Authentication', 'Bearer')
    $invokeParams.Add('Token', $secureToken)
}

if (($Method -eq 'Post' -or $Method -eq 'Patch') -and $Body) {
    $invokeParams.Add('Body', $Body)
}

$response = Invoke-RestMethod @invokeParams

if ($Method -eq 'Get' -and ($status -eq 200 -or $status -eq 204)) {
    $success = $true
} elseif ($Method -eq 'Post' -and $status -eq 201) {
    $success = $true
} elseif ($Method -eq 'Patch' -and $status -eq 200) {
    $success = $true
} else {
    $success = $false
}

if ($success) {
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath "Agents\$Agent\$OutputFile.json"
    $statusColor = 'Green'
}
else {
    $statusColor = 'Red'
}

Write-Host "Status code: $status" -ForegroundColor $statusColor
ConvertTo-Json $response -Depth 100

return $response