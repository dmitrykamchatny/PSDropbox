<#
.Synopsis
   Sets an archived team folder's status to active.
.DESCRIPTION
   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-activate.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Enable-DropboxTeamFolder {
    [CmdletBinding()]
    Param(
        # The ID of the team folder.
        [parameter(Mandatory,ParameterSetName="TeamFolderId")]
        [string]$TeamFolderId,
        # Dropbox team folder name to resolve team_folder_id.
        [parameter(Mandatory,ParameterSetName="TeamFolderName")]
        [string]$TeamFolderName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/team_folder/activate'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        
        if ($TeamFolderName) {
            $TeamFolderId = Get-DropboxTeamFolderList -TeamFolderName $TeamFolderName -Token $Token
        }
        
        $Body = @{
            team_folder_id=$TeamFolderId
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
   Set an active team folder's status to archived.
.DESCRIPTION
   Set an active team folder's status to archived and removes all folder and file members.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-archive.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Archive-DropboxTeamFolder {
    [CmdletBinding()]
    Param(
        # The ID of the team folder.
        [parameter(Mandatory,ParameterSetName="TeamFolderId")]
        [string]$TeamFolderId,
        # Dropbox team folder name to resolve team_folder_id.
        [parameter(Mandatory,ParameterSetName="TeamFolderName")]
        [string]$TeamFolderName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token,
        # Whether to force the archive to happen synchronously, default is false.
        [switch]$ForceAsync
    )

    Begin{
        $URI="https://api.dropboxapi.com/2/team/team_folder/archive"
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($TeamFolderName) {
            $TeamFolderId = Get-DropboxTeamFolderList -TeamFolderName $TeamFolderName -Token $Token
        }
        $Body = @{
            team_folder_id=$TeamFolderId
            force_async_off=$ForceAsync.IsPresent
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
   Create new team folder.
.DESCRIPTION
   Create a new, active, team folder with no members.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-create.
.EXAMPLE
   New-DropboxTeamFolder -Name PowerShell

   Creates new team folder with the name "PowerShell"
.EXAMPLE
   New-DropboxTeamFolder -Name PowerShell -SyncSetting not_synced

   Creates new team folder with the name "PowerShell" and sets team folder sync setting to not synced.
#>
function New-DropboxTeamFolder {
    [CmdletBinding()]
    Param(
        # Name for the new team folder
        [parameter(Mandatory)]
        [string]$Name,
        # The sync setting to apply to the team folder. Only permitted if the team has team selective sync enabled. This parameter is optional. 
        # "default" will follow parent folder's settings or otherwise follow default sync behavior. 
        # "not_synced" on first sync to member's computers, the folder will be set to not sync with selective sync.
        [ValidateSet("default","not_synced")]
        [string]$SyncSetting,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/team_folder/create'
        $Header=@{"Authorization"="Bearer $Token"}

    }
    Process{

        $Body = @{
            name=$Name
        }

        if ($SyncSetting) {
            $Body.Add("sync_setting",$SyncSetting)
        }
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            Write-Output $Result
        } catch {
            $ResultError = $_.Exception.Response.GetResponseStream()
            $DropboxError = Get-DropboxError -Result $ResultError
        }
    }
    End{
    }
}

<#
.Synopsis
   Get team folder info
.DESCRIPTION
   Retrieves metadata for team folders.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-get_info.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-DropboxTeamFolderInfo {
    [CmdletBinding()]
    Param(
        # The ID of the team folder.
        [string[]]$TeamFolderId,
        # List of team folder names to resolve to team_folder_id.
        [string[]]$TeamFolderName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/team_folder/get_info'
        $Header=@{"Authorization"="Bearer $Token"}
        $TeamFolderList = Get-DropboxTeamFolderList -Token $Token
        $TeamFolders = New-Object System.Collections.ArrayList
    }
    Process{
        foreach ($Id in $TeamFolderId) {
            $TeamFolders.Add($Id)
        }

        foreach ($Team in $TeamFolderName) {
            $TeamFolderList | Where-Object name -Like "*$Team*" | foreach {
                    $TeamFolders.Add($_.team_folder_id) | Out-Null
            }
        }

        $Body = @{
            team_folder_ids=$TeamFolders
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
   List all team folders.
.DESCRIPTION
   List all team folders.

   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-list.
.EXAMPLE
   Get-DropboxTeamFolderList -Limit 200

   Get list of all team folders up to 200 results.
#>
function Get-DropboxTeamFolderList {
    [CmdletBinding()]
    Param(
        # Team folder name to resolve team_folder_id.
        [string]$TeamFolderName,
        # Maximum number of results to return per request.
        [ValidateRange(1,200)]
        [int]$Limit=200,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/team_folder/list'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            limit=$Limit
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
            if ($TeamFolderName) {
                $SelectedTeamFolder = ($Result.team_folders | Where-Object name -Like "$TeamFolderName").team_folder_id
                if ($SelectedTeamFolder -eq $null) {
                    Write-Error -Message "Team Folder not found: $TeamFolder" -Category ObjectNotFound
                } else {
                    Write-Output $SelectedTeamFolder
                }
            } else {
                Write-Output $Result.team_folders | sort-object name
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
   Delete team folder.
.DESCRIPTION
   Permanently deletes an archived team folder.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-DropboxTeamFolder {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    Param(
        # Team folder name to resolve team folder id.
        [parameter(Mandatory,ParameterSetName="TeamFolderName")]
        [string]$TeamFolderName,
        # Dropbox team folder id.
        [parameter(Mandatory,ParameterSetName="TeamFolderId")]
        [string]$TeamFolderId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/team_folder/permanently_delete'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{

        if ($TeamFolderName) {
            $TeamFolder = Get-DropboxTeamFolderList -Token $Token | Where-Object {($_.name -Like $TeamFolderName -and $_.status.".tag" -eq "archived")}
            if ($TeamFolder -eq $null) {
                Write-Warning "Team folder: $TeamFolderName may not exist or is not an archived team folder"
            } else {
                $TeamFolderId = $TeamFolder.team_folder_id
            }
        }

        $Body = @{
            team_folder_id=$TeamFolderId
        }
        
        if ($PSCmdlet.ShouldProcess("Name: $TeamFolderName; TeamFolderId: $TeamFolderId","Permanently delete")) {
            try{ 
                $Response = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body)
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
   Change active team folder's name.
.DESCRIPTION
   Refer to https://www.dropbox.com/developers/documentation/http/teams#team-team_folder-rename
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Rename-DropboxTeamFolder {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="Medium")]
    Param(
        # Team folder name to resolve team folder id.
        [parameter(Mandatory,ParameterSetName="TeamFolderName")]
        [string]$TeamFolderName,
        # Dropbox team folder id.
        [parameter(Mandatory,ParameterSetName="TeamFolderId")]
        [string]$TeamFolderId,
        # New team folder name.
        [parameter(Mandatory)]
        [string]$NewName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter TeamMemberFileAccess access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/team/team_folder/rename'
        $TeamFolderID = (Get-DropboxTeamFolderList | Where-Object name -like "*$TeamFolderName").team_folder_id
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        if ($TeamFolderName) {
            $TeamFolderId = Get-DropboxTeamFolderList -TeamFolderName $TeamFolderName -Token $Token -ErrorAction Stop
        }
        if ($PSCmdlet.ShouldProcess("$TeamFolderName to $NewName")) {
            $Body = @{
                team_folder_id=$TeamFolderID
                name=$NewName
            }
            
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