param($Agent, $Mock = $false)

$path = Join-Path -Path $PSScriptRoot -ChildPath 'Call-GetMethod.ps1'
& $path -Agent $Agent -Route 'my/ships' -Mock $Mock -Authentication $true