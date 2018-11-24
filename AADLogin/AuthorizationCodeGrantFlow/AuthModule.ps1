#region 获取授权码
Function Get-AuthCode($url)
{
		Add-Type -AssemblyName System.Windows.Forms

		$form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
		$web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url -f ($Scope -join "%20")) }

		$DocComp  = {
			$Global:uri = $web.Url.AbsoluteUri        
			if ($Global:uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
		}
		$web.ScriptErrorsSuppressed = $true
		$web.Add_DocumentCompleted($DocComp)
		$form.Controls.Add($web)
		$form.Add_Shown({$form.Activate()})
		$form.ShowDialog() | Out-Null

		$queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
		$output = @{}
		foreach($key in $queryOutput.Keys){
			$output["$key"] = $queryOutput[$key]
      }

    return $queryOutput["code"]  
}
#endregion

#region 获取访问令牌
function GetAccessToken($config)
{
    
    #读取配置文件
    $config = Get-Content $config -Raw | ConvertFrom-Json

    # 引入系统组件
    Add-Type -AssemblyName System.Web

    $env:appFolder = $pwd

    $env:accessTokenFile = "$pwd\AccessToken.txt"
    $env:refreshToken = "$pwd\RefreshToken.txt"
    $env:AuthCode = "$pwd\AuthCode.txt" 
      # 获取AccessToken
    If (Test-Path -Path $env:accessTokenFile) {
	    $accessToken = Get-Content $env:accessTokenFile
    }
    else {
        $accessToken = $null
    }

   
    # 检查AccessToken是否过期，默认为1小时
    If (($accessToken -eq $null) -or ((get-date) - (get-item $env:accessTokenFile).LastWriteTime).TotalHours -gt 1) 
    {

        # 获取Refresh Token
        If (Test-Path -Path $env:refreshToken) 
        {
	        $refreshToken = Get-Content $env:refreshToken
        }

        $clientId = $config.AppId.ClientId
        $clientSecret = $config.AppId.clientSecret
    
        $secretEncoded = [System.Web.HttpUtility]::UrlEncode($clientSecret)
        $redirectUrl = $config.AppId.RedirectUrl
        $resourceUrl = $config.AppId.ResourceUrl

            Try 
            {
                $refreshBody = "grant_type=refresh_token&redirect_uri=$redirectUrl&client_id=$clientId&client_secret=$secretEncoded&refresh_token=$refreshToken&resource=$resourceUrl"
            
                $Authorization = Invoke-RestMethod https://login.chinacloudapi.cn/common/oauth2/token `
                    -Method Post -ContentType "application/x-www-form-urlencoded" `
                    -Body $refreshBody `
                    -UseBasicParsing
            }
            Catch 
            {
                $webResponse = $_.Exception.Response
                Write-Host "No refresh Token Found!\r\n Request Authorization Code" -ForegroundColor Yellow
            }
         

	    If ($webResponse -ne $null) {
		    # Get Authorization code
	        
            $url = "https://login.chinacloudapi.cn/common/oauth2/authorize?response_type=code&redirect_uri=$redirectUrl&client_id=$clientID"

            #$url

            $authCode = Get-AuthCode -url $url

            #$authCode
            # Store AuthCode
            Set-Content $env:AuthCode $authCode

            $secretEncoded = [System.Web.HttpUtility]::UrlEncode($clientSecret)
		    $body = "grant_type=authorization_code&redirect_uri=$redirectUrl&client_id=$clientId&client_secret=$secretEncoded&code=$authCode&resource=$resourceUrl"

		    $Authorization = Invoke-RestMethod https://login.chinacloudapi.cn/common/oauth2/token -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
	    }

	    # 保存 refreshToken
	    Set-Content $env:refreshToken $Authorization.refresh_token

	    # Store accessToken
	    $accessToken = $Authorization.access_token
	    Set-Content $env:accessTokenFile $accessToken
    }
    else
    {
        Write-Host "Access Token Found! \r\n Skipped Get Access Token" -ForegroundColor Green
    }
}
#endregion

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
