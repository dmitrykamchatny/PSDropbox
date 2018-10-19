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
        [string]$Path="$env:USERPROFILE\Documents\DropboxTokens.json",
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

<#
.SYNOPSIS
    Get returned Dropbox Error
.DESCRIPTION
    Currently the Invoke-RestMethod command error response doesn't show the actual response received from Dropbox.

    The catch code block includes the line "$ResultError = $_.Exception.Response.GetResponseStream()" to get the response stream then passes it to this cmdlet to read.
.EXAMPLE
    Get-DropboxError -Result $ResultError
#>
function Get-DropboxError {
    [cmdletbinding()]
    param(
        $Result
    )

    begin{
        $Reader = New-Object System.IO.StreamReader($Result)
    }
    process{
        $Reader.BaseStream.Position = 0
        $Reader.DiscardBufferedData()
        $DropboxError = ($Reader.ReadToEnd())
    }
    end{
        Write-Output $DropboxError
    }
}
