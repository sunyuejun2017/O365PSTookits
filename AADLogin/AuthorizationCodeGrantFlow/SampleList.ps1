
$env:appFolder = $pwd

#加载

#. $env:appFolder\AppModule.ps1

. $env:appFolder\AuthModule.ps1
#. $env:appFolder\MSGraphModule.ps1

. .\GraphAPI\User.ps1


GetAccessToken .\config.json

$accessToken = gc $pwd\accessToken.txt

$ResourceID="https://microsoftgraph.chinacloudapi.cn"

$headers = @{}
        $headers.Add('Authorization','Bearer ' + $accessToken)
        $headers.Add('Content-Type', "application/json")



#Get Me
Invoke-GraphRequest -Token $accessToken -url ($ResourceID+"/v1.0/me") -Method Get
#Get Me
Invoke-GraphRequest -Token $accessToken -url ($ResourceID+"/v1.0/me/messages") -Method Get

#region 用户搜索
$upn = "appuser@51o365.tk"
$url = $resourceId+ "/v1.0/users?`$filter=userPrincipalName eq '$upn'"

Invoke-GraphRequest -Token $accessToken -url $url -Method Get

#endregion

