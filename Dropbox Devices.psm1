<#
.Synopsis
   List Dropbox member's sessions.
.DESCRIPTION
   Cmdlet lists all device sessions for specified user. This can include list of web, device or mobile client sessions.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-devices-list_member_devices
.EXAMPLE
   PS> Get-DropboxMemberDevices -MemberEmail powershell@example.com -Token <TeamMemberFileAccess> -IncludeWebSessions

   Cmdlet returns list of web sessions for member powershell@example.com.
.EXAMPLE
   PS> Get-DropboxMemberDevices -MemberEmail powerShell@example.com -Token <TeamMemberFileAccess> -IncludeWebSessions -IncludeDesktopClients -IncludeMobileClients

   Cmdlet returns list of web, desktop and mobile sessions for member powershell@example.com.
#>
function Get-DropboxMemberDevices {
    [CmdletBinding()]
    Param(
        # Dropbox team member's id
        [parameter(Mandatory,ParameterSetName="TeamMemberId")]
        [string]$TeamMemberId,
        # Dropbox team member's email address to resolve team_member_id.
        [parameter(Mandatory,ParameterSetName="MemberEmail")]
        [string]$MemberEmail,
        # Whether to list web sessions.
        [switch]$IncludeWebSessions,
        # Whether to list linked desktop devices.
        [switch]$IncludeDesktopclients,
        # Whether to list linked mobile devices.
        [switch]$IncludeMobileClients,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/devices/list_member_devices'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($MemberEmail) {
            $Id = (Get-DropboxMemberInfo -MemberEmail $MemberEmail -Token (Get-DropboxToken -Permission TeamInformation)).team_member_id
            if ($Id -ne $null) {
                $TeamMemberId = $Id
            }
        }

        $Body = @{
            team_member_id=$TeamMemberId
            include_web_sessions=$IncludeWebSessions.IsPresent
            include_desktop_clients=$IncludeDesktopclients.IsPresent
            include_mobile_clients=$IncludeMobileClients.IsPresent
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            if ($IncludeWebSessions) {
                Write-Output $Result.active_web_sessions
            }
            if ($IncludeDesktopclients) {
                Write-Output $Result.desktop_client_sessions
            }
            if ($IncludeMobileClients) {
                Write-Output $Result.mobile_client_sessions
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
   List all Dropbox sesisons for team.
.DESCRIPTION
   List all Dropbox sessions for web, desktop or mobile for enture team.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-devices-list_members_devices.
.EXAMPLE
   PS> Get-DropboxDevices -IncludeWebSessions -Token <TeamMemberFileAccess>

   Cmdlet returns list of Dropbox web sessions.
.EXAMPLE
   PS> Get-DropboxDevices -IncludeWebSessions -IncludeDesktopClients -IncludeMobileClients -token <TeamMemberFileAccess>
#>
function Get-DropboxDevices {
    [CmdletBinding()]
    Param(
        # If original Get-DropboxDevices returned call includes has_more & cursor parameter.
        [string]$Cursor,
        # Whether to list Dropbox web sessions.
        [switch]$IncludeWebSessions,
        # Whether to list Dropbox desktop client sessions.
        [switch]$IncludeDesktopClients,
        # Whether to list Dropbox mobile client sessions.
        [switch]$IncludeMobileClients,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <TeamMemberFileAccess> access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/devices/list_members_devices'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            include_web_sessions=$IncludeWebSessions.IsPresent
            include_desktop_clients=$IncludeDesktopClients.IsPresent
            include_mobile_clients=$IncludeMobileClients.IsPresent
        }
        if ($Cursor) {
            $Body.Add("cursor","$Cursor")
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result.devices
            if ($Result.has_more -eq "true") {
                Write-Verbose "More devices available"
                $ResultTwo = Get-DropboxDevices -Cursor $Result.cursor -Token $Token
                Write-Output $ResultTwo.devices
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
   Revoke a device session of a team member.
.DESCRIPTION
   Revoke a device session of a team member.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-devices-revoke_device_session.
.EXAMPLE
   PS> Revoke-DropboxDevice -WebSessionId dbwsid:12345678912345678912345678912345678912 -TeamMemberId dbmid:12334232352 -Token <TeamMemberFileAccess>

   Revokes web session.
#>
function Revoke-DropboxDevice {
    [CmdletBinding()]
    Param(
        # Dropbox web session_id.
        [parameter(Mandatory,ParameterSetName="WebSession")]
        [string]$WebSessionId,
        # Dropbox desktop session_id.
        [parameter(Mandatory,ParameterSetName="DesktopClient")]
        [string]$DesktopSessionId,
        # Whether to delete all files of the account.
        [parameter(ParameterSetName="DesktopClient")]
        [switch]$DeleteOnUnlink,
        # Dropbox mobile session_id,
        [parameter(Mandatory,ParameterSetName="MobileClient")]
        [string]$MobileSessionId,
        # Dropbox team_member_id.
        [parameter(Mandatory)]
        [string]$TeamMemberId,

        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <TeamMemberFileAccess> access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/devices/revoke_device_session'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($WebSessionId) {
            $Body=@{".tag"="web_session";session_id=$WebSessionId;team_member_id=$TeamMemberId}
        }
        if ($DesktopSessionId) {
            $Body=@{".tag"="desktop_client";session_id=$DesktopSessionId;team_member_id=$TeamMemberId;delete_on_unlink=$DeleteOnUnlink.IsPresent}
        }
        if ($MobileSessionId) {
            $Body=@{".tag"="mobile_client";session_id=$MobileSessionId;team_member_id=$TeamMemberId}
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

.DESCRIPTION

.EXAMPLE

#>
function Revoke-DropboxBatchDevice {
    [CmdletBinding()]
    Param(
        # Dropbox web session_id.
        [parameter(Mandatory,ParameterSetName="WebSession")]
        [string]$WebSessionId,
        # Dropbox desktop session_id.
        [parameter(Mandatory,ParameterSetName="DesktopClient")]
        [string]$DesktopSessionId,
        # Whether to delete all files of the account.
        [parameter(ParameterSetName="DesktopClient")]
        [switch]$DeleteOnUnlink,
        # Dropbox mobile session_id,
        [parameter(Mandatory,ParameterSetName="MobileClient")]
        [string]$MobileSessionId,
        # Dropbox team_member_id.
        [parameter(Mandatory)]
        [string]$TeamMemberId,

        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <TeamMemberFileAccess> access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/devices/revoke_device_session'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($WebSessionId) {
            $Body=@{".tag"="web_session";session_id=$WebSessionId;team_member_id=$TeamMemberId}
        }
        if ($DesktopSessionId) {
            $Body=@{".tag"="desktop_client";session_id=$DesktopSessionId;team_member_id=$TeamMemberId;delete_on_unlink=$DeleteOnUnlink.IsPresent}
        }
        if ($MobileSessionId) {
            $Body=@{".tag"="mobile_client";session_id=$MobileSessionId;team_member_id=$TeamMemberId}
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