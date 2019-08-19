<#
.SYNOPSIS
    Get total number of Dropbox file requests.
.DESCRIPTION
    Cmdlet returns the total number of file requests owned by the user. This includes both
    open and closed file requests.
.EXAMPLE
    PS> Get-DropboxFileRequestCount -Token $Token
.NOTES
    API returns error about if the body is missing, also returns error if a null body is
    present...
#>
function Get-DropboxFileRequestCount {
    [CmdletBinding()]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")
        $Parameters = @{
            URI = "https://api.dropboxapi.com/2/file_requests/count"
            Method = "Post"
            Headers = $Header
            ContentType = "application/json"
        }
    }
    
    process {
        try {
            $Result = Invoke-RestMethod @Parameters
            Write-Output $Result
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
    Create a Dropbox file request.
.DESCRIPTION
    Cmdlet creates a Dropbox file request for this user.
.EXAMPLE
    PS> $Parameters = @{
            Token = $Token
            Title = "New File Request"
            Destination = "/new file request/"
            Open = $true
            Deadline = (Get-Date -Day 25 -Month 12 -Year 2019)
            GracePeriod = ''seven_days'
        }
    PS> New-DropboxFileRequest @Parameters

    Cmdlet creates a Dropbox file request that includes a deadline and grace period.
#>
function New-DropboxFileRequest {
    [CmdletBinding()]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token,
        # File Request Title
        [parameter(Mandatory)]
        [string]$Title,
        # Path of the folder in the Dropbox where uploaded files will be sent.
        [parameter(Mandatory)]
        [string]$Destination,
        # Wheather or not the file request should be open. 
        # If the file request is closed, it will not accept any file submissions but it can be opened later.
        # Defaults to $true
        [boolean]$Open = $true,
        # The deadline for the file request.
        # Can only be set by Professional and Business accounts.
        [datetime]$Deadline,
        # Allows uploads after the deadline has passed but will be marked overdue. 
        # This is only added if **Deadline** parameter is specified.
        [ValidateSet('one_day','two_days','seven_days','thirty_days','always')]
        [string]$GracePeriod
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")

        $Body = @{
            title = $Title
            destination = $Destination
            open = $Open
        }
        if ($Deadline) {
            $Body.add("deadline", @{"deadline" = $Deadline.ToString("yyyy-MM-ddTHH:mm:ssZ") })
            if ($GracePeriod) {
                $Body.deadline.Add("allow_late_uploads", $GracePeriod)
            }
        }
        $Parameters = @{
            URI = "https://api.dropboxapi.com/2/file_requests/create"
            Method = "Post"
            Headers = $Header
            ContentType = "application/json"
            Body = $Body | ConvertTo-Json
        }
    }
    
    process {
        try {
            $Result = Invoke-RestMethod @Parameters
            Write-Output $Result
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
    Delete a batch or all closed file requests.
.DESCRIPTION
    File request must be closed before removing! Use **Update-DropboxFileRequest** cmdlet to
    close specified file requests.

    Cmdlet will delete a specified batch of file request ids or all using the 
    **-AllClosed** parameter.
.EXAMPLE
    PS> Update-DropboxFileRequest -Token $Token -Id oaCAVmEyrqYnkZX9955Y -Open $false
    PS> Remove-DropboxFileRequest -Token $Token -Id oaCAVmEyrqYnkZX9955Y

    Example first closes the specified file request then removes it.
.EXAMPLE
    PS> Remove-DropboxFileRequest -Token $Token -Id "oaCAVmEyrqYnkZX9955Y","BaZmehYoXMPtaRmfTbSG"

    Cmdlet removes specified file request ids in one request.
.EXAMPLE
    PS> $FileRequests = @("oaCAVmEyrqYnkZX9955Y","BaZmehYoXMPtaRmfTbSG")
    PS> $FileRequests | Remove-DropboxFileRequest -Token $Token

    Cmdlet removes file requests one by one via pipeline.
.EXAMPLE
    PS> Remove-DropboxFileRequest -Token $Token -AllClosed

    Cmdlet removes all closed file requests.
#>
function Remove-DropboxFileRequest {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact="High",
        DefaultParameterSetName="Select"
    )]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token,
        # Ids of the file requests to delete.
        [parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Select"
        )]
        [string[]]$Id,
        # Wheather to delete all closed file requests owned by user.
        [parameter(ParameterSetName="All")]
        [switch]$AllClosed
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")
        $Parameters = @{
            URI = switch ($PSCmdlet.ParameterSetName) {
                "Select" {"https://api.dropboxapi.com/2/file_requests/delete"}
                "All" {"https://api.dropbox.api.com/2/file_requests/delete_all_closed"}
            }
            Method  = "Post"
            Headers = $Header
            ContentType = "application/json"
        }
    }
    
    process {
        # Add body containing file request id if specified or via pipeline
        if ($PSCmdlet.ParameterSetName -eq "Select") {
            $Parameters.Add("Body",(ConvertTo-Json -InputObject @{ids = @($Id)}))
        }
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
        # Remove body containing file request ids incase of pipeline
        if ($PSCmdlet.ParameterSetName -eq "Select") {
            $Parameters.Remove('Body')
        }
    }
    end {
    }
}

