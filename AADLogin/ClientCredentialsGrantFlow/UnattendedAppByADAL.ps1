# Load ADAL
Add-Type -Path ".\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

. .\GraphModule.ps1


# Output Token and Response from AAD Graph API
$accessTokenFile = ".\AccessTokenCode.txt"

#读取Config.json
$config = Get-Content ".\config.json" -Raw | ConvertFrom-Json

#获取访问令牌
If (Test-Path -Path $accessTokenFile) {
	$env:accessToken = Get-Content $accessTokenFile
}

$clientId = $config.AppId.ClientId
$secret = $config.AppId.clientSecret
$resourceId = $config.AppId.ResourceUrl
$tenantId = $config.AppId.tenantid
$login = "https://login.chinacloudapi.cn"
$login2  = "https://login.partner.microsoftonline.cn"

# 检查访问令牌是否超过1小时重新获取新的访问令牌
If (($accessToken -eq $null) -or ((get-date) - (get-item $accessTokenFile).LastWriteTime).TotalHours -gt 1) 
{
	
    # 获取访问令牌，并保存
    # Get an Access Token with ADAL
    # $clientCredential = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($clientId,$secret)
    # $authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext("{0}/{1}" -f $login,$tenantId)
    # $authenticationResult = $authContext.AcquireToken($resourceId, $clientcredential)

    #$authCode = Get-AuthCodeByADAL -login $login2 -tenantId $tenantId -ClientId $clientId -ClientSecret $secret
    
    $authCode = Get-AuthCode -login $login2 -tenantId $tenantId -ClientId $clientId -ClientSecret $secret
    
    # Store AuthCode
    Set-Content $accessTokenFile $authCode
    $accessToken = $authCode

}
# Call the AAD Graph API 
$headers = @{ 
    "Authorization" = ("Bearer {0}" -f $accessToken);
    "Content-Type" = "application/json";
}


$endpointv1 = "$resourceID/v1.0/"
$endpointbeta = "$resourceID/beta/"

Invoke-GraphRequest -Token $accessToken -url "https://microsoftgraph.chinacloudapi.cn/v1.0/users/appuser@51o365.tk" -Method Get

Invoke-GraphRequest -Token $accessToken -url "https://microsoftgraph.chinacloudapi.cn/v1.0/users" -Method Get


  