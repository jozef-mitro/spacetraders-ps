param($Mock = $false)

$path = Join-Path -Path $PSScriptRoot -ChildPath 'Call-GetMethod.ps1'
& $path -Mock $Mock