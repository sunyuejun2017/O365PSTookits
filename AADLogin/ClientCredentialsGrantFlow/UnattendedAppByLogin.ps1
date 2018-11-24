
# 读取并配置参数
$config = Get-Content ".\config.json" -Raw | ConvertFrom-Json

$clientId = $config.AppId.ClientId
$secret = $config.AppId.clientSecret
$resourceId = $config.AppId.ResourceUrl
$tenantId = $config.AppId.tenantid
$secretEncoded = [System.Web.HttpUtility]::UrlEncode($secret)

# 设置访问令牌文件
$accessTokenFile =  ".\AccessTokenCode.txt"

# 读取
If (Test-Path -Path $accessTokenFile) {
	$accessToken = Get-Content $accessTokenFile
}
else {
    $accessToken = $null
}

# 检查访问令牌是否超过1小时重新获取新的访问令牌
If (($accessToken -eq $null) -or ((get-date) - (get-item $accessTokenFile).LastWriteTime).TotalHours -gt 1) 
{
	
    # 使用“客户凭据流”来获取访问令牌
    $body="client_id="+$clientId+"&client_secret="+$secretEncoded+"&grant_type=client_credentials&resource="+$resourceId
    $Response = Invoke-WebRequest -Method Post -ContentType "application/x-www-form-urlencoded" -Uri ("https://login.chinacloudapi.cn/$tenantId/oauth2/token") -body $body
 
    $Authentication = $Response.Content|ConvertFrom-Json
    Set-Content $accessTokenFile $Authentication.access_token
    $accessToken = $Authentication.access_token

}


$headers = @{ 
    "Authorization" = ("Bearer {0}" -f $accessToken);
    "Content-Type" = "application/json";
}


write-host "Get All Users Information:"
# 使用令牌进行Graph调用
# 获取所有用户列表 
$Response=Invoke-WebRequest -Method GET -Uri ($ResourceID+"/v1.0/users") -Header $headers -ErrorAction Stop

$responseObject = ConvertFrom-Json $Response.Content

#$responseObject
$responseObject.value | ForEach-Object { $_.userPrincipalName}