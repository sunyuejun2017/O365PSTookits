# update user's property
function User_Update {
    param (
        $header,$body,$upn
    )

    $url = $resourceId+ "/v1.0/users/$upn"

    $Response=Invoke-WebRequest -Method Patch -Uri $url -Header $headers -Body $body -ErrorAction Stop

    
}

function User_Delete {
    param (
        $header,$upn
    )

    $url = $resourceId+ "/v1.0/users/$upn"

    $Response=Invoke-WebRequest -Method Delete -Uri $url -Header $headers -ErrorAction Stop

    
}

function User_Get {
    param (
        $header,$upn
    )

    $url = $resourceId+ "/v1.0/users/$upn"

    $Response=Invoke-WebRequest -Method Get -Uri $url -Header $headers -ErrorAction Stop

    
}

function User_Search {
    param (
        $header,$upn
    )

    $url = $resourceId+ "/v1.0/users?`$filter=userPrincipalName eq '$upn'"

    $Response=Invoke-WebRequest -Method Get -Uri $url -Header $headers -ErrorAction Stop

    $responseObject = ConvertFrom-Json $Response.Content

    if ($responseObject.value -eq $null)
    {
        Write-Host "No found" -ForegroundColor Yellow
    }
    else {
        Write-Host "User: $upn was created" -ForegroundColor Green
        $responseObject.value | ForEach-Object { $_.userPrincipalName}
    }
   
}
# Load ADAL
Add-Type -Path ".\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

# Output Token and Response from AAD Graph API
$env:accessToken = "$pwd\adal_tokenv2.txt"

#读取Config.json
$config = Get-Content ".\config.json" -Raw | ConvertFrom-Json

#获取访问令牌
If ((Test-Path -Path $env:accessToken) -ne $false) {
	$accessToken = Get-Content $env:accessToken
}
else {
    $accessToken = $null
}

$clientId = $config.AppId.ClientId
$secret = $config.AppId.clientSecret
$resourceId = $config.AppId.ResourceUrl
$tenantId = $config.AppId.tenantid
$login = "https://login.chinacloudapi.cn"


    # Get an Access Token with ADAL
    $clientCredential = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($clientId,$secret)
    $authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext("{0}/{1}" -f $login,$tenantId)
    $authenticationResult = $authContext.AcquireToken($resourceId, $clientcredential)

    <#
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authorityPS 
    $UserCred = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential" -ArgumentList "XXXXX","XXX"
    PS D:\PowershellRepository\MSGraph\UnattendedSamples> $authResult = $authContext.AcquireTokenAsync($resourceId,$clientId,$UserCred)
    #>
    #$authenticationResult

    # Store AuthCode
    Set-Content $env:accessToken $authenticationResult.AccessToken

# Call the AAD Graph API 
$headers = @{ 
    "Authorization" = ("Bearer {0}" -f $authenticationResult.AccessToken);
    "Content-Type" = "application/json";
}

#$authenticationResult.AccessToken
#Pause
$orgname = "51o365.partner.onmschina.cn"
$username = "testuser"+ -join ([char[]](48..57) | Get-Random -Count 6)

$body=@"
{

        "accountEnabled": true,
        "displayName": "$username",
        "mailNickname": "$username",
        "userPrincipalName": "$username@$($orgname)",
        "passwordProfile" : {
          "forceChangePasswordNextSignIn": false,
          "password": "P@ssw0rd!"
        }
      
  }
"@
#$body
# create user
$Response=Invoke-WebRequest -Method Post -Uri ($resourceId+"/v1.0/users") -Header $headers -Body $body -ErrorAction Stop

#更新用户属性
$body = @"
  {
     "jobTitle": "IT"
  }
"@
User_Update -header $headers -body $body -upn "$username@51o365.partner.onmschina.cn"

# 按部门选择
$url = $resourceId+ "/v1.0/users?`$filter=startswith(jobtitle,'IT')"
#$url = $resourceId+ "/v1.0/users?`$filter=userPrincipalName eq '$username@21v365.win')"
$Response=Invoke-WebRequest -Method GET -Uri $url -Header $headers -ErrorAction Stop
 
$responseObject = ConvertFrom-Json $Response.Content

$responseObject.value | ForEach-Object { $_.userPrincipalName}


# 搜索用户
User_Search -header $headers -upn "$username@$orgname"


