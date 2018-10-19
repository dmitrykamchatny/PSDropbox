<#
.SYNOPSIS
    Copy a file or folder.
.DESCRIPTION
    Copy a file or folder to a different location in user's Dropbox. If the source path is a folder all its contents will be copied.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-copy.
.EXAMPLE
    Copy-DropboxFile -Source /test.txt -Destination /PowerShell/test.txt -token <access token>

    Copies file test.txt to PowerShell folder.
.EXAMPLE
    Copy-DropboxFile -Source /test.txt -Destination /PowerShell/test.txt -SelectUser powershell@example.com

    Copies file test.txt to PowerShell folder on powershell@example.com team member' Dropbox folder.
#>
function Copy-DropboxFile {
    [cmdletbinding()]
    param(
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Path in the user's Dropbox to be copied.
        [parameter(Mandatory,Position=0)]
        [string]$Source,
        # Path in the user's Dropbox that is the destination.
        [parameter(Mandatory,Position=1)]
        [string]$Desntination,
        # Will copy contents in shared folder, otherwise RelocationError.cant_copy_shared_folder error will be returned.
        [switch]$AllowSharedFolder,
        # If there's a name conflict, Dropbox will try to autorename the file to avoid conflict.
        [switch]$AutoRename,
        # Allow moves by owner even if it would result in an ownership transfer.
        [switch]$AllowOwnershipTransfer,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/copy_v2"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{
        $Body = @{
            from_path=$Source
            to_path=$Desntination
            allow_shared_folder=$AllowSharedFolder.IsPresent
            autorename=$AutoRename.IsPresent
            allow_ownership_transfer=$AllowOwnershipTransfer.IsPresent
        }

        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.metadata
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    end{}
}

<#
.SYNOPSIS
    Create a folder in Dropbox
.DESCRIPTION
    Create a folder in Dropbox in specified path.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder.
.EXAMPLE
    New-DropboxFolder -Path "/PowerShell/Modules/Dropbox"
#>
function New-DropboxFolder {
    [cmdletbinding()]
    param(
        # Path in user's Dropbox to create
        [parameter(Mandatory)]
        [string]$Path,
        # If there's a name conflict, Dropbox will try to autorename the file to avoid conflict. 
        [switch]$AutoRename,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/create_folder_v2"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{

        $Body = @{
            path=$Path
            autorename=$AutoRename.IsPresent
        }

        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.metadata
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    end{}
}

<#
.SYNOPSIS
    Create multiple folders in Dropbox at once.
.DESCRIPTION
    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder_batch.
.EXAMPLE
    New-DropboxBatchFolder -Paths /Pictures,/Documents,/Videos

    Create folders "Pictures", "Documents", "Videos"
#>
function New-DropboxBatchFolder {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        # List of paths to be created in user's Dropbox. Duplicate arguments are considered only once.
        [string[]]$Paths,
        # If there's a name conflict, Dropbox will try to autorename the file to avoid conflict.
        [switch]$AutoRename,
        # Whether to force the create to happen asynchronously.
        [switch]$ForceAsync,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/create_folder_batch"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
        $NewFolders = New-Object System.Collections.ArrayList
    }
    process{
        foreach ($Path in $Paths){
            $NewFolders.Add($Path) | Out-Null
        }
        $Body = @{
            paths=@($NewFolders)
            autorename=$AutoRename.IsPresent
            force_async=$ForceAsync.IsPresent
        }
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.entries | Format-Table
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    end{}
}

<#
.SYNOPSIS
    Delete specified file or folder.
.DESCRIPTION
    If folder, all contents will be deleted too. Successful response indicates the file or folder was deleted.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-delete.
.EXAMPLE
    Remove-DropboxFile -Path /PowerShell.psm1

    Remove file PowerShell.psm1 in root folder.
#>
function Remove-DropboxFile {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="High")]
    param(
        # Path in the user's Dropbox to delete.
        [parameter(Mandatory)]
        [string]$Path,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/delete_v2"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{
        $Body = @{
            path=$Path
        }
        if ($PSCmdlet.ShouldProcess("$Path","Delete Dropbox file")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result.metadata
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
        }   
    }
    end{}
}

<#
.SYNOPSIS
    Delete multiple files or folders.
.DESCRIPTION
    Returns async_job_id, use Get-DropboxDeleteBatchStatus -AsyncJobId <async_job_id> for job status.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-delete_batch.
.EXAMPLE
    Remove-DropboxBatchFile -Paths /1,/2,/3,/4,/5

    Remove files or folders 1,2,3,4,5.
