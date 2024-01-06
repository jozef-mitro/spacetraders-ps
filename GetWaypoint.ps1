param($System, $Waypoint, $Mock = $false)

if (!$System -or !$Waypoint) {
    Write-Host 'You must specify a system and a waypoint.'

    exit
}

$path = Join-Path -Path $PSScriptRoot -ChildPath 'Call-GetMethod.ps1'
& $path -Route "systems/$System/waypoints/$Waypoint" -Mock $Mock -Authentication $true