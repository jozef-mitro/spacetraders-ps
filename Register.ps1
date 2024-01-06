param($Faction = 'Random', $Symbol = 'Random', $Email, $Mock = $false)
$Factions = @('COSMIC', 'VOID', 'GALACTIC', 'QUANTUM', 'DOMINION', 'ASTRO', 'CORSAIRS', 'OBSIDIAN', 'AEGIS', 'UNITED', 'SOLITARY', 'COBALT', 'OMEGA', 'ECHO', 'LORDS', 'CULT', 'ANCIENTS', 'SHADOW', 'ETHEREAL')
$body = @{}

if ($Faction -eq 'Random') {
    $Faction = $Factions | Get-Random
} elseif ($Factions -notcontains $Faction) {
    Write-Host "Invalid faction: $Faction"
    Write-Host "Valid factions: $Factions"

    exit
}

$body.Add('faction', $Faction)

if ($Symbol -eq 'Random') {
    $Symbol = [System.Guid]::NewGuid().ToString().Substring(0, 14)
} if ($Symbol.Length -lt 3 -or $Symbol.Length -gt 14) {
    Write-Host "Invalid symbol: $Symbol"
    Write-Host "Symbol must be between 3 and 14 characters (inclusive)"

    exit
}

$body.Add('symbol', $Symbol)

if ($Email) {
    $EmailRegex = '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'

    if ($Email -notmatch $EmailRegex) {
        Write-Host "Invalid email address: $Email"

        exit
    }

    $body.Add('email', $Email)
}

$body = $body | ConvertTo-Json

if ($Mock) {
    $api = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
} else {
    $api = 'https://api.spacetraders.io/v2'
}

$uri = $api + '/register'
$response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json' -SkipHttpErrorCheck -StatusCodeVariable status

if ($status -eq 201) {
    $OutputDirectory = "Agents\$Symbol"

    if (!(Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }

    $secureToken = ConvertTo-SecureString -String $response.data.token -AsPlainText -Force
    $encryptedToken = ConvertFrom-SecureString -SecureString $secureToken
    $encryptedToken | Out-File -FilePath "$OutputDirectory\Register.token"
    # Make sure we don't save the token in plain text.
    $response.data.token.Clear()
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputDirectory\Register.json"
    $statusColor = 'Green'
} else {
    $statusColor = 'Red'
}

Write-Host "Status code: $status" -ForegroundColor $statusColor
ConvertTo-Json $response -Depth 100