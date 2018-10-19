# Dropbox-PowerShell-Module

## Description

This PowerShell Module allows administrators with appropriate access tokens to perform actions on Dropbox from Windows PowerShell. Personal accounts are able to manage their own files and folders as well as sharing with other Dropbox members. Advanced and Business accounts ware able to manage team members, groups, team folders and perform file, folder and sharing actions to specific team members with an access token with "Team member file access" permission.

The module utilizes the HTTP Dropbox API to send rest method calls to Dropbox with your own specified parameters. [Refer to Dropbox for HTTP Developers](https://www.dropbox.com/developers/documentation/http/overview) documentation.

## Installtion

1. [Create a Dropbox platform app](https://www.dropbox.com/developers/apps)
2. Generate Access Token
3. Download module files
```
# Download module files to either directory to allow PowerShell to automatically import the module.
cd $env:USERPROFILE\Documents\WindowsPowerShell\Modules\
or
cd "C:\Program Files\WindowsPowerShell\Modules\

git clone https://github.com/dmitrykamchatny/Dropbox-PowerShell-Module.git
```

## Usage

1. Run New-DropboxTokenFile cmdlet to generate a token
  - Defualt path is $env:USERPROFILE\Documents\DropboxTokens.json
```
PS > New-DropboxTokenFile
Enter TeamMemberManagement access token: <TeamMemberManagement>
Enter TeamInformation access token: <TeamInformation>
Enter TeamAuditing access token: <TeamAuditing>
Enter TeamMemberFileAccess access token: <TeamMemberFileAccess>
Enter Personal access token: <Personal>

Name                 Token                 
----                 -----                 
TeamMemberManagement <TeamMemberManagement>
TeamInformation      <TeamInformation>     
TeamAuditing         <TeamAuditing>        
TeamMemberFileAccess <TeamMemberFileAccess>
Personal             <Personal>            
File output: C:\Users\Dmitry\Documents\DropboxTokens.json
```
2. Assign token to a variable and run a command!
```
PS > $Personal = Get-DropboxToken -Permission Personal
PS > New-DropboxFolder -Path /PowerShell -Token $Personal
name       path_lower  path_display id                       
----       ----------  ------------ --                       
PowerShell /powershell /PowerShell  id:XXXXXXXXXXXXXXXXXX
```
3. Run a command as on another user's Dropbox account
 - Dropbox API requires team_member_id parameter but SelectUser parameter currently only support email addresses which is used to resolve the team_member_id using Get-DropboxMemberInfo cmdlet which requires "Team information" permission.
```
PS > $TeamMemberFileAccess = Get-DropboxToken -Permission TeamMemberFileAccess
PS > New-DropboxFolder -Path /PowerShell -SelectUser powershell@example.com -Token $TeamMemberFileAccess
cmdlet Get-DropboxMemberInfo at command pipeline position 1
Supply values for the following parameters:
(Type !? for Help.)
Token: !?
Enter TeamInformation access token
Token: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

name       path_lower  path_display id                       
----       ----------  ------------ --                       
PowerShell /powershell /PowerShell  id:XXXXXXXXXXXXXXXXXXXX
```
## To-do

- [ ] New module name
- [ ] Implement better error output
- [ ] Implement better token management / storage
- [ ] Add "continue" cmdlets for organisations with more possible results than API limits allow
- [ ] PowerShell help documentation ( description, examples, parameters )
- [ ] Create cmdlets for almost all HTTP API calls
- [ ] Upload to PowerShell Gallary
