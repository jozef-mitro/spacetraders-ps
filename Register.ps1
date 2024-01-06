param($Faction = 'Random', $Symbol = 'Random', $Email, $OutputFile, $Mock = $false)
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

if (!$OutputFile) {
    $OutputFile = "Register-$Symbol.json"
}

if ($Mock) {
    $api = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
} else {
    $api = 'https://api.spacetraders.io/v2'
}

$uri = $api + '/register'
$response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json' -SkipHttpErrorCheck -StatusCodeVariable status
Write-Host "Status code: $status"
ConvertTo-Json $response -Depth 100

if ($status -eq 201) {
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $OutputFile
}