param($Agent, $Mock = $false)

$path = Join-Path -Path $PSScriptRoot -ChildPath 'AuthenticatedGet.ps1'
& $path -Agent $Agent -Route 'my/agent' -Mock $Mock