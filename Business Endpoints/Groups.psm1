<#
.Synopsis
   Create new Dropbox group.
.DESCRIPTION
   Create a new Dropbox group with no members.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-create.
.EXAMPLE
   PS> New-DropboxGroup -GroupName PowerShell -GroupExternalId PowerShell -GroupManagementType user_managed -Token <TeamMemberManagement>

   Creates a new group named PowerShell where group membership is managed by a group manager user.
#>
function New-DropboxGroup {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")]
    Param(
        # New Dropbox group name.
        [parameter(Mandatory=$true)]
        [string]$GroupName,
        # Arbitrary external ID to the group.
        [string]$GroupExternalId,
        # Whether the team can be managed by selected users or only by team admins
        [ValidateSet("user_managed","company_managed")]
        [string]$GroupManagementType="company_managed",
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI = 'https://api.dropboxapi.com/2/team/groups/create'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            group_name=$GroupName
            group_external_id=$GroupExternalId
            group_management_type=$GroupManagementType
        }
            
        if ($PSCmdlet.ShouldProcess("GroupName: $GroupName, GroupExternalId: $GroupExternalId, ManagementType: $GroupManagementType","Create new Dropbox group")) {
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
   Delete a Dropbox group
.DESCRIPTION
   Immidiately delete Dropbox group.

   Revoking group-owned resources may take additional time.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-delete.
.EXAMPLE
   PS> Remove-DropboxGroup -GroupName PowerShell -Token <TeamMemberManagement>

   Remove Dropbox group PowerShell.
.EXAMPLE
   PS> Remove-DropboxGroup -GroupId <Group Id> -Token <TeamMemberManagement>

   Remove Dropbox group by specifying the group_id.
.EXAMPLE
   PS> Remove-DropboxGroup -GroupExternalId PowerShell -Token <TeamMemberManagement>

   Remove Dropbox group by specifying group_external_id.
#>
function Remove-DropboxGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="High")]
    Param(
        # Dropbox group id.
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string]$GroupExternalId,
        # Dropbox group name to resolve group id.
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string]$GroupName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/delete'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupOd" {
                $Body=@{".tag"="group_id";group_id=$GroupId}
            }
            "GroupExternalId" {
                $Body=@{".tag"="group_external_id";group_external_id=$GroupExternalId}
            }
            "GroupName" {
                $Id = Get-DropboxGroupList -GroupName $GroupName
                $Body=@{".tag"="group_id";group_id=$Id}
            }
        }
        
        if ($PSCmdlet.ShouldProcess("GroupName: $GroupName, GroupId: $GroupId, GroupExternalId: $GroupExternalId","Delete Dropbox group")) {
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
   Get group information.
.DESCRIPTION
   Get information about one or more groups.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-get_info.
.EXAMPLE
   PS> Get-DropboxGroupInfo -GroupName *PowerShell* -Token <access token>

   Get info for any Dropbox group with a name containing PowerShell.
.EXAMPLE
   PS> Get-DropboxGroupInfo -GroupName PowerShell,Scripts -Token <access token>

   Get info for Dropbox groups "PowerShell" & "Scripts"
.EXAMPLE
   PS> Get-DropboxGroupInfo -GroupId <Group Id> -Token <access token>

   Get info for Dropbox group of the specified group_id.
#>
function Get-DropboxGroupInfo {
    [CmdletBinding()]
    Param(
        # Dropbox group id.
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string[]]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string[]]$GroupExternalId,
        # Dropbox group name to resolve group id.
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string[]]$GroupName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamInformation access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/get_info'
        $Header=@{"Authorization"="Bearer $Token"}
        $GroupList = New-Object -TypeName System.Collections.ArrayList
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupName" {
                foreach ($Group in $GroupName) {
                    $IdList = Get-DropboxGroupList -GroupName $Group -Token $Token
                    foreach ($Id in $IdList) {
                        $GroupList.Add($Id) | Out-Null
                    }
                }
                $Body=@{".tag"="group_ids";group_ids=$GroupList}
            }
            "GroupId" {
                foreach ($Group in $GroupId) {
                    $GroupList.Add($Group) | Out-Null
                }
                $Body=@{".tag"="group_ids";group_ids=$GroupList}
            }
            "GroupExternalId" {
                foreach ($Id in $GroupExternalId) {
                    $GroupList.Add($Id) | Out-Null
                }
                $Body=@{".tag"="group_external_ids";group_external_ids=$GroupList}
            }
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
   Lists groups on a team.
