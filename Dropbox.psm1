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
        # Invoke-RestMethod error stream.
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
function Get-DropboxAccount {
    [CmdletBinding()]
    Param(
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/users/get_current_account'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = $null
        try {
            $Result = Invoke-RestMethod -Uri $URI -ContentType "application/json" -Method Post -Body "null" -Headers $Header
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    End{}
}