#>
function Remove-DropboxBatchFile {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="High")]
    param(
        # List of paths to delete in user's Dropbox.
        [parameter(Mandatory)]
        [string[]]$Paths,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/delete_batch"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
        $Entries = New-Object -TypeName System.Collections.ArrayList
    }
    process{
        foreach ($P in $Paths) {
            $Entries.Add(@{"path"=$P}) | Out-Null
        }

        $Body = @{
            entries=@($Entries)
        }
        if ($PSCmdlet.ShouldProcess("Dropbox","Delete specified paths")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result.async_job_id
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
        }
    }
    end{}
}

<#
.SYNOPSIS
    Get status of an delete_batch job.
.DESCRIPTION
    Return the status of each entry for asynchronous delete_batch jobs.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-delete_batch-check.
.EXAMPLE
    $AsyncJobID = Remove-DropboxBatchFile -Paths /1,/2,/3,/4,/5
    
    Get-DropboxDeleteBatchStatus -AsyncJobId $AsyncJobID

    Add async_job_id from Remove-DropboxBatchFile to variable $AsyncJobID and specify variable to AsyncJobID parameter/
#>
function Get-DropboxDeleteBatchStatus {
    [cmdletbinding()]
    param(
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # ID of the asynchronous job, this value is the response returned from Remove-DropboxBatchFile.
        [string]$AsyncJobId,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/delete_batch/check"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{
        $Body = @{
            async_job_id=$AsyncJobId
        }
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.entries
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    end{}
}

<#
.Synopsis
   Get contents of a folder.
.DESCRIPTION
   Return contents of a folder and optionally return media information, deleted files, shared members and mounted folders.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder.
.EXAMPLE
   Get-DropboxFolderList

   Get contents from root Dropbox folder.
.EXAMPLE
   Get-DropboxFolderList -Path /Pictures -IncludeMediaInfo

   Get contents from /Pictures folder and include media information.
.EXAMPLE
   Get-DropboxFolderList -Recursive

   Get contents from root Dropbox folder and content from child folders recursively.
#>
function Get-DropboxFolderList {
    [CmdletBinding()]
    Param(
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Dropbox path to list contents, default root folder.
        [string]$Path="",
        # Maximum number of results to return per request.
        [ValidateRange(1,2000)]
        [int32]$Limit="200",
        # List folder operations will be applied recursively to all subfolders. Response will contain contents of all subfolders.
        [switch]$Recursive,
        # Return media type and other media specific attributes.
        [switch]$IncludeMediaInfo,
        # Includes entries for files and folders that were deleted.
        [switch]$IncludeDeleted,
        # Include a flag for each file indicating whether or not the file has any explicit members.
        [switch]$IncludeHasExplicitSharedMembers,
        # Include entries under mounted folders which includes app folder, shared folder and team folder.
        [switch]$IncludeMountedFolders,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/files/list_folder'
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{

        $Body = @{
            path=$Path
            recursive=$Recursive.IsPresent
            include_media_info=$IncludeMediaInfo.IsPresent
            include_deleted=$IncludeDeleted.IsPresent
            include_has_explicit_shared_members=$IncludeHasExplicitSharedMembers.IsPresent
            include_mounted_folders=$IncludeMountedFolders.IsPresent
        }
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.entries
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    End{}
}

<#
.SYNOPSIS
    Get revisions of a Dropbox file.
.DESCRIPTION
    Returns Dropbox file revision entries. The Mode parameter must be specified to indicate if a file path or file id is to be used.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-list_revisions.
.EXAMPLE
    Get-DropboxFileRevision -Mode path -Path /Dropbox.psm1 -Limit 100

    Get up to 100 revision entries for file Dropbox.psm1
.EXAMPLE
    Get-DropboxFileRevision -Mode id -ID id:abcdefghijklmnop
    
    Get defualt 10 revision entries for file id id:abcdefghijklmnop
#>
function Get-DropboxFileRevision {
    [cmdletbinding()]
    param(
        # Path to Dropbox file you want to see revisions of.
        [parameter(ParameterSetName="Path",Mandatory)]
        [string]$Path,
        # File id of Dropbox file you want to see revisions of.
        [parameter(ParameterSetName="Id",Mandatory)]
        [string]$Id,
        # Specifies if file path or id is used.
        [parameter(Mandatory)]
        [validateset("path","id")]
        [string]$Mode="path",
        # Maximum number of revision entries to return default 10, max 100.
        [ValidateRange(1,100)]
        [int]$Limit=10,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/list_revisions"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{
        
        $Body = @{
            mode=$Mode
            limit=$Limit        
        }

        if ($Mode -eq "path") {
            $Body.Add("path",$Path)
        } else {
            $Body.Add("path",$Id)
        }


        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.entries
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    end{}
}

<#
.SYNOPSIS
    Move a file or folder.
.DESCRIPTION
    Move a file or folder to a new location in user's Dropbox. If the source path is a folder, all its contents will be moved.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-move.
.EXAMPLE
    Move-DropboxFile -Source /Source -Destination /Destination/Source

    Move Source Dropbox folder to Destination folder retaining the folder name "Source"
#>
function Move-DropboxFile {
    [cmdletbinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    param(
        # Path in the user's Dropbox to be moved.
        [parameter(Mandatory,Position=0)]
        [string]$Source,
        # Path in the user's Dropbox that is the destination.
        [parameter(Mandatory, Position=1)]
        [string]$Destination,
        # Allow to copy contents from shared folders.
        [switch]$AllowSharedFolder,
        # If there's a conflict, Dropbox will try to autorename the file to avoid conflict.
        [switch]$AutoRename,
        # Allow move even if it results in ownership transfer for content being moved.
        [switch]$AllowOwnerShipTransfer,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/move_v2"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{
        $Body = @{
            from_path=$Source
            to_path=$Destination
            allow_shared_folder=$AllowSharedFolder.IsPresent
            autorename=$AutoRename.IsPresent
            allow_ownership_transfer=$AllowOwnerShipTransfer.IsPresent
        }
        if ($PSCmdlet.ShouldProcess("$Destination","Move contents from $Source")){
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result.metadata
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
        }
    }
    end{}
}

<#
.SYNOPSIS
    Restore file.
.DESCRIPTION
    Restore a specific revision of a file to specified Dropbox path.

    Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-restore.
.EXAMPLE
    Restore-DropboxFileRevision -Path /restored.txt -Revision 123abcdefghi

    Restores file revision 123abcdefghi to file "restored.txt" in user's Dropbox root folder.
#>
function Restore-DropboxFileRevision {
    [cmdletbinding()]
    param(
        # Dropbox path to save restored file.
        [parameter(Mandatory)]
        [string]$Path,
        # The file revision to restore.
        [parameter(Mandatory)]
        [Alias("rev")]
        [string]$Revision,
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    begin{
        $URI="https://api.dropboxapi.com/2/files/restore"
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    process{
        $Body = @{
            path=$Path
            rev=$Revision
        }
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    end{}
}

<#
.Synopsis
   Search for a file or folder.
.DESCRIPTION
   Searches for a file or folder in specified Dropbox path.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#files-search.
.EXAMPLE
   Search-DropboxFile -Query "Dropbox Files.psm1"

   Searches entire Dropbox folder for Dropbox Files module.
.EXAMPLE
   Search-DropboxFile -Query "oops.docx" -Mode deleted_filename -Path /Documents

   Seraches Documents folder for deleted file named oops.docx
#>
function Search-DropboxFile {
    [CmdletBinding()]
    Param(
        # Dropbox API access token. Command can be run on behalf of team member (Requires Team member file acess token)
        [parameter(Mandatory,HelpMessage="Enter Dropbox API or Dropbox Business(Team member file access) access token")]
        [string]$Token,
        # Dropbox path to search, best to be a folder.
        [string]$Path="",
        # String to search for.
        [parameter(Mandatory)]
        [string]$Query,
        # Stating index within search results (used for paging).
        [int]$Start=0,
        # Maximumum number of search results to return.
        [ValidateRange(1,1000)]
        [int]$MaxResults=100,
        # Search mode. Note that searching file content is only available for Dropbox Business accounts.
        [validateset("filename","filename_and_content","deleted_filename")]
        [string]$Mode="filename",
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/files/search'
        $Header = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
        $Header.Add("Authorization","Bearer $Token")
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        $Body = @{
            path=$Path
            query=$Query
            start=$Start
            max_results=$MaxResults
            mode=$Mode
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.matches.metadata | Select-Object .tag,name,path_display,size,id
            if ($Result.more -eq $true) {
                Write-Output "More results are available"
            }
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    End{}
}

<#
.Synopsis
   Get metadata for file or folder.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-DropboxFileMetadata {
    [CmdletBinding()]
    Param(
        # Dropbox file path.
        [parameter(Mandatory,ParameterSetName="FilePath")]
        [string]$Path,
        # Dropbox file id.
        [parameter(Mandatory,ParameterSetName="FileId")]
        [string]$Id,
        # Dropbox file revision id.
        [parameter(Mandatory,ParameterSetName="FileRevision")]
        [string]$Revision,
        # Media info for photo and videos.
        [switch]$IncludeMediaInfo,
        # Include deleted files or folders.
        [switch]$IncludeDeleted,
        # Include flag if file has explicit members.
        [switch]$IncludeHasExplicitSharedMembers,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/files/get_metadata'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberId = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        if ($Path) {
            $File = $Path
        }
        if ($Id) {
            $File = $Id
        }
        if ($Revision) {
            $File = $Revision
        }
        $Body = @{
            path=$File
            include_media_info=$IncludeMediaInfo.IsPresent
            include_deleted=$IncludeDeleted.IsPresent
            include_has_explicit_shared_members=$IncludeHasExplicitSharedMembers.IsPresent
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