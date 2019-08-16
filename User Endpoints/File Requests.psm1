<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
#>
function Get-DropboxFileRequestList {
    [CmdletBinding()]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token,
        # Maximum number of file requests to return.
        [int64]$Limit = 1000,
        # Weather to continue to receive data if limit has been reached.
        [switch]$Continue
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")
        $Parameters = @{
            URI = "https://api.dropboxapi.com/2/file_requests/list_v2"
            Method = "Post"
            Headers = $Header
            ContentType = "application/json"
            Body = @{limit=$Limit} | ConvertTo-Json
        }
    }
    
    process {
        try {
            $Result = Invoke-RestMethod @Parameters
            Write-Output $Result.file_requests
            While ($Result.has_more -and $Continue.IsPresent) {
                Write-Verbose "Loading more data from cursor: $($Result.cursor)"
                $ContinueParameters = @{
                    URI = "https://api.dropboxapi.com/2/file_requests/list/continue"
                    Method = "Post"
                    Headers = $Header
                    ContentType = "application/json"
                    Body = @{cursor=$Result.cursor} | ConvertTo-Json
                }
                $Result = Invoke-RestMethod @ContinueParameters
                Write-Output $Result.file_requests
            }
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    
    end {
    }
}

<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
#>
function Remove-DropboxFileRequest {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token,
        # Ids of the file requests to delete.
        [parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string[]]$Id
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")
        $Parameters = @{
            URI = "https://api.dropboxapi.com/2/file_requests/delete"
            Method  = "Post"
            Headers = $Header
            ContentType = "application/json"
        }
    }
    
    process {
        $Parameters.Add("Body",(ConvertTo-Json -InputObject @{ids = @($Id)}))
        Write-Output $Parameters.Body
        if ($PSCmdlet.ShouldProcess("File Request",$Id -join ",")) {
            try {
                $Result = Invoke-RestMethod @Parameters
                Write-Output $Result.file_requests
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
        }
        $Parameters.Remove('Body')
    }
    end {
    }
}