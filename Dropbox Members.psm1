<#
.Synopsis
   List members of a team.
.DESCRIPTION
   Cmdlet returns a sorted basic list of current Dropbox team members.

   /member/list/continue is currently not supported.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-list.
.EXAMPLE
   Get-DropboxMemberList -Limit 100 -IncludeRemoved
    
   Cmdlet will return exactly 100 members including removed team members.
#>
function Get-DropboxMemberList {
    [CmdletBinding()]
    Param(
        # Number of results to return per call.
        [ValidateRange(1,1000)]
        [int]$Limit=200,
        # Whether to return removed members, default is false.
        [switch]$IncludeRemoved,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamInformation access token")]
        [string]$Token
    )

    Begin{
        $URI = "https://api.dropboxapi.com/2/team/members/list"
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{
        
        $Body = @{
            limit=$Limit
            include_removed=$IncludeRemoved.IsPresent
        }
        
        $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
        Write-Output $Result.members.profile | Sort-Object email
    }
    End{}
}

<#
.Synopsis
   Get information for one or more team members.
.DESCRIPTION
   Get information for specific team member(s).

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-get_info.
.EXAMPLE
   Get-DropboxMemberInfo -MemberEmail team.member@example.com

   Cmdlet gets information for team.member@example.com
.EXAMPLE
   Get-DropboxMemberInfo -MemberEmail team.member@example.com, team.member2@example.com

   Cmdlet gets information for multiple team members.
#>
function Get-DropboxMemberInfo {
    [CmdletBinding()]
    Param(
        # Dropbox team member's email address
        [parameter(Mandatory=$true,ParameterSetName="Email")]
        [ValidateLength(1,255)]
        [string[]]$MemberEmail,
        # Dropbox team member's team_member_id
        [parameter(Mandatory=$true,ParameterSetName="MemberId")]
        [string[]]$TeamMemberId,
        # Dropbox tema member's external_id
        [parameter(Mandatory=$true,ParameterSetName="ExternalId")]
        [ValidateLength(1,64)]
        [string[]]$ExternalId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamInformation access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/get_info'
        $Header = @{"Authorization"="Bearer $Token"}
        $Members = New-Object -TypeName System.Collections.ArrayList
    }
    Process{

        foreach ($Address in $MemberEmail) {
            $Members.Add(@{".tag"="email";email=$Address}) | Out-Null
        }
        foreach ($Id in $TeamMemberId) {
            $Members.Add(@{".tag"="team_member_id";team_member_id=$Id}) | Out-Null
        }
        foreach ($Id in $ExternalId) {
            $Members.Add(@{".tag"="external_id";external_id=$Id}) | Out-Null
        }

        $Body = @{
            members=$Members
        }
        
        $Response = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
        Write-Output $Response.profile
    }
    End{
    }
}

<#
.Synopsis
   Adds member to team.
.DESCRIPTION
   Currently only support a single user per call.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-add.
.EXAMPLE
    
#>
function Add-DropboxMember {
    [CmdletBinding()]
    Param(
        # New Dropbox member's email address.
        [parameter(Mandatory, ParameterSetName="SingleUser")]
        [ValidateLength(1,255)]
        [string]$MemberEmail,
        # New Dropbox member's first name.
        [parameter(ParameterSetName="SingleUser")]
        [ValidateLength(1,100)]
        [string]$MemberGivenName,
        # New Dropbox member's last name.
        [parameter(ParameterSetName="SingleUser")]
        [ValidateLength(1,100)]
        [string]$MemberSurname,
        # Team administrative tier.
        [parameter(ParameterSetName="SingleUser")]
        [validateset("member_only","support_admin","user_management_admin","team_admin")]
        [string]$Role="member_only",
        # Ne Dropbox member's external_id.
        [parameter(ParameterSetName="SingleUser")]
        [ValidateLength(1,64)]
        [string]$MemberExternalId,
        # New Dropbox member's persistent_id. Only available for teams using persistent ID SAML configuration.
        [parameter(ParameterSetName="SingleUser")]
        [string]$MemberPersistentId,
        # Whether to send a welcome email to the member.
        [parameter(ParameterSetName="SingleUser")]
        [switch]$SendWelcomeEmail,
        # Whether a user is directory restricted.
        [parameter(ParameterSetName="SingleUser")]
        [switch]$DirectoryRestricted,
        # Whether to force the add to happen asynchronously.
        [switch]$ForceAsync,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token

    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/add'
        $Header = @{"Authorization"="Bearer $Token"}
        $Member = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[string]]"
    }
    Process{
        
        $Member = [ordered]@{
                member_email=$MemberEmail
                send_welcome_email=$SendWelcomeEmail.IsPresent
                role=$Role
        }

        if ($MemberGivenName) {
            $Member.Add("member_given_name",$MemberGivenName)
        }
        if ($MemberSurname) {
            $Member.Add("member_surname",$MemberSurname)
        }
        if ($MemberExternalId) {
            $Member.Add("member_external_id",$MemberExternalId)
        }
        if ($MemberPersistentId) {
            $Member.Add("member_persistent_id",$MemberPersistentId)
        }
        if ($DirectoryRestricted.IsPresent -eq $true) {
            $Member.Add("is_directory_restricted","true")
        }

        $Body = @{
            new_members=@($Member)
            force_async=$ForceAsync.IsPresent
        }
        
        $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
        Write-Output $Result.".tag"
        Write-Output $Result.complete.profile

    }
    End{
    }
}

