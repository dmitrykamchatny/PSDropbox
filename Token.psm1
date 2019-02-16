<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Request-DropboxAccessToken {
    [CmdletBinding()]
    Param(
        # App key found in https://www.dropbox.com/developers/apps.
        [parameter(Mandatory)]
        [string]$ClientId,
        # Where to redirect user after authorization has completed. The redirect uri must be specified in Dropbox API app.
        [parameter(Mandatory)]
        [string]$RedirectUri,
        # Dropbox API permission type.
        # Team Information - Information about team and aggregate usage data.
        # Team Auditing - Team information and team's detailed activity log.
        # Team Member File Access - Team Information and Auditing. Allows ability to perform acny action as a member.
        # Team Member Management - Team Information and ability to add, edit and delete team members.
        [parameter(Mandatory)]
        [validateset("TeamMemberManagement","TeamInformation","TeamAuditing","TeamMemberFileAccess","Personal")]
        [string]$Permission
    )

    Begin{
        $ResponseType="token"
        $URI='https://www.dropbox.com/oauth2/authorize/?response_type={0}&client_id={1}&redirect_uri={2}' -f @(
            $ResponseType
            $ClientId
            $RedirectUri
        )
        $InternetExplorerProperties = @{
            Height=680
            Width=480
            Resizable = $false
            AddressBar=$false
            visible=$true
        }
        $Object = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"

    }
    Process{
        $InternetExplorer = New-Object -ComObject InternetExplorer.Application -Property $InternetExplorerProperties
        $InternetExplorer.Navigate($URI)
        while (-not ($InternetExplorer.LocationURL -match "access_token")) {
            Start-Sleep -Seconds 1
        }
        $Result = $InternetExplorer.LocationURL.Replace("$($RedirectUri)#",'') -split '&'
        $InternetExplorer.Quit()

        $Result | foreach {
            $Key,$Value = $_ -split "="
            $Object.Add($Key,$Value)
        }
        if ($Object.Keys -contains "team_id") {
            $Token = [pscustomobject]@{
                PSTypeName="Dropbox.Oauth.AccessToken"
                Permission=$Permission
                TokenType=$Object.token_type
                AccessToken=$Object.access_token
                UID=$Object.uid
                TeamId=$Object.team_id
            }
        } else {
            $Token = [pscustomobject]@{
                PSTypeName="Dropbox.Oauth.AccessToken"
                Permission=$Permission
                TokenType=$Object.token_type
                AccessToken=$Object.access_token
                UID=$Object.uid
                AccountId=$Object.account_id
            }
        }
        Write-Output $Token
    }
    End{}
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function New-DropboxTokenFile {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias()]
    Param(
        [PSTypeName("Deserialized.Dropbox.Oauth.AccessToken")]$TeamMemberManagement,
        [PSTypeName("Deserialized.Dropbox.Oauth.AccessToken")]$TeamMemberFileAccess,
        [PSTypeName("Deserialized.Dropbox.Oauth.AccessToken")]$TeamInformation,
        [PSTypeName("Deserialized.Dropbox.Oauth.AccessToken")]$TeamAuditing,
        [PSTypeName("Deserialized.Dropbox.Oauth.AccessToken")]$Personal,
        [string]$Path='$env:USERPROFILE\Documents\DropboxTokens.xml'
    )

    Begin{
    }
    Process{
        $AllObjects = $TeamMemberManagement,$TeamMemberFileAccess,$TeamInformation,$TeamAuditing,$Personal
        if (Test-Path -Path $Path) {
            Write-Warning "Dropbox token file already exists!"
        } else {
            $AllObjects | Export-Clixml -Path $Path
        }
    }
    End{}
}

<#
.SYNOPSIS
    Get Dropbox API access token.
.DESCRIPTION
    Cmdlet retrieves Dropbox API access from DropboxTokens.json file in user's Documents folder (default) or specified file.
    All cmdlets in the Dropbox module require a Token parameter and this cmdlet was created to make it easier.
    If Permission parameter is entered, the cmdlet will output the token for specified permission level.
.EXAMPLE
    $Token = Get-DropboxToken

    Gets all tokens from $env:USERPROFILE\Documents\DropboxTokens.json file and assigns values to variable $Token.
.EXAMPLE
    Get-DropboxToken -Permission TeamInformation

    Gets TeamInformation token value.
.EXAMPLE
    Get-DropboxToken -Path C:\DropboxTokens.json

    Get all tokens from C:\DropboxTokens.json file.
#>
function Get-DropboxToken {
    [cmdletbinding()]
    param(
        # Path to retreive json token file.
        [string]$Path="$env:USERPROFILE\Documents\DropboxTokens.json",
        # Required permission level.
        [validateset("TeamMemberManagement","TeamInformation","TeamAuditing","TeamMemberFileAccess","Personal")]
        [string]$Permission
    )
    begin{}
    process{
        if (Test-Path -Path $Path) {
            $Tokens = Get-Content -Path $Path | ConvertFrom-Json
            if ($Permission) {
                Write-Output ($Tokens | Where-Object Name -EQ $Permission).token
            } else {
                Write-Output $Tokens
            }
        } else {
            Write-Warning "File not found: $Path"
            if ((Read-Host "Generate new DropboxToken file?(y/n)") -like "y") {
                New-DropboxTokenFile
            }
        }
    }
    end{}
}

<#
.SYNOPSIS
    Create a Dropbox token file.
.DESCRIPTION
    Create a json file containing Dropbox tokens for each permission level and a personal token. User must enter appropriate access token when prompted.
.EXAMPLE
    New-DropboxTokenfile -Path C:\DropboxTokens.json

    Generates token file C:\DropboxTokens.json containing tokens for all permission levels.
.EXAMPLE
    New-DropboxTokenFile -TokenName Personal

    Generates $env:USERPROFILE\Documents\DropboxTokens.json file containing personal access token only.
#>
function New-DropboxTokenFile {
    [cmdletbinding()]
    param(
        # Path to export json token file.
        [string]$Path="$env:USERPROFILE\Documents\DropboxTokens.json",
        [validateset("TeamMemberManagement","TeamInformation","TeamAuditing","TeamMemberFileAccess")]
        [string[]]$TokenName=@("TeamMemberManagement","TeamInformation","TeamAuditing","TeamMemberFileAccess","Personal")
    )

    begin{
        $Tokens = @()
    }

    process {
        foreach ($T in $TokenName) {
            $Object = [PSCustomObject]@{
                Name=$T
                Token=Read-Host -Prompt "Enter $T access token"
            }
            $Tokens += $Object
        }
        
        Write-Output $Tokens
        Write-Output "File output: $Path"
        ConvertTo-Json -InputObject $Tokens | Out-File -FilePath $Path
    }

    end{}
}