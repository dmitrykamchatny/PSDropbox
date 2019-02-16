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
function Archive-DropboxDoc {
    [CmdletBinding()]
    Param(
        # Paper doc id.
        [parameter(Mandatory)]
        [string]$DocId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/paper/docs/archive'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            doc_id=$DocId
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    End{
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
function New-DropboxDoc {
    [CmdletBinding()]
    Param(
        # Format of provided data.
        [parameter(Mandatory)]
        [ValidateSet("html","markdown","plain_text")]
        [string]$InputFormat,
        # File to copy contents for new doc.
        [parameter(Mandatory)]
        [string]$InputFile,
        # Paper folder id where Paper document should be created.
        [string]$ParentFolderId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/paper/docs/create'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            import_format=$InputFormat
        }
        if ($PaperFolderId) {
            $Body.Add("parent_folder_id","$ParentFolderId")
        }
        $Header.Add("Dropbox-API-Arg",($Body| ConvertTo-Json -Compress))

        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/octet-stream" -Headers $Header -InFile $InputFile
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
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
function Get-DropboxDoc {
    [CmdletBinding()]
    Param(
        # Paper doc id.
        [parameter(Mandatory)]
        [string]$DocId,
        # Desired export format of Paper doc.
        [ValidateSet("html","markdown")]
        [string]$ExportFormat="html",
        # Output file path.
        [parameter(Mandatory)]
        [string]$OutFile,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/paper/docs/download'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        $Body = @{
            doc_id=$DocId
            export_format=$ExportFormat
        }
        $Header.Add("Dropbox-API-Arg",($Body | ConvertTo-Json -Compress))

        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/octet-stream" -Headers $Header -OutFile $OutFile
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
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
function Get-DropboxDocList {
    [CmdletBinding()]
    Param(
        # Specify how Paper docs should be filtered.
        [ValidateSet("docs_accessed","docs_created")]
        [string]$FilterBy="docs_created",
        # Specify how Paper docs should be sorted.
        [ValidateSet("accessed","modified","created")]
        [string]$SortBy="modified",
        # Specify how results will be ordered.
        [ValidateSet("ascending","descending")]
        [string]$SortOrder="ascending",
        # Maximum number of docs to return per call.
        [ValidateRange(1,1000)]
        [int]$Limit=100,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/paper/docs/list'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            filter_by=$FilterBy
            sort_by=$SortBy
            sort_order=$SortOrder
            limit=$Limit
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
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
function Remove-DropboxDoc {
    [CmdletBinding()]
    Param(
        # Paper doc id.
        [parameter(Mandatory)]
        [string]$DocId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/paper/docs/permanently_delete'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        $Body = @{
            doc_id=$DocId
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
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
function Update-DropboxDoc {
    [CmdletBinding()]
    Param(
        # Paper doc id.
        [parameter(Mandatory)]
        [string]$DocId,
        # Policy used for current update call.
        [ValidateSet("append","prepend","overwrite_all")]
        [string]$UpdatePolicy="append",
        # Latest doc version.
        [parameter(Mandatory)]
        [int64]$Revision,
        # Format of provided data.
        [parameter(Mandatory)]
        [ValidateSet("html","markdown","plain_text")]
        [string]$ImportFormat,
        # File to copy contents from for new doc.
        [parameter(Mandatory)]
        [string]$InputFile,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/paper/docs/update'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        $Body = @{
            doc_id=$DocId
            doc_update_policy=$UpdatePolicy
            revision=$Revision
            import_format=$InputFormat
        }
        $Header.Add("Dropbox-API-Arg",($Body | ConvertTo-Json -Compress))
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/octet-stream" -Headers $Header -InFile $InputFile
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    End{}
}