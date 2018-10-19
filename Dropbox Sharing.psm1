<#
.Synopsis
   Add specific members to a file.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Add-DropboxFileMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")]
    Param(
        # File path to resolve file id.
        [parameter(Mandatory,ParameterSetName="FilePath")]
        [string]$Path,
        # File id to add members to.
        [parameter(Mandatory,ParameterSetName="FileId")]
        [string]$FileId,
        # Members' email addresses to add to file.
        [ValidateLength(1,255)]
        [string[]]$MemberEmail,
        # Dropbox account, team member or group id.
        [string[]]$DropboxId,
        # Message to send to added members in their invitation,
        [string]$CustomMessage,
        # Whether added members should be notified via device notifications of their invitation.
        [switch]$Quiet,
        # Access level new members will recieve for file.
        [parameter(Mandatory)]
        [ValidateSet("viewer_no_comment","viewer","editor","owner")]
        [string]$AccessLevel,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/add_file_member'
        $Header=@{"Authorization"="Bearer $Token"}
        $Members = New-Object -TypeName System.Collections.ArrayList
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{

        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "file") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $File = $Resolve.shared_folder_id
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "File not found: $Path"
            } else {
                Write-Warning "Specified path is not a file, use Add-DropboxFolderMember instead."
            }
        }
        if ($FileId) {
            $File = $FileId
        }

        foreach ($Address in $MemberEmail) {
            $Members.Add(@{".tag"="email";email=$Address}) | Out-Null
        }
        foreach ($Id in $DropboxId) {
            $Members.Add(@{".tag"="dropbox_id";dropbox_id=$Id}) | Out-Null
        }
        $Body = @{
            file=$File
            members=$Members
            quiet=$Quiet.IsPresent
            access_level=$AccessLevel
        }

        if ($CustomMessage) {
            $Body.Add("custom_message",$CustomMessage) | Out-Null
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
.SYNOPSIS
   Add specific members to a folder.
.DESCRIPTION
.EXAMPLE
#>
function Add-DropboxFolderMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")]
    Param(
        # Folder path to resolve folder id.
        [parameter(Mandatory,ParameterSetName="FolderPath")]
        [string]$Path,
        # Folder id to add members to.
        [parameter(Mandatory,ParameterSetName="FolderId")]
        [string]$SharedFolderId,
        # Members' email addresses to add to file.
        [ValidateLength(1,255)]
        [string[]]$MemberEmail,
        # Dropbox account, team member or group id.
        [string[]]$DropboxId,
        # Message to send to added members in their invitation,
        [string]$CustomMessage,
        # Whether added members should be notified via device notifications of their invitation.
        [switch]$Quiet,
        # Access level new members will recieve for file.
        [parameter(Mandatory)]
        [ValidateSet("viewer_no_comment","viewer","editor","owner")]
        [string]$AccessLevel,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/add_folder_member'
        $Header=@{"Authorization"="Bearer $Token"}
        $Members = New-Object -TypeName System.Collections.ArrayList
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{

        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "folder") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $Folder = $Resolve.shared_folder_id
                } else {
                    Write-Warning "Folder not shared, use New-DropboxSharedFolder"
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "Folder not found: $Path"
            } else {
                Write-Warning "Specified path is not a folder, use Add-DropboxFileMember instead."
            }
        }
        if ($SharedFolderId) {
            $Folder = $SharedFolderId
        }

        foreach ($Address in $MemberEmail) {
            $Members.Add(@{member=@{".tag"="email";email=$Address};access_level=$AccessLevel}) | Out-Null
        }
        foreach ($Id in $DropboxId) {
            $Members.Add(@{member=@{".tag"="dropbox_id";dropbox_id=$Id};access_level=$AccessLevel}) | Out-Null
        }
        $Body = @{
            shared_folder_id=$Folder
            members=$Members
            quiet=$Quiet.IsPresent
        }

        if ($CustomMessage) {
            $Body.Add("custom_message",$CustomMessage) | Out-Null
        }
        if ($PSCmdlet.ShouldProcess("Folder: $Folder", "Add users $($Members.member.email)")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body -Depth 3)
                Write-Output "Succesfully shared folder"
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
        }
    }
    End{}
}

