#region 清除IE缓存
function Clear-IECachedData
{
	[CmdletBinding(ConfirmImpact = 'None')]
	param
	(
		[Parameter(Mandatory = $false,
				   HelpMessage = ' Delete Temporary Internet Files')]
		[switch]
		$TempIEFiles,
		[Parameter(HelpMessage = 'Delete Cookies')]
		[switch]
		$Cookies,
		[Parameter(HelpMessage = 'Delete History')]
		[switch]
		$History,
		[Parameter(HelpMessage = 'Delete Form Data')]
		[switch]
		$FormData,
		[Parameter(HelpMessage = 'Delete Passwords')]
		[switch]
		$Passwords,
		[Parameter(HelpMessage = 'Delete All')]
		[switch]
		$All,
		[Parameter(HelpMessage = 'Delete Files and Settings Stored by Add-Ons')]
		[switch]
		$AddOnSettings
	)
	if ($TempIEFiles) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 8}
	if ($Cookies) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 2}
	if ($History) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 1}
	if ($FormData) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 16}
	if ($Passwords) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 32 }
	if ($All) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 255}
	if ($AddOnSettings) { RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 4351 }
}

# User Action


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
        
        $responseObject.value | ForEach-Object { $_.userPrincipalName ; $_.mobilePhone }
    }
   
}

function UserSearchByUPN {
    param (
        $token,$upn
    )

    $url = $resourceId+ "/v1.0/users?`$filter=userPrincipalName eq '$upn'"

    # $Response=Invoke-WebRequest -Method Get -Uri $url -Header $headers -ErrorAction Stop

    # $responseObject = ConvertFrom-Json $Response.Content

    $responseObject = Invoke-GraphRequest -Token $token -url $url -Method Get

    if ($responseObject.value -eq $null)
    {
        Write-Host "No found" -ForegroundColor Yellow
    }
    else {
        Write-Host "User: $upn was found" -ForegroundColor Green
        $responseObject.value
        #$responseObject.value | ForEach-Object { $_.userPrincipalName}
    }
   
}

function User_Update {
    param (
        $header,$body,$upn
    )

    $url = $resourceId+ "/v1.0/users/$upn"

    $Response=Invoke-WebRequest -Method Patch -Uri $url -Header $headers -Body $body -ErrorAction Stop

}


$ResourceID=$env:id

function HelloWorld {
    param (
        [string]$message
    )

    Write-Host "Hello, $message!" -ForegroundColor Yellow
    
}


$ResourceID="https://microsoftgraph.chinacloudapi.cn"

#region Me

function GetMe {
    param (
        $token
    )
    
    $url = "$ResourceID/v1.0/me"

    $responseObject = Invoke-GraphRequest -Token $token -url $url -Method Get

    return $responseObject
    }

function CreateUser {
    param (
        
    )
    
$orgname = "51o365.partner.onmschina.cn"
$username = "testuser"+ -join ([char[]](48..57) | Get-Random -Count 6)
#$username
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
$t=ConvertFrom-Json $Response.Content
return $t.userPrincipalName

}