.DESCRIPTION
   Cmdlet lists all groups on a team or filter for a specific group.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-list"
.EXAMPLE
   PS> Get-DropboxGroupList

   Cmdlet will list all groups.
.EXAMPLE
   PS> Get-DropboxGroupList -GroupName PowerShell

   Cmdlet willl return group_id for group PowerShell (if exists).
.EXAMPLE
   PS> Get-DropboxGroupList -GroupName *test*

   Cmdlet will return group_ids for any group containing "test".
#>
function Get-DropboxGroupList {
    [CmdletBinding()]
    Param(
        # Group name used to resolve group id.
        [string]$GroupName,
        # Number of results to return per call.
        [ValidateRange(1,1000)]
        [int]$Limit=200,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamInformation access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/list'
        $Header=@{"Authorization"="Bearer $Token"}
    }

    Process{

        $Body = @{
            limit=$Limit
        }
        
        $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)

        if ($GroupName) {
            $SelectedGroup = ($Result.groups | Where-Object group_name -Like "$GroupName").group_id
            if ($SelectedGroup -eq $null) {
                Write-Warning "Group not found: $GroupName"
            } else {
                Write-Output $SelectedGroup
            }
        } else {
            Write-Output $Result.groups | Sort-Object group_name
        }
        if ($Result.has_more -eq $true) {
            Write-Output "More groups results are available"
        }
    }
        
    End{}
}

<#
.Synopsis
   Add members to a group.
.DESCRIPTION
   Immediately add members to a group.

   Granting group-owned resources may take additional time.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-members-add.
.EXAMPLE
   PS> Add-DropboxGroupMember -GroupName PowerShell -MemberEmail powershell@example.com,cmdlet@example.com -AccessType member -Token <TeamMemberManagement>

   Add powershell@example.com & cmdlet@example.com to PowerShell group as members.
.EXAMPLE
   PS> Add-DropboxGroupMember -GroupName PowerShell -MemberEmail powershell@example.com -AccessType owner -ReturnMembers -Token <TeamMemberManagement>

   Add powershell@example.com to PowerShell group as the owner and return all current group members.
#>
function Add-DropboxGroupMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")]
    Param(
        # Dropbox group name used to resolve group id
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string]$GroupName,
        # Dropbox group id
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string]$GroupExternalId,
        # Dropbox member's email address
        [ValidateLength(1,255)]
        [parameter(ValueFromPipeline)]
        [string[]]$MemberEmail,
        # Dropbox member's team_member_id.
        [string[]]$TeamMemberId,
        # Dropbox member's external_id.
        [ValidateLength(1,64)]
        [string[]]$ExternalId,
        # Role of a user in group
        [validateset("member","owner")]
        [string]$AccessType="member",
        # Whether to return the list of members in the group
        [switch]$ReturnMembers,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/members/add'
        $Header=@{"Authorization"="Bearer $Token"}
        $MemberAccess = New-Object System.Collections.ArrayList
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupName" {
                $Id = Get-DropboxGroupList -GroupName $GroupName
                $Group=@{".tag"="group_id";group_id=$Id}
            }
            "GroupId" {
                $Group=@{".tag"="group_id";group_id=$GroupId}
            }
            "GroupExternalId" {
                $Group=@{".tag"="group_external_id";group_external_id=$GroupExternalId}
            }
        }

        foreach ($Email in $MemberEmail) {
            $MemberAccess.Add(@{user=[ordered]@{".tag"="email";email=$Email};access_type=$AccessType}) | Out-Null
        }
        foreach ($Id in $TeamMemberId) {
            $MemberAccess.Add(@{user=[ordered]@{".tag"="team_member_id";team_member_id=$Id};access_type=$AccessType}) | Out-Null
        }
        foreach ($Id in $ExternalId) {
            $MemberAccess.Add(@{user=[ordered]@{".tag"="external_id";external_id=$Id};access_type=$AccessType}) | Out-Null
        }

        $Body = @{
            group=$Group
            members=$MemberAccess
            return_members=$ReturnMembers.IsPresent
        }
        
        if ($PSCmdlet.ShouldProcess("GroupName: $GroupName, GroupID: $GroupId, GroupExternalId: $GroupExternalId","Add members to")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body -Depth 3)     
                Write-Output $Result.group_info
                if ($ReturnMembers.IsPresent -eq $true) {
                    Write-Output $Result.group_info.members.profile | Sort-Object email
                }
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
   Lists members of a group
