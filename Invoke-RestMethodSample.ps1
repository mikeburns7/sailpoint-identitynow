$access_token = Read-Host "Provide App Acccess Token"


Invoke-RestMethod -Method "DELETE" -Uri "https://myapiurl.api" -Headers @{Authorization = "Bearer $($access_token)"; "Content-Type" = "application/json"}