<#
.Synopsis
   Send Dropbox welcome email.
.DESCRIPTION
   Sends Dropbox welcome email to a pending member.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Send-DropboxWelcomeEmail {
    [CmdletBinding()]
    Param(
        # Dropbox team member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [ValidateLength(1,255)]
        [string]$MemberEmail,
        # Dropbox team member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$TeamMemberId,
        # Dropbox team member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [ValidateLength(1,64)]
        [string]$ExternalId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/send_welcome_email'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{

        if ($MemberEmail) {
            $Body = @{".tag"="email";email=$MemberEmail}
        }
        if ($TeamMemberId) {
            $Body = @{".tag"="team_member_id";team_member_id=$TeamMemberId}
        }
        if ($ExternalId) {
            $Body = @{".tag"="external_id";external_id=$ExternalId}
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
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
   Update team member's permissions.
.DESCRIPTION
   Cmdlet updates an existing team member's permissions to "member_only","support_admin","user_management_admin" or "team_admin".

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-set_admin_permissions.

.EXAMPLE
   Set-DropboxMemberPermissions -MemberEmail team.member@example.com -NewRole team_admin

   Cmdlet sets team.member's role to team_admin.
#>
function Set-DropboxMemberPermissions {
    [CmdletBinding()]
    Param(
        # Dropbox team member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [validatelength(1,255)]
        [string]$MemberEmail,
        # Dropbox team member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$TeamMemberId,
        # Dropbox team member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [ValidateLength(1,64)]
        [string]$ExternalId,
        # New role for Dropbox team member.
        [validateset("member_only","support_admin","user_management_admin","team_admin")]
        [parameter(Mandatory=$true)]
        [string]$NewRole,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/set_admin_permissions'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($MemberEmail) {
            $User = @{".tag"="email";email=$MemberEmail}
        }
        if ($TeamMemberId) {
            $User = @{".tag"="team_member_id";team_member_id=$TeamMemberId}
        }
        if ($ExternalId) {
            $User = @{".tag"="external_id";external_id=$ExternalId}

        }
        $Body = @{
            user=$User
            new_role=$NewRole
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
   Update team member's profile.
.DESCRIPTION
   Update a team member's profile.

   The following parameters can be altered:

        Email
        GivenName
        Surname
        ExternalId
        PersistentId

    Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-set_profile.
.EXAMPLE
   Set-DropboxMemberProfile -MemberEmail team.member@example.com -GivenName test -Surname user

   Cmdlet sets team.members's first name to "test" and last name to "user".
#>
function Set-DropboxMemberProfile {
    [CmdletBinding()]
    Param(
        # Dropbox team member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [validatelength(1,255)]
        [string]$MemberEmail,
        # Dropbox team member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$TeamMemberId,
        # Dropbox team member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [ValidateLength(1,64)]
        [string]$ExternalId,
        # New Dropbox external id for member.
        [ValidateLength(1,64)]
        [string]$NewExternalId,
        # New email for Dropbox member.
        [ValidateLength(1,255)]
        [string]$NewEmail,
        # New given / first name for member.
        [ValidateLength(1,100)]
        [string]$GivenName,
        # New surname / last name for member.
        [ValidateLength(1,100)]
        [string]$Surname,
        # New persistent ID (only available to teams with persistent ID SAML configuration).
        [string]$PersistentId,
        # Whether user is a directory restricted user.
        [switch]$NewIsDirectoryRestricted,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/set_profile'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{

        if ($MemberEmail) {
            $Body=@{user=@{".tag"="email";email=$MemberEmail}}
        }
        if ($TeamMemberId) {
            $Body=@{user=@{".tag"="team_member_id";team_member_id=$TeamMemberId}}
        }
        if ($ExternalId) {
            $Body=@{user=@{".tag"="external_id";external_id=$ExternalId}}
        }

        # Optional parameters

        if ($NewEmail) {
            $Body.Add("new_email",$NewEmail)
        }
        if ($NewExternalId) {
            $Body.Add("new_external_id",$NewExternalId)
        }
        if ($GivenName) {
            $Body.Add("new_given_name",$GivenName)
        }
        if ($Surname) {
            $Body.Add("new_surname",$Surname)
        }
        if ($PersistentId) {
            $Body.Add("new_persistent_id",$PersistentId)
        }
        if ($NewIsDirectoryRestricted) {
            $Body.Add("new_is_directory_restricted",$NewIsDirectoryRestricted.IsPresent)
        }

        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.profile
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
function Suspend-DropboxMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    Param(
        # Dropbox team member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [ValidateLength(1,255)]
        [string]$MemberEmail,
        # Dropbox team member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$TeamMemberId,
        # Dropbox team member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [ValidateLength(1,64)]
        [string]$ExternalId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token,
        # Controls if user's Dropbox data will be deleted on linked devices.
        [switch]$WipeData
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/suspend'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($MemberEmail) {
            $Body=@{user=@{".tag"="email";email=$MemberEmail};wipe_data=$WipeData.IsPresent}
        }
        if ($TeamMemberId) {
            $Body=@{user=@{".tag"="team_member_id";team_member_id=$TeamMemberId};wipe_data=$WipeData.IsPresent}
        }
        if ($ExternalId) {
            $Body= @{user=@{".tag"="external_id";external_id=$ExternalId};wipe_data=$WipeData.IsPresent}
        }
        
        try {
            if ($PSCmdlet.ShouldProcess("Suspend Dropbox Member $MemberEmail")) {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
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
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Unsuspent-DropboxMember {
    [CmdletBinding()]
    Param(
        # Dropbox team member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [ValidateLength(1,255)]
        [string]$MemberEmail,
        # Dropbox team member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$TeamMemberId,
        # Dropbox team member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [ValidateLength(1,64)]
        [string]$ExternalId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/unsuspend'
        $Header = @{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($MemberEmail) {
            $Body=@{user=@{".tag"="email";email=$MemberEmail}}
        }
        if ($TeamMemberId) {
            $Body=@{user=@{".tag"="team_member_id";team_member_id=$TeamMemberId}}
        }
        if ($ExternalId) {
            $Body= @{user=@{".tag"="external_id";external_id=$ExternalId}}
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            Get-DropboxError -Result $ResultError
        }
    }
    End{}
}