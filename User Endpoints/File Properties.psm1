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
function Add-DropboxFileProperties {
    [CmdletBinding()]
    Param(
        # Path of file or folder
        [Parameter(Mandatory)]
        [string]$Path,
        # Template Id
        [string]$TemplateId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/file_properties/properties/add'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
        $Fields = New-Object System.Collections.ArrayList
    }
    Process{
        $Template = Get-DropboxTemplate -TemplateId $TemplateId -Token $Token
        Write-Output "Template: $($Template.name)"
        Write-Output "Template description: $($Template.description)"
        foreach ($Field in $Template.fields) {
            Write-Output "Field name: $($Field.name)"
            Write-Output "Field description: $($Field.description)"
            $FieldValue = Read-Host "Enter a field value"
            $Fields.Add(@{name=$Field.name;value=$FieldValue}) | Out-Null
        }

        $Body = @{
            path=$Path
            property_groups=@(@{
                template_id=$TemplateId
                fields=$Fields    
            })
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body -Depth 4)
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
function Search-DropboxProperty {
    [CmdletBinding()]
    Param(
        # Property field value to search for.
        [parameter(Mandatory)]
        [string]$Query,
        # Mode to perform search.
        [ValidateSet("field_name")]
        $SearchMode="field_name",
        # Search value associated with field name.
        [string]$FieldName,
        # Logical operator to append the query.
        [ValidateSet("or_operator")]
        [string]$LogicalOperator="or_operator",
        # List of templates to filter.
        [string[]]$TemplateFilter="filter_none",
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token,
        # Run command on behalf of selected Dropbox team member.
        [string]$SelectUser
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/file_properties/properties/search'
        $Header=@{"Authorization"="Bearer $Token"}
        if ($SelectUser){
            $MemberID = (Get-DropboxMemberInfo -MemberEmail $SelectUser).team_member_id
            $Header.add("Dropbox-API-Select-User",$MemberId)
        }
    }
    Process{     
        $Body = @{
            queries=@(@{
                query=$Query
                mode=@{
                    ".tag"=$SearchMode
                    field_name=$FieldName
                }
                logical_operator=$LogicalOperator
            })
            template_filter=$TemplateFilter
        }
        
        try {
            $Result = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Headers $Header -Body (ConvertTo-Json -InputObject $Body -Depth 8)
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
function Add-DropboxTemplate {
    [CmdletBinding()]
    Param(
        # Display name for template.
        [parameter(Mandatory)]
        [string]$Name,
        # Description for the template.
        [parameter(Mandatory)]
        [string]$Description,
        # Field names
        [string[]]$FieldName,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter access token")]
        [string]$Token
    )

    Begin{
        $URI='https://api.dropboxapi.com/2/file_properties/templates/add_for_user'
        $Header=@{"Authorization"="Bearer $Token"}
        $Fields = New-Object System.Collections.ArrayList

    }
    Process{
        foreach ($Field in $FieldName) {
            Write-Output "Field name: $Field"
            $FieldDescription = Read-Host "Enter field description"
            $Fields.Add(@{name=$Field;description=$FieldDescription;type="string"}) | Out-Null
        }

        $Body = @{
            name=$Name
            description=$Description
            fields=$Fields
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
function Get-DropboxTemplate {
    [CmdletBinding()]
    Param(
        # Teamplate Id
        [parameter(Mandatory)]
        [string]$TemplateId,
        # Dropbox API access token.
        [parameter(Mandatory,HelpMessage="Enter <Permission> access token")]
        [string]$Token

    )

    Begin{
        $URI='https://api.dropboxapi.com/2/file_properties/templates/get_for_user'
        $Header=@{"Authorization"="Bearer $Token"}
    }
    Process{
        $Body = @{
            template_id=$TemplateId
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