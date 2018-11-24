
function ListUsers ($upn) 
{
    
    if ($upn -eq $null)
    {
        $url = "$ResourceID/v1.0/users"    
    }
    else {
        $url = "$ResourceID/v1.0/users/$upn"    
    }
    
    
    Invoke-GraphRequest -Token $accessToken -url $url -Method Get

   
}

function ListUserByUPN {
    param (
        $upn
    )

    $url = "$ResourceID/v1.0/users?`$filter=userPrincipalName eq '$upn'"

    Invoke-GraphRequest -Token $accessToken -url $url -Method Get
   
}

function User_Update {
    param (
        $header,$body,$upn
    )

    $url = $resourceId+ "/v1.0/users/$upn"

    $Response=Invoke-WebRequest -Method Patch -Uri $url -Header $headers -Body $body -ErrorAction Stop

}

#region 创建用户
function CreateUser {
    param (
        $upn
    )

if($upn -eq $null)
{
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
    }
    else {

        

        $username = $upn.Substring(0,$upn.IndexOf("@"))

$body=@"
{

        "accountEnabled": true,
        "displayName": "$username",
        "mailNickname": "$username",
        "userPrincipalName": "$upn",
        "passwordProfile" : {
          "forceChangePasswordNextSignIn": false,
          "password": "P@ssw0rd!"
        }
      
  }
"@
    }

# create user
# $Response=Invoke-WebRequest -Method Post -Uri ("$ResourceId/v1.0/users") -Header $headers -Body $body -ErrorAction Stop
# $t=ConvertFrom-Json $Response.Content
# ListUsers $t.userPrincipalName


Invoke-GraphRequest -Token $accessToken -url "$ResourceId/v1.0/users" -Method Post -Body $body

}
#endregion

# 删除用户
function DeleteUser ($upn) {
    
    if($upn -eq $null)
    {
        return "Error"
    }

    Invoke-GraphRequest -Token $accessToken -url "$ResourceId/v1.0/users/$upn" -Method Delete

}



function GetUserInfo {
   
    $url = "$ResourceId/v1.0/me"

    $responseObject = Invoke-GraphRequest -Token $accessToken -url $url -Method Get

    return $responseObject
    }
