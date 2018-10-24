<#
.Synopsis
   Add specific members to a file.
.DESCRIPTION
   Add specific member to a file.

   File must be already be shared.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-add_file_member.
.EXAMPLE
   PS> Add-DropboxFileMember -Path /share.txt -MemberEmail powershell@example.com -CustomMessage "Sharing this file" -AccessLevel viewer -Token <access token>

   Allows powershell@example.com as a viewer for file share.txt.
.EXAMPLE
   PS> Add-DropboxFileMember -Path /share.txt -MemberEmail powershell@example.com -Quiet -AccessLevel owner -SelectUser ps@example.com -Token <TeamMemberFileAccess>

   Adds powershell@example.com as owner for file share.txt on behalf of ps@example.com
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
        switch ($PSCmdlet.ParameterSetName) {
            "FilePath" {
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
            "FileId" {
                $File = $FileId
            }
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
        
        if ($PSCmdlet.ShouldProcess("Path: $Path, FileId: $FileId","Add $MemberEmail as $AccessLevel")) {
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
.SYNOPSIS
   Add specific members to a folder.
.DESCRIPTION
   Folder must already be shared using New-DropboxSharedFolder.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-add_folder_member.
.EXAMPLE
   PS> Add-DropboxFolderMember -Path /share -MemberEmail powershell@example.com -AccessLevel editor -Token <access level>

   Allow powershell@example.com to collaborate for content located in /share folder.
.EXAMPLE
   PS> Add-DropboxFolderMember -Path /share -MemberEmail powershell@example.com -AccessLevel editor -SelectUser ps@example.com -Token <TeamMemberFileAccess>

   Allow powershell@example.com to collaborate for content located in ps@example.com's /share folder.
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
        switch ($PSCmdlet.ParameterSetName) {
            "FolderPath" {
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
            "FolderId" {
                $Folder = $SharedFolderId
            }
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

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-list_file_members.
.EXAMPLE
   PS> Get-DropboxFileMember -Path /share.txt -Token <access token>

   Get all members with access to share.txt file.
.EXAMPLE
   PS> Get-DropboxFileMember -Path /share.txt -SelectUser powershell@example.com -Token <TeamMemberFileAccess>

   Get all members with access to powershell@example.com's share.txt file.
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
        switch ($PSCmdlet.ParameterSetName) {
            "FilePath" {
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
            "FileId" {
                $File = $FileId
            }
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
   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-list_folder_members.
.EXAMPLE
   PS> Get-DropboxFolderMember -Path /Share -Actions leave_a_copy -Token <access token>

   Get members for folder Share who are able to leave a copy of the shared folder.
.EXAMPLE
   PS> Get-DropboxFolderMember -Path /Share -SelectUser powershell@example.com -Token <TeamMemberFileAccess>

   Get members for powershell@example.com's Share folder.
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
        switch ($PSCmdlet.ParameterSetName) {
            "FolderPath" {
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
            "FolderId" {
                $Folder = $SharedFolderId
            }
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
   Get list of all shared folders.
.DESCRIPTION
   Get list of all shared folders the user has access to.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-list_folders.
.EXAMPLE
   PS> Get-DropboxSharedFolderList -Token <access token>

   Get all shared folders in your Dropbox folder.
.EXAMPLE
   PS> Get-DropboxSharedFolderList -SelectUser powershell@example.com -Token <TeamMemberFileAccess>

   Get all shared folders powershell@example.com has access to.
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
   Set a Dropbox folder as a shared folder and configure shared folder properties. To add members to the shared folder, use Add-DropboxFolderMember.

   If folder doesn't exist, it will be created.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-share_folder.
.EXAMPLE
   PS> New-DropboxSharedFolder -Path /Share -AccessInheritance inherit -Token <access token>

   Create / set folder Share as a shared folder with inherited access.
.EXAMPLE
   PS> New-DropboxSharedFolder -Path /Share -AccessInheritance inherit -SelectUser powershell@example.com -Token <TeamMemberFileAccess>

   Create / set folder Share as a shared folder in powershell@example.com's Dropbox folder.
#>
function New-DropboxSharedFolder {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
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
        
        if ($PSCmdlet.ShouldProcess("$Path","Create/set shared folder")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError
            }
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

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-relinquish_folder_membership.
.EXAMPLE
   PS> Grant-DropboxFolderOwnership -Path /Share -DropboxId id:123123124124 -Token <access token>

   Transfer Share folder ownership to DropboxId id:123123124124.
.EXAMPLE
   PS> Grant-DropboxFolderOwnership -Path /Share -DropboxID id:123123123123 -SelectUser powershell@example.com -Token <TeamMemberFileAccess>

   Transfer powershell@example.com's Share folder ownership to DropboxId id:123123123123.
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
        $URI='https://api.dropboxapi.com/2/sharing/transfer_folder'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "FolderPath" {
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
            "FolderId" {
                $Folder = $SharedFolderId
            }
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
   May take some time for action to complete depending on how many members are shared with.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-unshare_folder.
.EXAMPLE
   PS> Remove-DropboxSharedFolder -Path /Share -LeaveCopy -Token <access token>

   Unshare Dropbox folder Share and allow members to retain a copy of the file.
.EXAMPLE
   PS> Remove-DropboxSharedFolder -Path /Share -SelectUser powershell@example.com -Token <TeamMemberFileAccess>

   Unshare powershell@example.com's Dropbox Share folder.
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
        switch ($PSCmdlet.ParameterSetName) {
            "FolderPath" {
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
            "FolderId" {
                $Folder = $SharedFolderId
            }
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
   Remove another member.
.DESCRIPTION
   Allows an owner or editor (if the ACL update policy allows) of a shared folder to remove another member.

   Refer to https://www.dropbox.com/developers/documentation/http/documentation#sharing-remove_folder_member.
.EXAMPLE
   PS> Remove-DropboxFolderMember -Path /Share -MemberEmail powershell@example.com -Token <access token>

   Remove powershell@example.com from Share Dropbox folder.
.EXAMPLE
   PS> Remove-DropboxFolderMember -Path /Share -MemberEmail powershell@example.com -SelectUser ps@example.com -Token <TeamMemberFileAccess>

   Remove powershell@example.com's access to ps@example.com's Share Dropbox folder.
#>
function Remove-DropboxFolderMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
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
        if ($PSCmdlet.ShouldProcess("Path: $Path, SharedFolderId: $SharedFolderId","Remove Email: $MemberEmail, DropboxID: $DropboxId")) {        
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