<#
.Synopsis
   List shared file members.
.DESCRIPTION
   Get list of members invited to a file, both inherited and uninherited members.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-DropboxFileMember {
    [CmdletBinding()]
    Param(
        # File path to resolve file id.
        [parameter(Mandatory,ParameterSetName="FilePath")]
        [string]$Path,
        # File id to add members to.
        [parameter(Mandatory,ParameterSetName="FileId")]
        [string]$FileId,
        # Whether to include members who only have access from parent shared folder.
        [switch]$IncludeInherited,
        # Number of members to return per query.
        [ValidateRange(1,300)]
        [int]$Limit=100,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/list_file_members'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "file") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $File = $Resolve.shared_folder_id
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "File not found: $Path"
            } else {
                Write-Warning "Specified path is not a file, use Add-DropboxFolderMember instead."
            }
        }
        if ($FileId) {
            $File = $FileId
        }
        $Body = @{
            file=$File
            include_inherited=$IncludeInherited.IsPresent
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
    End{
    }
}

<#
.Synopsis
   Get shared folder members.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-DropboxFolderMember {
    [CmdletBinding()]
    Param(
        # Folder path to resolve folder id.
        [parameter(Mandatory,ParameterSetName="FolderPath")]
        [string]$Path,
        # Folder id to add members to.
        [parameter(Mandatory,ParameterSetName="FolderId")]
        [string]$SharedFolderId,
        # Return if members can perform the following actions.
        # leave_a_copy: Allow the member to keep a copy of the folder when removing.
        # make_editor: Make the member an editor of the folder.
        # make_owner: Make the member an owner of the folder.
        # make_viewer" Make the member a viewer of the folder.
        # make_viewer_no_comment: Make the member a viewer of the folder without commenting permissions.
        # remove: Remove the member from the folder. 
        [ValidateSet("leave_a_copy","make_editor","make_owner","make_viewer","make_viewer_no_comment","remove")]
        [string[]]$Actions,
        # Number of results to return
        [ValidateRange(1,1000)]
        [int]$Limit=100,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/list_folder_members'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "folder") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $Folder = $Resolve.shared_folder_id
                } else {
                    Write-Warning "Folder not shared, use New-DropboxSharedFolder"
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "Folder not found: $Path"
            } else {
                Write-Warning "Specified path is not a folder, use Add-DropboxFileMember instead."
            }
        }
        if ($SharedFolderId) {
            $Folder = $SharedFolderId
        }

        $Body = @{
            shared_folder_id=$Folder
            limit=$Limit
        }
        if ($Actions) {
            $ActionList = New-Object System.Collections.ArrayList
            foreach ($Action in $Actions) {
                $ActionList.Add($Action)
            }
            $Body.Add("actions",$ActionList)
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
function Get-DropboxSharedFolderList {
    [CmdletBinding()]
    Param(
        # Number of results to return per call.
        [ValidateRange(1,1000)]
        [int]$Limit=100,
        # Actions that may be taken on shared folders.
        # change_options: Change folder options, such as who can be invited to join the folder.
        # disable_viewer_info : Disable viewer information for this folder.
        # edit_contents: Change or edit contents of the folder.
        # enable_viewer_info : Enable viewer information on the folder.
        # invite_editor: Invite a user or group to join the folder with read and write permission.
        # invite_viewer: Invite a user or group to join the folder with read permission.
        # invite_viewer_no_comment: Invite a user or group to join the folder with read permission but no comment permissions.
        # relinquish_membership: Relinquish one's own membership in the folder.
        # unmount: Unmount the folder.
        # unshare: Stop sharing this folder.
        # leave_a_copy: Keep a copy of the contents upon leaving or being kicked from the folder.
        # create_link: Create a shared link for folder.
        # set_access_inheritance: Set whether the folder inherits permissions from its parent. 
        [ValidateSet("change_options","disable_viewer","edit_contents","enable_viewer","invite_editor","invite_viewer","invite_viewer_no_comment","relinquish_membership","unmount","unshare","leave_a_copy","create_link","set_access_inheritance")]
        [string[]]$Actions,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/list_folders'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        $Body = @{
            limit=$Limit
        }

        if ($Actions) {
            $ActionList = New-Object System.Collections.ArrayList
            foreach ($Action in $Actions) {
                $ActionList.Add($Action)
            }
            $Body.Add("actions",$ActionList)
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
.Synopsis
   Share a folder with collaborators.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function New-DropboxSharedFolder {
    [CmdletBinding()]
    Param(
        # Dropbox folder path to share. If folder doesn't exist, a new folder will be created.
        [parameter(Mandatory)]
        [string]$Path,
        # Who can add and remove members on shared folder.
        # Owner: Only the owner can update the ACL.
        # Editors: Any editor can update the ACL.
        [ValidateSet("owner","editors")]
        [string]$UpdatePolicy,
        # Whether to force the sare to happen asynchronously.
        [switch]$ForceAsync,
        # Who can be a member of shared folder. Only applicable if user is on a team.
        # team: Only a teammate can become a member.
        # anyone: Anyone can become a member.
        [ValidateSet("team","anyone")]
        [string]$MemberPolicy,
        # Policy to apply to shared links. Only applicable if user is on a team.
        [ValidateSet("anyone","team","members")]
        [string]$SharedLinkPolicy,
        # Who can enable/disable viewer info for shared folder.
        [ValidateSet("enabled","disabled")]
        [string]$ViewerInfoPolicy,
        # Access inheritance settings for shared folder.
        [Parameter(Mandatory)]
        [ValidateSet("inherit","no_inherit")]
        [string]$AccessInheritance,
        # List of folder actions user can perform on shared folder.
        # change_options: Change folder options, such as who can be invited to join the folder.
        # disable_viewer_info: Disable viewer information for this folder.
        # edit_contents: Change or edit contents of the folder.
        # enable_viewer_info: Enable viewer information on the folder.
        # invite_editor: Invite a user or group to join the folder with read and write permission.
        # invite_viewer: Invite a user or group to join the folder with read permission.
        # invite_viewer_no_comment: Invite a user or group to join the folder with read permission but no comment permission.
        # relinquish_membership: Relinquish one's own membership in the folder.
        # unmount: Unmount the folder.
        # unshare: Stop sharing this folder.
        # leave_a_copy: Keep a copy of the contents upon leaving or being kicked from the folder.
        # create_link: Create a shard link for folder.
        # set_access_inheritance: Set whether the folder inherits permissions from its parent.
        [ValidateSet("change_options","disable_viewer_info","edit_contents","enable_viewer_info","invite_editor","invite_viewer","invite_viewer_no_comment","relinquish_membership","unmount","unshare","leave_a_copy","create_link","set_access_inheritance")]
        [string[]]$Actions,
        # Settings on the link for shared folder.
        $LinkSettings,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/share_folder'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        $Body = @{
            path=$Path
            force_async=$ForceAsync.IsPresent
        }
        if ($UpdatePolicy) {
            $Body.Add("acl_update_policy",$UpdatePolicy)
        }
        if ($MemberPolicy) {
            $Body.Add("member_policy",$MemberPolicy)
        }
        if ($SharedLinkPolicy) {
            $Body.Add("shared_link_policy",$SharedLinkPolicy)
        }
        if ($ViewerInfoPolicy) {
            $Body.Add("viewer_info_policy",$ViewerInfoPolicy)
        }
        if ($AccessInheritance) {
            $Body.Add("access_inheritance",$AccessInheritance)
        }
        if ($Actions) {
            $ActionList = New-Object System.Collections.ArrayList
            foreach ($Action in $Actions) {
                $ActionList.Add($Action)
            }
            $Body.Add("actions",$ActionList)
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
   Transfer folder ownership.
.DESCRIPTION
   Transfer ownership of a shared folder to a member of the shared folder.
   User must have folder owner access to perform transfer.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Grant-DropboxFolderOwnership {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    Param(
        # Folder path to resolve folder id.
        [parameter(Mandatory,ParameterSetName="FolderPath")]
        [string]$Path,
        # Folder id to add members to.
        [parameter(Mandatory,ParameterSetName="FolderId")]
        [string]$SharedFolderId,
        # Dropbox account or team_member_id 
        [parameter(Mandatory)]
        [string]$DropboxId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "folder") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $Folder = $Resolve.shared_folder_id
                } else {
                    Write-Warning "Folder not shared, use New-DropboxSharedFolder"
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "Folder not found: $Path"
            } else {
                Write-Warning "Specified path is not a folder, use Add-DropboxFileMember instead."
            }
        }
        if ($SharedFolderId) {
            $Folder = $SharedFolderId
        }
        $Body = @{
            shared_folder_id=$Folder
            to_dropbox_id=$DropboxId
        }
        if ($PSCmdlet.ShouldProcess("Folder: $Folder User: $DropboxId","Transfer folder ownership")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
        }
    }
    End{}
}

<#
.Synopsis
   Unshare Dropbox folder.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-DropboxSharedFolder {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    Param(
        # Folder path to resolve folder id.
        [parameter(Mandatory,ParameterSetName="FolderPath")]
        [string]$Path,
        # Folder id to add members to.
        [parameter(Mandatory,ParameterSetName="FolderId")]
        [string]$SharedFolderId,
        # Whether members will retain a copy of shared folder.
        [switch]$LeaveCopy,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/unshare_folder'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "folder") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $Folder = $Resolve.shared_folder_id
                } else {
                    Write-Warning "Folder not shared, use New-DropboxSharedFolder"
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "Folder not found: $Path"
            } else {
                Write-Warning "Specified path is not a folder, use Add-DropboxFileMember instead."
            }
        }
        if ($SharedFolderId) {
            $Folder = $SharedFolderId
        }

        $Body = @{
            shared_folder_id=$Folder
            leave_a_copy=$LeaveCopy.IsPresent
        }
        if ($PSCmdlet.ShouldProcess("Folder: $Folder","Unshare folder")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
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
function Remove-DropboxFolderMember {
    [CmdletBinding()]
    Param(
        # Folder path to resolve folder id.
        [parameter(Mandatory,ParameterSetName="FolderPath")]
        [string]$Path,
        # Folder id to add members to.
        [parameter(Mandatory,ParameterSetName="FolderId")]
        [string]$SharedFolderId,
        # Dropbox member's email address.
        [parameter(Mandatory,ParameterSetName="MemberEmail")]
        [parameter(ParameterSetName="FolderPath")]
        [parameter(ParameterSetName="FolderId")]
        [string]$MemberEmail,
        # Member's Dropbox id.
        [parameter(Mandatory,ParameterSetName="DropboxId")]
        [parameter(ParameterSetName="FolderPath")]
        [parameter(ParameterSetName="FolderId")]
        [string]$DropboxId,
        # Allow user to keep copy of files.
        [switch]$LeaveCopy,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/sharing/remove_folder_member'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        if ($Path) {
            $Resolve = Get-DropboxFileMetadata -Path $Path -Token $Token
            if ($Resolve.".tag" -eq "folder") {
                if ($Resolve.shared_folder_id -ne $null) {
                    $Folder = $Resolve.shared_folder_id
                } else {
                    Write-Warning "Folder not shared, use New-DropboxSharedFolder"
                }
            } elseif ($Resolve -eq $null) {
                Write-Warning "Folder not found: $Path"
            } else {
                Write-Warning "Specified path is not a folder, use Add-DropboxFileMember instead."
            }
        }
        if ($SharedFolderId) {
            $Folder = $SharedFolderId
        }
        if ($MemberEmail) {
            $Member=@{".tag"="email";email=$MemberEmail}
        } else {
            $Member=@{".tag"="dropbox_id";dropbox_id=$DropboxId}
        }
        $Body = @{
            shared_folder_id=$Folder
            member=$Member
            leave_a_copy=$LeaveCopy.IsPresent
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