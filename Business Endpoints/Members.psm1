<#
.Synopsis
   Adds member to team.
.DESCRIPTION
   Adds a member to Dropbox team. If no Dropbox account exists with specified email a new Dropbox account will be created and invited to team.

   If a personal account exists with specified email address, a placeholder account will be created and user will be invited to the team. The user will be promted to migrate their existing personal account onto the team.
   Currently only support a single user per call due to the large number of parameters.

   Added member will be required to complete Dropbox account setup.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-add.
.EXAMPLE
   PS> $TeamMemberManagement = Get-DropboxToken -Permission TeamMemberManagement
   PS> Add-DropboxMember -MemberEmail powershell@example.com -MemberGivenName Power -MemberSurname Shell -Role team_admin -MemberExternalId Powershell -SendWelcomeEmail -Token $TeamMemberManagement

   Adds user powershell@example.com as a team admin.
    
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
        # Dropbox.Member.New object which must contain at least the email address. Maximum 20 entries per call.
        [parameter(ParameterSetName="MultiUser")]
        [PSTypeName("Dropbox.Member.New")]$InputObject,
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
            $Member.Add("member_given_name",$MemberGivenName) | Out-Null
        }
        if ($MemberSurname) {
            $Member.Add("member_surname",$MemberSurname) | Out-Null
        }
        if ($MemberExternalId) {
            $Member.Add("member_external_id",$MemberExternalId) | Out-Null
        }
        if ($MemberPersistentId) {
            $Member.Add("member_persistent_id",$MemberPersistentId) | Out-Null
        }
        if ($DirectoryRestricted.IsPresent -eq $true) {
            $Member.Add("is_directory_restricted","true") | Out-Null
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
   Get information for one or more team members.
.DESCRIPTION
   Get information for specific team member(s). Member's can be specified by email, team_member_id or external_id.

   This cmdlet is also used to resolve team_member_id for some calls that only support that parameter.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-get_info.
.EXAMPLE
   PS> Get-DropboxMemberInfo -MemberEmail team.member@example.com

   Cmdlet gets information for team.member@example.com
.EXAMPLE
   PS> Get-DropboxMemberInfo -MemberEmail team.member@example.com, team.member2@example.com

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
        
        try {
            $Response = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Response.profile
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
   List members of a team.
.DESCRIPTION
   Cmdlet returns a sorted basic list of current Dropbox team members.

   /member/list/continue is currently not supported.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-list.
.EXAMPLE
   PS> Get-DropboxMemberList
    
   Cmdlet will return information for 100 users (Default)
.EXAMPLE
   PS> Get-DropboxMemberList -Limit 1000 -IncludeRemoved

   Cmdlet will return information for 1000 (maximum) users including any removed members.
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
   Send Dropbox welcome email.
.DESCRIPTION
   Sends Dropbox welcome email to a pending member.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-send_welcome_email.
.EXAMPLE
   PS> Send-DropboxWelcomeEmail -MemberEmail powershell@example.com -Token <TeamMemberManagement>

   Sends a Dropbox welcomd email to powershell@example.com.
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
        switch ($PSCmdlet.ParameterSetName) {
            "Email" {
                $Body = @{".tag"="email";email=$MemberEmail}
            }
            "MemberId" {
                $Body = @{".tag"="team_member_id";team_member_id=$TeamMemberId}
            }
            "ExternalId" {
                $Body = @{".tag"="external_id";external_id=$ExternalId}
            }
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
   PS> Set-DropboxMemberPermissions -MemberEmail team.member@example.com -NewRole team_admin -Token <TeamMemberManagement>

   Cmdlet sets team.member's role to team_admin.
#>
function Set-DropboxMemberPermissions {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
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

        Switch ($PSCmdlet.ParameterSetName) {
            "Email" {    
                $User = @{".tag"="email";email=$MemberEmail}
            }
            "MemberId" {
                $User = @{".tag"="team_member_id";team_member_id=$TeamMemberId}
            }
            "ExternalId" {
                $User = @{".tag"="external_id";external_id=$ExternalId}
            }
        }
        $Body = @{
            user=$User
            new_role=$NewRole
        }
   
        if ($PSCmdlet.ShouldProcess("Email: $MemberEmail, TeamMemberId: $TeamMemberId, ExternalId: $ExternalId","Update administrative permissions")) {
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
   Update team member's profile.
.DESCRIPTION
   Update a team member's profile.

   The following parameters can be altered: Email, GivenName, Surname, ExternalId, PersistentId

    Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-set_profile.
.EXAMPLE
   PS> Set-DropboxMemberProfile -MemberEmail team.member@example.com -GivenName test -Surname user -Token <TeamMemberManagement>

   Cmdlet sets team.members's first name to "test" and last name to "user".
.EXAMPLe
   PS> Set-DropboxMemberProfile -MemberEmail team.member@example.com -ExternalId teammember -Token <TeamMemberManagement>

   Cmdlet sets team.member's external_id to teammember.
#>
function Set-DropboxMemberProfile {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
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
        switch ($PSCmdlet.ParameterSetName) {
            "Email" {
                $Body=@{user=@{".tag"="email";email=$MemberEmail}}
            }
            "MemberId" {
                $Body=@{user=@{".tag"="team_member_id";team_member_id=$TeamMemberId}}
            }
            "ExternalId" {
                $Body=@{user=@{".tag"="external_id";external_id=$ExternalId}}
            }
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

        if ($PSCmdlet.ShouldProcess("Email: $Email, TeamMemberId: $TeamMemberId, ExternalId: $ExternalId","Update member profile")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
                Write-Output $Result.profile
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
   Suspend a member from a team.
.DESCRIPTION
   Suspend a team member from a team. All access will be revoked until Unsuspend-DropboxMember is run.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-suspend.
.EXAMPLE
   PS> Suspend-DropboxMember -MemberEmail powershell@example.com -token <TeamMemberManagement>

   Suspends user powershell@example.com.
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
        switch ($PSCmdlet.ParameterSetName) {
            "Email" {
                $Body=@{user=@{".tag"="email";email=$MemberEmail};wipe_data=$WipeData.IsPresent}
            }
            "MemberId" {
                $Body=@{user=@{".tag"="team_member_id";team_member_id=$TeamMemberId};wipe_data=$WipeData.IsPresent}
            }
            "ExternalId" {
                $Body= @{user=@{".tag"="external_id";external_id=$ExternalId};wipe_data=$WipeData.IsPresent}
            }
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
   Unsuspend a member from a team.
.DESCRIPTION
   Unsuspend a member from a team. Allows user to login to Dropbox again.
.EXAMPLE
   PS> Unsuspend-DropboxMember -MemberEmail powershell@example.com -Token <TeamMemberManagement>

   Unsuspend user powershell@example.com.
#>
function Unsuspend-DropboxMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")]
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
        switch ($PSCmdlet.ParameterSetName) {
            "Email" {
                $Body=@{user=@{".tag"="email";email=$MemberEmail}}
            }
            "MemberId" {
                $Body=@{user=@{".tag"="team_member_id";team_member_id=$TeamMemberId}}
            }
            "ExternalId" {
                $Body= @{user=@{".tag"="external_id";external_id=$ExternalId}}
            }
        }
        
        if ($PSCmdlet.ShouldProcess($Body,"Unsuspend member")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
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
   Move removed member's files.
.DESCRIPTION
   Move removed member's files to a different member.

   The call requires an id for the user, destination user and administrator where email address, external_id or team_member_id can be specified, only one identification type can be specified.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-move_former_member_files.
.EXAMPLE
   PS> Move-DropboxMemberFiles -MemberEmail powershell@example.com -DestinationEmail cmd@example.com -AdminEmail admin@example.com -Token <TeamMemberManagement>

   Moves powershell@example.com's Dropbox files to cmd@example.com. If an error occurs, admin@example.com will receive an error email.
.EXAMPLE
   PS> Move-DropboxMemberFiles -MemberEmail powershell@example.com -TeamMemberId pwsh:1231241241 -DestinationEmail cmd@example.com -AdminEmail admin@example.com -Token <TeamMemberManagement>

   Both MemberEmail and TeamMemberId are specified, MemberEmail will take presidence.
#>
function Move-DropboxMemberFiles {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    Param(
        # Member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$TeamMemberId,
        # Member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [string]$ExternalId,
        # Member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [string]$MemberEmail,
        # Destination member's team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$DestinationTeamMemberId,
        # Destination member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [string]$DestinationExternalId,
        # Destination member's email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [string]$DestinationEmail,
        # Administrator team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberId")]
        [string]$AdminTeamMemberId,
        # Administrator external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [string]$AdminExternalId,
        # Administrator email address.
        [parameter(Mandatory,ParameterSetName="Email")]
        [string]$AdminEmail,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/move_former_member_files'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{

        switch ($PSCmdlet.ParameterSetName) {
            "Email" {
                $User=@{".tag"="email";email=$MemberEmail}
                $Destination=@{".tag"="email";email=$DestinationEmail}
                $Admin=@{".tag"="email";email=$AdminEmail}
            }
            "ExternalId" {
                $User=@{".tag"="external_id";external_id=$ExternalId}
                $Destination=@{".tag"="external_id";external_id=$DestinationExternalId}
                $Admin=@{".tag"="external_id";external_id=$AdminExternalId}
            }
            "MemberId" {
                $User=@{".tag"="team_member_id";team_member_id=$TeamMemberId}
                $Destination=@{".tag"="team_member_id";team_member_id=$DestinationTeamMemberId}
                $Admin=@{".tag"="team_member_id";team_member_id=$AdminTeamMemberId}
            }
        }

        $Body = @{
            user=$User
            transfer_dest_id=$Destination
            transfer_admin_id=$Admin
        }
        
        if ($PSCmdlet.ShouldProcess($Destination,"Move $User files to")) {
            try {
                $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body -Depth 3)
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
   Recover deleted member.
.DESCRIPTION
   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-members-recover.
.EXAMPLE
   Restore-DropboxMember -MemberEmail powershell@example.com -Token <TeamMemberManagement>

   Restores member powershell@example.com.
#>
function Restore-DropboxMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")]
    Param(
        # Dropbox member's team_member_id.
        [parameter(Mandatory,ParameterSetName="TeamMemberId")]
        [string]$TeamMemberId,
        # Dropbox member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [string]$ExternalId,
        # Dropbox member's email address.
        [parameter(Mandatory,ParameterSetName="MemberEmail")]
        [string]$MemberEmail,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/recover'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "TeamMemberId" {
                $User=@{".tag"="email";email=$MemberEmail}
            }
            "ExternalId" {
                $User=@{".tag"="external_id";external_id=$ExternalId}
            }
            "MemberEmail" {
                $User=@{".tag"="team_member_id";team_member_id=$TeamMemberId}
            }
        }
        
        $Body = @{
            user=$User
        }
        
        if ($PSCmdlet.ShouldProcess("$User","Restore Dropbox member")) {
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
   Remove member from Dropbox team.
.DESCRIPTION
   Remove exactly one member from a Dropbox team.

   Accounts can be recoved via Restore-DropboxMember (members/recover call) cmdlet for a 7 day period or until account is permanently deleted or transferred to another account(whichever comes first).

   Attempting to restore member with Add-DropboxMember (members/add call) cmdlet will result in user_already_on_team error.

   Accounts can have files transferred via admin console for a limited time based on version history length associated with the team (120 days for most teams).
.EXAMPLE
   PS> Remove-DropboxMember -MemberEmail powershell@example.com -WipeData -Token <TeamMemberManagement>

   Remove powershell@example.com member from Dropbox team and wipe any data present on user's devices.
.EXAMPLE
   PS> Remove-DropboxMember -MemberEmail powershell@example.com -DestinationEmail admin@example.com -AdminEmail admin@example.com -Token <TeamMemberManagement>

   Remove powershell@example.com member from Dropbox team and transfer member's files to admin@example.com. 
.EXAMPLE
   PS> Remove-DropboxMember -MemberEmail powershell@example.com -KeepAccount -Token <TeamMemberManagement>

   Remove powershell@example.com member from Dropbox team and allow member to retain Dropbox account as basic / personal.
#>
function Remove-DropboxMember {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    Param(
        # Dropbox member's team_member_id.
        [parameter(Mandatory,ParameterSetName="TeamMemberId")]
        [string]$TeamMemberId,
        # Dropbox member's external_id.
        [parameter(Mandatory,ParameterSetName="ExternalId")]
        [string]$ExternalId,
        # Dropbox member's email address.
        [parameter(Mandatory,ParameterSetName="MemberEmail")]
        [string]$MemberEmail,
        # Destination member's team_member_id to transfer removed member's files.
        [string]$DestinationTeamMemberId,
        # Destination member's external_id to transfer removed member's files.
        [string]$DestinationExternalId,
        # Destination member's email address to transfer removed member's files.
        [string]$DestinationEmail,
        # Administrator team_member_id to receive errors. Must be used if destination account is specified.
        [string]$AdminTeamMemberId,
        # Administrator external_id to receive errors. Must be used if destination account is specified.
        [string]$AdminExternalId,
        # Administrator email address to receive errors. Must be used if destination account is specified.
        [string]$AdminEmail,
        # Whether data will be deleted off linked devices.
        [switch]$WipeData,
        # Whether to downgrade account to a basic account. User will retain data and email address associated with Dropbox account.
        [switch]$KeepAccount,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberManagement access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/members/remove'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        switch ($PSCmdlet.ParameterSetName) {
            "TeamMemberId" {
                $User=@{".tag"="team_member_id";team_member_id=$TeamMemberId}
            }
            "ExternalId" {
                $User=@{".tag"="external_id";external_id=$ExternalId}
            }
            "MemberEmail" {
                $User=@{".tag"="email";email=$MemberEmail}
            }
        }

        $Body = @{
            user=$User
            wipe_data=$WipeData.IsPresent
            keep_account=$KeepAccount.IsPresent
        }

        if ($DestinationEmail -or $DestinationExternalId -or $DestinationTeamMemberId) {
            if ($DestinationEmail) {
                $Body.Add("transfer_dest_id",@{".tag"="email";email=$DestinationEmail})
            } elseif ($DestinationExternalId) {
                $Body.Add("transfer_dest_id",@{".tag"="external_id";external_id=$ExternalId})               
            } elseif ($DestinationTeamMemberId) {
                $Body.Add("transfer_dest_id",@{".tag"="team_member_id";team_member_id=$DestinationTeamMemberId})
            }
            # Admin id required for transfer_dest_id.
            if ($AdminEmail) {
                $Body.Add("transfer_admin_id",@{".tag"="email";email=$AdminEmail})
            } elseif ($AdminExternalId) {
                 $Body.Add("transfer_admin_id",@{".tag"="external_id";external_id=$AdminExternalId})               
            } elseif ($AdminTeamMemberId) {
                $Body.Add("transfer_admin_id",@{".tag"="team_member_id";team_member_id=$AdminTeamMemberId})
            } else {
                Write-Warning "Specifying a destination account requires admin id to be specified."
            }

        }
        Write-Verbose ($Body | ConvertTo-Json)
        if ($PSCmdlet.ShouldProcess($User.Name,"Remove Dropbox team member")) {
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