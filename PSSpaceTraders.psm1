function Invoke-Api {
    param(
        $Route,
        [Parameter(Mandatory = $true)] [ValidateSet('Get', 'Post')] [string]$Method,
        $WriteOutput = $true,
        $OutputFile,
        $Authentication,
        $Agent,
        $Body,
        $Mock = $false
    )

    if ($Mock) {
        $uri = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
    }
    else {
        $uri = 'https://api.spacetraders.io/v2'
    }

    if ($Route) {
        $uri += "/$Route"
    }

    $invoke_params = @{
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
            $settings = Get-Content -Path 'Data\settings.json' -Raw | ConvertFrom-Json
            $Agent = $settings.CurrentAgent
    
            if (!$Agent) {
                Write-Host 'No agent specified and no agent found in settings.json'
    
                exit
            }
        }
    
        $token_path = "Data\Agents\$Agent\Register.token"

        if (!(Test-Path -Path $token_path)) {
            Write-Host "No register token found for agent: $Agent"
    
            exit
        }

        $secure_token = Get-Content -Path $token_path | ConvertTo-SecureString
    
        if (!$secure_token) {
            Write-Host "Failed to load the token for agent: $Agent"
    
            exit
        }

        $invoke_params.Add('Authentication', 'Bearer')
        $invoke_params.Add('Token', $secure_token)
    }

    if (($Method -eq 'Post' -or $Method -eq 'Patch') -and $Body) {
        $invoke_params.Add('Body', $Body)
    }

    $api_response = Invoke-RestMethod @invoke_params

    if ($status -eq 200 -or $status -eq 201 -or $status -eq 204) {
        if ($WriteOutput) {
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

            $output_path = 'Data' + ($Authentication ? "\Agents\$Agent" : '') + "\$OutputFile.json"
            $api_response | ConvertTo-Json -Depth 100 | Out-File -FilePath $output_path
        }

        $status_color = 'Green'
    }
    else {
        $status_color = 'Red'
    }

    Write-Host "Call-Api: $Method $uri"
    Write-Host "Status code: " -NoNewline
    Write-Host $status -ForegroundColor $status_color
    # Avoid rate limiting. We can do 2 requests per second.
    Start-Sleep -Milliseconds 500

    return $api_response
}

function Get-Waypoints {
    param (
        [Parameter(Mandatory = $true)][string]$System,
        [Parameter(Mandatory = $false)][string[]]$Traits,
        [Parameter(Mandatory = $false)]
        [ValidateSet('PLANET', 'GAS_GIANT', 'MOON', 'ORBITAL_STATION', 'JUMP_GATE', 'ASTEROID_FIELD', 'ASTEROID', 'ENGINEERED_ASTEROID', 'ASTEROID_BASE', 'NEBULA', 'DEBRIS_FIELD', 'GRAVITY_WELL', 'ARTIFICIAL_GRAVITY_WELL', 'FUEL_STATION')]
        [string]$Type
    )

    $invoke_api_params = @{
        Method      = 'Get'
        WriteOutput = $false
    }
    $page = 1
    $limit = 20
    $total = 0
    $output = @()

    do {
        $invoke_api_params.Route = "systems/$System/waypoints/?limit=$limit&page=$page"

        if ($Traits) {
            foreach ($trait in $Traits) {
                $invoke_api_params.Route += "&traits[]=$trait"
            }
        }

        if ($Type) {
            $invoke_api_params.Route += "&type=$Type"
        }

        $waypoints_response = Invoke-Api @invoke_api_params
        $total = $waypoints_response.meta.total
        $page++

        # If a waypoint has the MARKETPLACE traite, we grabt the market data for that waypoint.
        foreach ($waypoint in $waypoints_response.data) {
            Write-Host "Waypoint: $($waypoint.symbol)"

            if ($waypoint.traits | Where-Object { $_.symbol -eq 'MARKETPLACE' }) {
                Write-Host "Marketplace: $($waypoint.symbol)"
                $invoke_api_params.Route = "systems/$System/waypoints/$($waypoint.symbol)/market"
                $market_response = Invoke-Api @invoke_api_params
                $waypoint | Add-Member -MemberType NoteProperty -Name "market" -Value $market_response.data
            }
        }

        $output += $waypoints_response.data
    } while ($page * $limit -lt $total)

    Write-Host "Total: $total"
    $outputPath = "Data\Systems\$System\Waypoints$($Traits ? "-$($Traits -join '-')" : '')$($Type ? "-$Type" : '').json"
    $output | ConvertTo-Json -Depth 100 | Out-File ( New-Item -Path $outputPath -Force )
}

function Clear-TemporaryData {
    #Remove all .json files inside the Data directory except for the settings.json file.
    Get-ChildItem -Path 'Data' -Filter '*.json' -Exclude 'settings.json' -Recurse | Remove-Item
    #Remove all directories inside the Data diricetory except for the directories inside the Agents directory.
    Get-ChildItem -Path 'Data' -Directory -Exclude 'Agents' | Remove-Item -Recurse
}

function Add-Agent {
    param(
        $Faction = 'Random',
        $Symbol = 'Random',
        $Email,
        $Mock = $false
    )

    $Factions = @('COSMIC', 'VOID', 'GALACTIC', 'QUANTUM', 'DOMINION', 'ASTRO', 'CORSAIRS', 'OBSIDIAN', 'AEGIS', 'UNITED', 'SOLITARY', 'COBALT', 'OMEGA', 'ECHO', 'LORDS', 'CULT', 'ANCIENTS', 'SHADOW', 'ETHEREAL')
    $body = @{}

    if ($Faction -eq 'Random') {
        $Faction = $Factions | Get-Random
    }
    elseif ($Factions -notcontains $Faction) {
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
        $email_regex = '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'

        if ($Email -notmatch $email_regex) {
            Write-Host "Invalid email address: $Email"

            exit
        }

        $body.Add('email', $Email)
    }

    $body = $body | ConvertTo-Json

    if ($Mock) {
        $api = 'https://stoplight.io/mocks/spacetraders/spacetraders/96627693'
    }
    else {
        $api = 'https://api.spacetraders.io/v2'
    }

    $uri = $api + '/register'
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json' -SkipHttpErrorCheck -StatusCodeVariable status

    if ($status -eq 201) {
        $output_directory = "Data\Agents\$Symbol"

        if (!(Test-Path -Path $output_directory)) {
            New-Item -Path $output_directory -ItemType Directory -Force | Out-Null
        }

        $secure_token = ConvertTo-SecureString -String $response.data.token -AsPlainText -Force
        $encrypted_token = ConvertFrom-SecureString -SecureString $secure_token
        $encrypted_token | Out-File -FilePath "$output_directory\Register.token"
        # Make sure we don't save the token in plain text.
        $response.data.token.Clear()
        $response | ConvertTo-Json -Depth 100 | Out-File -FilePath "$output_directory\Register.json"
        $status_color = 'Green'
    }
    else {
        $status_color = 'Red'
    }

    Write-Host "Call-Api: $Method $uri"
    Write-Host "Status code: " -NoNewline
    Write-Host $status -ForegroundColor $status_color
    # Avoid rate limiting. We can do 2 requests per second.
    Start-Sleep -Milliseconds 500
}