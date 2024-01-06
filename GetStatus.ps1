$response = Invoke-RestMethod -Uri 'https://api.spacetraders.io/v3' -Method Get -SkipHttpErrorCheck -StatusCodeVariable status
Write-Host "Status code: $status"
ConvertTo-Json $response -Depth 100