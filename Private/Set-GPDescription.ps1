function Set-GPDescription {
<#
.SYNOPSIS
    It sets the description of a Group Policy
.EXAMPLE
    $params = @{
        GpoName       = 'TestGPO'
        UserGroup     = 'TestUsers'
        ComputerGroup = 'TestServers'
        JiraLink      = 'https://sample.atlassian.net/browse/DEVOPS-1988'
        Owner         = 'john.doe@sample.com'
        PassThru      = $true
        Verbose       = $true
    }    
    Set-GPDescription @params
#>
[OutputType([void])]
[OutputType([Microsoft.GroupPolicy.Gpo])]
[CmdletBinding(DefaultParameterSetName = 'Group')]
param (
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [Microsoft.ActiveDirectory.Management.ADGroup[]]$UserGroup,

    [Parameter(Mandatory,ParameterSetName = 'Group')]
    [Microsoft.ActiveDirectory.Management.ADGroup]$ComputerGroup,

    [Parameter(Mandatory,ParameterSetName = 'Type')]
    [ToolsServerType]$ServerType,

    [Parameter(Mandatory)]
    [ValidateJiraLink()]
    [uri]$JiraLink,

    [Parameter(Mandatory)]
    [string[]]$Owner,

    [ValidateSet('User','Admin')]
    [string]$GpoType = 'Admin',

    [switch]$PassThru
)

Write-Verbose 'Change GPO Description'
$Description = Get-Content $PSScriptRoot\..\Data\Description.txt -Raw
$SB = [System.Text.StringBuilder]::new($Description)

if     ($GpoType -eq 'Admin') {$LocalGroup = 'local admins'}
elseif ($GpoType -eq 'User')  {$LocalGroup = 'remote desktop users'}

if     ($PSCmdlet.ParameterSetName -eq 'Group') {$FilterText = "are members of the $($ComputerGroup.Name) group"}
elseif ($PSCmdlet.ParameterSetName -eq 'Type')  {$FilterText = "have the $ServerType server type"}

[void]$SB.Replace('@USERGROUP@',($UserGroup.Name -join ','))
[void]$SB.Replace('@LOCALGROUP@',$LocalGroup)
[void]$SB.Replace('@FILTERTEXT@',$FilterText)
[void]$SB.Replace('@TICKETID@',$JiraLink.Segments[-1])
[void]$SB.Replace('@JIRALINK@',$JiraLink.ToString())
[void]$SB.Replace('@DATE@',(Get-Date -Format 'dd-MMM-yyyy'))
[void]$SB.Replace('@OWNER@',($Owner -join ','))
[void]$SB.Replace('@DOMAIN@',$env:USERDOMAIN)

$NewGPO = Get-GPO -Name $GpoName
$NewGPO.Description = $SB.ToString()

if ($PassThru) {$NewGPO}
}