<#
.SYNOPSIS
    Get Dropbox file requests.
.DESCRIPTION
    Cmdlet will return a list of file requests owned by the user. If the **-Id** parameter is
    present, only specified file request will be returned.
.EXAMPLE
    PS> Get-DropboxFileRequest -Token $Token -Limit 100

    Cmdlet will return up-to 100 file requests. If response **has_more** property is true and 
    the **-Continue** switch parameter is specified, the cmdlet will paginate through all
    file requests.
.EXAMPLE
    PS> Get-DropboxFileRequest -Token $Token -Id oaCAVmEyrqYnkZX9955Y

    Cmdlet will return only the specified file request.
#>
function Get-DropboxFileRequest {
    [CmdletBinding(DefaultParameterSetName = "List")]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token,
        # Maximum number of file requests to return.
        [parameter(ParameterSetName = "List")]
        [int64]$Limit = 1000,
        # Weather to continue to receive data if limit has been reached.
        [parameter(ParameterSetName = "List")]
        [switch]$Continue,
        # The Id of the file request to retreive.
        [parameter(Mandatory, ParameterSetName = "Id")]
        [string]$Id
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")
        switch ($PSCmdlet.ParameterSetName) {
            "List" {
                $Url = "https://api.dropboxapi.com/2/file_requests/list_v2"
                $Body = @{limit = $Limit }
            }
            "Id" {
                $Url = "https://api.dropboxapi.com/2/file_requests/get"
                $Body = @{id = $Id }
            }
        }
        $Parameters = @{
            URI         = $Url
            Method      = "Post"
            Headers     = $Header
            ContentType = "application/json"
            Body        = $Body | ConvertTo-Json
        }
    }
    
    process {
        try {
            $Result = Invoke-RestMethod @Parameters
            Write-Output $Result.file_requests
            While ($Result.has_more -and $Continue.IsPresent) {
                Write-Verbose "Loading more data from cursor: $($Result.cursor)"
                $ContinueParameters = @{
                    URI         = "https://api.dropboxapi.com/2/file_requests/list/continue"
                    Method      = "Post"
                    Headers     = $Header
                    ContentType = "application/json"
                    Body        = @{cursor = $Result.cursor } | ConvertTo-Json
                }
                $Result = Invoke-RestMethod @ContinueParameters
                Write-Output $Result.file_requests
            }
        }
        catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    
    end {
    }
}

<#
.SYNOPSIS
    Update a file request.
.DESCRIPTION
    Cmdlet updates parameters on specified file request id.
.EXAMPLE
    PS> $Parameters = @{
            Token = $Token
            Id = "oaCAVmEyrqYnkZX9955Y"
            Title = "Homework submission"
            Destination = "/File Requests/Homework"
            Deadline = (Get-Date -Day 12 -Month 10 -Year 2020 -Hour 17)
            GracePeriod = 'seven_days'
            Open = $true
        }
    PS> Update-DropboxFileRequest @Parameters

    Cmdlet updates all file request parameters.
.EXAMPLE
    PS> Update-DropboxFileRequest -Token $Token -Id "oaCAVmEyrqYnkZX9955Y" -Open $false

    Cmdlet closes file request. File request can be deleted using the 
    **Remove-DropboxFileRequest** cmdlet.
#>
function Update-DropboxFileRequest {
    [CmdletBinding()]
    [Alias('Set-DropboxFileRequest')]
    param (
        # Dropbox API access token.
        [parameter(Mandatory)]
        [string]$Token,
        # File request id to update
        [parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id,
        # New file request title
        [string]$Title,
        # New path of the folder in the Dropbox where uploaded files will be sent.
        [string]$Destination,
        # Wheather or not the file request should be open. 
        # If the file request is closed, it will not accept any file submissions but it can be opened later.
        # Defaults to $true
        [boolean]$Open = $true,
        # The new deadline for the file request.
        # Can only be set by Professional and Business accounts.
        [datetime]$Deadline,
        # Allows uploads after the deadline has passed but will be marked overdue. 
        # This is only added if **Deadline** parameter is specified.
        [ValidateSet('one_day', 'two_days', 'seven_days', 'thirty_days', 'always')]
        [string]$GracePeriod
    )
    
    begin {
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization", "Bearer $Token")
        
        # Generate body
        $Body = @{id = $Id;open=$Open}
        if ($Title) {$Body.Add('title',$Title)}
        if ($Destination) {$Body.Add('destination',$Destination)}
        if ($Deadline) {
            $Body.add("deadline", @{".tag" = "update"; "deadline" = $Deadline.ToString("yyyy-MM-ddTHH:mm:ssZ") })
            if ($GracePeriod) {
                $Body.deadline.Add("allow_late_uploads", $GracePeriod)
            }
        } else {
            $Body.Add("deadline",@{".tag" = "no_update"})
        }

        $Parameters = @{
            URI = "https://api.dropboxapi.com/2/file_requests/update"
            Method = "Post"
            Headers = $Header
            ContentType = "application/json"
            Body = $Body | ConvertTo-Json
        }
    }
    
    process {
        try {
            $Result = Invoke-RestMethod @Parameters
            Write-Output $Result
        }
        catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    
    end {
    }
}