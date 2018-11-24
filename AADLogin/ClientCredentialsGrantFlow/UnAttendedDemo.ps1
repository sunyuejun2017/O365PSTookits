Function Get-AuthCode(
	[string]$ClientId,
    [string]$ClientSecret,
    [string]$tenantId)
{
        
    $ResourceUrl = "https://microsoftgraph.chinacloudapi.cn"

    $body="client_id="+$ClientId+"&client_secret="+$ClientSecret+"&grant_type=client_credentials&resource="+$ResourceUrl
    
    $Response = Invoke-WebRequest -Method Post -ContentType "application/x-www-form-urlencoded" -Uri ("https://login.chinacloudapi.cn/$tenantId/oauth2/token") -body $body

    $Authentication = $Response.Content|ConvertFrom-Json
    
    #
    return $Authentication.access_token
}

function GraphAPICall ($token,$operation) {
    
    $Response=Invoke-WebRequest -Method GET -Uri ("https://microsoftgraph.chinacloudapi.cn/v1.0/$operation") -Header @{ Authorization = "BEARER "+$token} -ErrorAction Stop

    return ConvertFrom-Json $Response.Content
    
}

#region 调用Graph
Function Invoke-GraphRequest {
    param($Token, $url, $Method, $Body)
    
    try {
        $headers = @{}
        $headers.Add('Authorization','Bearer ' + $Token)
        $headers.Add('Content-Type', "application/json")

        if($Body)
        {
           $response = Invoke-WebRequest -Uri $url -Method $Method -Body $Body -Headers $headers -UseBasicParsing
        }
        else
        {
           $response = Invoke-WebRequest -Uri $url -Method $Method -Headers $headers -UseBasicParsing
        }

        return (ConvertFrom-Json $response.Content)
    }
    catch
    {
        #throw ($error[0].Exception.Response) 
        if($_.Exception.Response)
        {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $responseBody = $reader.ReadToEnd();
            throw "Status: A system exception was caught.`n $responsebody"
        }
        else
        {
            throw $_
        }

    }
   
}
#endregion
<#
.功能
	获取访问令牌

.描述
    使用client_credentials方法获取访问令牌调用Office 365 Graph API获取信息

.前提要求
	
    1. 注册应用
      登录https://portal.azure.cn 注册应用程序，记录应用程序ID，密钥，并分配应用程序权限
	  在应用上配置 Microsoft Graph 的权限。
	   示例配置需要的应用程序权限有：Read directory data/Send mail as any user
    2. 获取管理员同意。
    3. 获取访问令牌。
    4. 使用访问令牌调用 Microsoft Graph。  

.示例
	GraphAPIGetAccessTokenCode.ps1 -ClientId $clientId -ClientSecret $clientSecret -tenantId $tenantId
   
.注释
	版本:        1.0
	作者:        孙跃军
	创建时间:     2018-4-19  
  
.EXAMPLE
  connectTo-Graph.ps1

#>


#----------------------------------------------------------[Declarations]----------------------------------------------------------
#读取配置文件
#$config = Get-Content ".\config.json" -Raw | ConvertFrom-Json
#获取访问令牌
$accessTokenFile = ".\AccessTokenCode.txt"

$accessToken = ""

If (Test-Path -Path $accessTokenFile) {
	$accessToken = Get-Content $accessTokenFile
}
else {
    $accessToken = $null
}

$clientId = "d786bd1e-041b-4ccd-aa02-3f46c62e265c"
$secret = "WgRskLCnvCmgdwTNEF24eJoq7HWxSF4u+2XdOBsNI0c="
$resourceId = "https://microsoftgraph.chinacloudapi.cn"
$tenantId = "51o365.partner.onmschina.cn"
$secretEncoded = [System.Web.HttpUtility]::UrlEncode($secret)
    
# 检查访问令牌是否超过1小时重新获取新的访问令牌
If (($accessToken -eq $null) -or ((get-date) - (get-item $accessTokenFile).LastWriteTime).TotalHours -gt 1) 
{
	
    # 获取访问令牌，并保存
    $authCode = Get-AuthCode -ClientId $clientId -ClientSecret $secretEncoded -tenantId $tenantId
    Set-Content $accessTokenFile $authCode
	$accessToken = $authCode	
}


#Get user's information
Invoke-GraphRequest -Token $accessToken -url "$resourceId/v1.0/users/appuser@51o365.tk" -Method Get
#Invoke-GraphRequest -Token $accessToken -url "https://microsoftgraph.chinacloudapi.cn/v1.0/users" -Method Get
   
#Invoke-GraphRequest -Token $accessToken -url "$resourceId/v1.0/users?`$top=2" -Method Get

#(Invoke-GraphRequest -Token $accessToken -url "$resourceId/v1.0/users?`$filter=startswith(mail,'testuser')" -Method Get).value

$mailbody = get-content .\output.htm


#
#$mailbody
$body=@"
{
    "message": {
      "subject": "Meet for lunch?",
      "body": {
        "contentType": "HTML",
        "content": "$mailbody"
      },
      "toRecipients": [
        {
          "emailAddress": {
            "address": "sun.yuejun@oe.21vianet.com"
          }
        }
      ],
      "ccRecipients": [
        {
          "emailAddress": {
            "address": "13466745064@139.com"
          }
        }
      ]
    },
    "saveToSentItems": "false"
  }
"@
#$body
# create user

$headers = @{}
$headers.Add('Authorization','Bearer ' + $accessToken)
$headers.Add('Content-Type', "application/json")

$url = "$resourceId/v1.0/users/appuser@51o365.tk/sendMail"
$response = Invoke-WebRequest -Uri $url -Method Post -Body $Body -Headers $headers -UseBasicParsing


#Invoke-GraphRequest -Token $accessToken -url "$resourceId/v1.0/users/appuser@51o365.tk/sendMail" -Body $body -Method POST
