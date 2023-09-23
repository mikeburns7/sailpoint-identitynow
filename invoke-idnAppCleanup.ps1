
[cmdletbinding()]
param([string]$CleanUp)



$access_token = Read-Host "Enter IDN Session Token - https://xxx.identitynow.com/ui/session?refresh=true"
$appId = Read-Host "Enter Applicaiton ID"
$roleary = @()
$roles = Invoke-RestMethod -Method Get -Uri "https://xxx.api.identitynow.com/cc/api/role/list" -Headers @{Authorization = "Bearer $($access_token)" }
$matchlog = ''
$aplog = ''
$appInfo = ''
$Deleteresults = ''

$utime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() 

$appInfo = Invoke-RestMethod -Method Get -Uri "https://xxx.api.identitynow.com/cc/api/app/get/$($appId)?_dc=$($utime)" -Headers @{Authorization = "Bearer $($access_token)" }


#Get all roles and stroy in array
Foreach ($role in $roles.items) {
     $roleinfo = Invoke-RestMethod -Method Get -Uri "https://xxx.api.identitynow.com/cc/api/role/get/$($role.id)" -Headers @{Authorization = "Bearer $($access_token)" }
     #$hash.add($roleinfo.name,$roleinfo.id,$roleinfo.selector.complexRoleCriterion.children.value)
     #$hash.add($roleinfo.name,$roleinfo.id)
     $roleary = $roleary + [PSCustomObject]@{RoleID = $roleinfo.id; RoleName = $roleinfo.name; EntValue = $roleinfo.selector.complexRoleCriterion.children.value}

    }


#get all access profiles for a given Application
If ($appid) {
        #Get Access Profiles
        $utime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() 
        $accessProfiles = Invoke-RestMethod -Method Get -Uri "https://xxx.api.identitynow.com/cc/api/app/getAccessProfiles/$($appid)?_dc=$($utime)" -Headers @{Authorization = "Bearer $($access_token)" }
        $aps = $accessProfiles.items | Select-Object -Property name, id
        Write-Host $aps | Format-Table -Property name, id
        $aps | Export-Csv "$($appid)-APs.csv" -NoTypeInformation
        #$aps = $accessProfiles.items.id
        
        if ($CleanUp -eq 'y') { 
            Write-Host "Deleting App" 
            
            #Delete Application
            $applicationId = $appInfo.appId
            $Deleteresults += Invoke-RestMethod -Method 'POST' -Uri "https://xxx.api.identitynow.com/cc/api/app/delete/$($applicationId)" -Headers @{Authorization = "Bearer $($access_token)"}
        
        }
        
    
    }

#get all entitlements for a given access prfoile
If ($aps) {
    Foreach ($ap in $aps) {
        $aplog += "$($ap.name)`n"

        $results = Invoke-RestMethod -Method "GET" -Uri "https://xxx.api.identitynow.com/v2/access-profiles/$($ap.id)" -Headers @{Authorization = "Bearer $($access_token)"; "Content-Type" = "application/json" }
        $entitlement= $results.entitlements[0]
        #write-host "Delete $ap"
        $body = @"
{
    "indices": [
        "entitlements"
    ],
    "query": {
        "query": "$($entitlement)"
    }
}
"@


$searchresult = Invoke-RestMethod -Method 'POST' -uri "https://mandiant.api.identitynow.com/v3/search" -body $body -Headers @{Authorization = "Bearer $($access_token)"; "Content-Type" = "application/json" }

#Write-host "AP Entitlement ID: $($entitlement) Search Value: $($searchresult.value)" 

#check for entitlement value match against list of roles stored in the array
Foreach ($roleitem in $roleary) {
    if ($roleitem.EntValue -eq $searchresult.value){
        $matchlog += "$($roleitem.RoleName)`n"

        if ($CleanUp -eq 'y') { 
            
            #Delete Role
            $roleItemId = $roleitem.RoleID
            Write-Host "Deleting Role! - $($roleItemId)" 
        $Deleteresults += Invoke-RestMethod -Method "POST" -Uri "https://xxx.api.identitynow.com/cc/api/role/delete/$($roleItemId)" -Headers @{Authorization = "Bearer $($access_token)"}

        Start-Sleep 5
        }


        if ($CleanUp -eq 'y') { 
            $accessProfileId = $ap.id
            Write-Host "Deleting AccessProfile! - $($accessProfileId)" 
            
            #Delete Access Profile
        $Deleteresults += Invoke-RestMethod -Method "DELETE" -Uri "https://xxx.api.identitynow.com/v2/access-profiles/$($accessProfileId)" -Headers @{Authorization = "Bearer $($access_token)"; "Content-Type" = "application/json" }
        }
        

    }

   }

 

    }
}Else {
    Write-Warning 'No app ids provided. Continuing to the next record'
    }

    if ($CleanUp -eq 'y') { 
        Write-Host "******The following Configurations have been REMOVED*****" 
    }


write-host "===Applications To Be Removed===="
write-host $appInfo.name

write-host "===Access Profiles To Be Removed===="
write-host $aplog


write-host "===Roles To Be Removed===="
write-host $matchlog 

write-host "===Delete Results===="
write-host  $Deleteresults > "$($appid)-DeleteLog.txt" 


#https://stackoverflow.com/questions/46412764/powershell-hashtable-with-multiple-values-and-one-key

<#if a access profile cannot be deleted, it most likely is tied to another role. Use IDN search to find role to remove it from 

Navigate to Search.

Within the query bar, run the following query. Replace [Access Profile Name] with the Access Profile’s name:
accessProfiles.name:"[Access Profile Name]"

Run the Search query.

Note the Roles returned from the Search.

Navigate to Admin > Access > Roles.

Find each Role from the Search results and remove the Access Profile. Save the changes for each Role.

After all Roles changes have been saved, remove the Access Profile
https://support.sailpoint.com/hc/en-us/articles/360053867412--IdentityNow-Access-profile-cannot-be-deleted-because-it-is-in-use-error-when-trying-to-delete-Access-Profile?_ga=2.37076192.1340825291.1666633961-1060168444.1665154268&_gl=1*1hi6qq*_ga*MTA2MDE2ODQ0NC4xNjY1MTU0MjY4*_ga_SS72Z4HXJM*MTY2NjY0MjgyNS4xNy4xLjE2NjY2NDI5MDIuNDYuMC4w

#>