.DESCRIPTION
   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-members-list.
.EXAMPLE
   Get-DropboxGroupMemberList -GroupName PowerShell -Token <TeamInformation>

   Get list of members for group PowerShell
#>
function Get-DropboxGroupMemberList {
    [CmdletBinding()]
    Param(
        # Dropbox group name used to resolve group id
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string]$GroupName,
        # Dropbox group id
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string]$GroupExternalId,
        # Number of results to return per call.
        [ValidateRange(1,1000)]
        [int]$Limit=200,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamInformation access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/members/list'
	    $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupName" {
                $Id = Get-DropboxGroupList -GroupName $GroupName -Token $Token
                $Group=@{".tag"="group_id";group_id=$Id}
            }
            "GroupId" {
                $Group=@{".tag"="group_id";group_id=$GroupId}
            }
            "GroupExternalId" {
                $Group=@{".tag"="group_external_id";group_external_id=$GroupExternalId}
            }
        }

        $Body = @{
            group=$Group
            limit=$Limit
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.members.profile | Sort-Object email
            if ($Result.has_more -eq $true) {
                Write-Output "More group member results are available"
            }
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
   Removes members from a group.
.DESCRIPTION
   Immediately remove members from a group.

   Revoking of group-owned resources may take additional time.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-members-remove.
.EXAMPLE
   PS> Remove-DropboxGroupMember -GroupName PowerShell -MemberEmail powershell@example.com -Token <TeamMemberManagement>

   Remove member powershell@example.com from group PowerShell.
.EXAMPLE
   PS> Remove-DropboxGroupMember -GroupName PowerShell -MemberEmail powershell@example.com,cmdlet@example.com -ReturnMembers -Token <TeamMemberManagement>

   Remove member powershell@example.com & cmdlet@example.com from group PowerShell and return list of current members.
#>
function Remove-DropboxGroupMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    Param(
        # Dropbox group name used to resolve group id
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string]$GroupName,
        # Dropbox group id
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string]$GroupExternalId,
        # Dropbox team member's email address.
        [ValidateLength(1,255)]
        [string[]]$MemberEmail,
        # Dropbox team member's team_mmeber_id.
        [string[]]$TeamMemberId,
        # Dropbox team member's external_id.
        [ValidateLength(1,64)]
        [string[]]$ExternalId,
        # Whether to return list of group members.
        [switch]$ReturnMembers,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/members/remove'
	    $Header=@{"Authorization"="Bearer $Token"}
        $Members = New-Object -TypeName System.Collections.ArrayList
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupName" {
                $Id = Get-DropboxGroupList -GroupName $GroupName -Token $Token
                $Group=@{".tag"="group_id";group_id=$Id}
            }
            "GroupId" {
                $Group=@{".tag"="group_id";group_id=$GroupId}
            }
            "GroupExternalId" {
                $Group=@{".tag"="group_external_id";group_external_id=$GroupExternalId}
            }
        }

        foreach ($Email in $MemberEmail) {
            $Members.Add([ordered]@{".tag"="email";email=$Email}) | Out-Null
        }
        foreach ($Id in $TeamMemberId) {
            $Members.Add(@{".tag"="team_member_id";team_member_id=$Id}) | Out-Null
        }
        foreach ($Id in $ExternalId) {
            $Members.Add(@{".tag"="external_id";external_id=$Id}) | Out-Null
        }

        $Body = @{
            group=$Group
            users=@($Members)
            return_members=$ReturnMembers.IsPresent
        }
        
        if ($PSCmdlet.ShouldProcess("GroupName: $GroupName, GroupId: $GroupId, GroupExternalId: $GroupExternalId","Remove Dropbox member")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result.group_info
                if ($ReturnMembers.IsPresent -eq $true) {
                    Write-Output $Result.group_info.members.profile | Sort-Object email
                }
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
   Set members access type in a group
.DESCRIPTION
   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-members-set_access_type.
.EXAMPLE
   PS> Set-DrobpoxGroupMemberAccess -GroupName PowerShell -MemberEmail ps -AccessType owner -Token <TeamMemberManagement>

   Sets user ps as the owner of group PowerShell.
#>
function Set-DropboxGroupMemberAccess {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    Param(
        # Dropbox group name used to resolve group id.
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string]$GroupName,
        # Dropbox group id
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string]$GroupExternalId,
        # Dropbox team member's email address.
        [ValidateLength(1,255)]
        [string]$MemberEmail,
        # Dropbox team member's team_mmeber_id.
        [string]$TeamMemberId,
        # Dropbox team member's external_id.
        [ValidateLength(1,64)]
        [string]$ExternalId,
        # New group access type the user will have.
        [parameter(Mandatory)]
        [validateset("member","owner")]
        [string]$AccessType,
        # Whether to return the list of members in the group.
        [switch]$ReturnMembers,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/members/set_access_type'
	    $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupName" {
                $Id = Get-DropboxGroupList -GroupName $GroupName -Token $Token
                $Group=@{".tag"="group_id";group_id=$Id}
            }
            "GroupId" {
                $Group=@{".tag"="group_id";group_id=$GroupId}
            }
            "GroupExternalId" {
                $Group=@{".tag"="group_external_id";group_external_id=$GroupExternalId}
            }
        }

        foreach ($Email in $MemberEmail) {
            $User=@{".tag"="email";email=$Email}
        }
        foreach ($Id in $TeamMemberId) {
            $User=@{".tag"="team_member_id";team_member_id=$Id}
        }
        foreach ($Id in $ExternalId) {
            $User=@{".tag"="external_id";external_id=$Id}
        }

        $Body = @{
            group=$Group
            user=$User
            access_type=$AccessType
            return_members=$ReturnMembers.IsPresent
        }
        
        if ($PSCmdlet.ShouldProcess("GroupName: $GroupName, GroupId: $GroupId, GroupExternalId: $GroupExternalId","Set member to $AccessType")) {
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
   Update Dropbox group.
.DESCRIPTION
   Update Dropbox group name, external id or management type.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-groups-update.
.EXAMPLE
   PS> Update-DropboxGroup -GroupName PowerShell -NewName PowerShellUpdated -Token <TeamMemberManagement>

   Update group PowerShell name to PowerShellUpdated.
#>
function Update-DropboxGroup {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    Param(
        # Group name to resolve group id
        # Dropbox group name used to resolve group id
        [parameter(Mandatory,ParameterSetName="GroupName")]
        [string]$GroupName,
        # Dropbox group id
        [parameter(Mandatory,ParameterSetName="GroupId")]
        [string]$GroupId,
        # Dropbox group external id.
        [parameter(Mandatory,ParameterSetName="GroupExternalId")]
        [string]$GroupExternalId,
        # Set new group name
        [string]$NewName,
        # Set new group external id
        [string]$NewExternalID,
        # Set new group management type
        [validateset("user_managed","company_managed","system_managed")]
        [string]$NewGroupManagementType,
        # Whether to return the list of members in group
        [switch]$ReturnMembers,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/groups/update'
	    $Permission="TeamMemberManagement"
	    $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "GroupName" {
                $Id = Get-DropboxGroupList -GroupName $GroupName -Token $Token
                $Group=@{".tag"="group_id";group_id=$Id}
            }
            "GroupId" {
                $Group=@{".tag"="group_id";group_id=$GroupId}
            }
            "GroupExternalId" {
                $Group=@{".tag"="group_external_id";group_external_id=$GroupExternalId}
            }
        }

        $Body = @{
            group=$Group
            return_members=$ReturnMembers.IsPresent
        }

        if ($NewName) {
            $Body.Add("new_group_name",$NewName) | Out-Null
        }
        if ($NewExternalID) {
            $Body.Add("new_group_external_id",$NewExternalID) | Out-Null
        }
        if ($NewGroupManagementType) {
            $Body.Add("new_group_management_type",$NewGroupManagementType) | Out-Null
        }
        
        if ($PSCmdlet.ShouldProcess("GroupName: $GroupName, GroupID: $GroupId, GroupExternalId: $GroupExternalId","NewName: $NewName, NewExternalId: $NewExternalID, ManagementType: $NewGroupManagementType")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result
                if ($ReturnMembers.IsPresent -eq $true) {
                    Write-Output $Result.members.profile | Sort-Object email
                }
            } catch {
                $ResultError = $_.Exception.Response.GetResponseStream()
                Get-DropboxError -Result $ResultError 
            }
        }
    }
    End{}
}