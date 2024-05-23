function New-GPLocalGroup {
<#
.SYNOPSIS
    Create a new Group Policy that configures domain users as members of local groups.
.DESCRIPTION
    Create a new Group Policy that configures domain users as members of local groups.
    
    Specifically the new policy that will be created will add one or more specified domain groups
    into either the local admins or the remote desktop users group.

    Additionally the new policy will apply only to a specific set of domain computers,
    which is defined either through a computer group or through the server type.
    The server type is identified through an LDAP query that looks for a specific value
    in the street property of the computer object.
.EXAMPLE
    # create a new Group Policy Object
    $params = @{
        GpoName    = 'DB-Admins'
        UserGroup  = 'DB-Admins','SRE-Admins'
        ServerType = 'DB-Server'
        JiraLink   = 'https://sample.atlassian.net/browse/DEVOPS-1988'
        Owner      = 'john.doe@sample.com'
        GpoType    = 'Admin'
        PassThru   = $true
        Verbose    = $true
    }
    New-GPLocalGroup @params
.NOTES
    Author: Panos Grigoriadis
    Email:  panos.g@almondcode.com
    Date:   28 Mar 2024
#>
[OutputType([void])]                         # <-- default output
[OutputType([Microsoft.GroupPolicy.Gpo])]    # <-- output when using the PassThru parameter option
[CmdletBinding(DefaultParameterSetName = 'Group')]
param (
    [Parameter(Mandatory,Position=0)]
    [string]$GpoName,

    [Parameter(Mandatory,Position=1)]
    [StringToADGroup()]
    [Microsoft.ActiveDirectory.Management.ADGroup[]]$UserGroup,

    [Parameter(Mandatory,Position=2,ParameterSetName = 'Group')]
    [StringToADGroup()]
    [Microsoft.ActiveDirectory.Management.ADGroup]$ComputerGroup,

    [Parameter(Mandatory,Position=2,ParameterSetName = 'Type')]
    [ToolsServerType]$ServerType,

    [Parameter(Mandatory,Position=3)]
    [ValidateJiraLink()]
    [uri]$JiraLink,

    [Parameter(Mandatory,Position=4)]
    [string[]]$Owner,

    [ValidateSet('User','Admin')]
    [string]$GpoType = 'Admin',

    [switch]$PassThru
)

if (-not (Test-IsAdmin)) {
    return 'This function requires elevated privileges, please run powershell as administrator.'
}

### copy the GPO to temp
Write-Verbose 'Copy GPO Template to Temp'
$GpoTemplate = "$PSScriptRoot\..\Data\{6B08FD7E-E918-4EBA-9AB1-9CFB1745854F}"
if (-not (Test-Path $env:Temp\TempGpo)) {New-Item $env:Temp\TempGpo -ItemType Directory -Force | Out-Null}
Copy-Item -Path $GpoTemplate -Destination $env:TEMP\TempGpo -Force -Container -ErrorAction Stop -Verbose:$false -Recurse

### change the settings in the GPO
$params = @{
    GpoType   = $GpoType
    UserGroup = $UserGroup
    XmlPath   = "$env:TEMP\TempGpo\{6B08FD7E-E918-4EBA-9AB1-9CFB1745854F}\DomainSysvol\GPO\Machine\Preferences\Groups\Groups.xml"
}
if     ($PSCmdlet.ParameterSetName -eq 'Group') {$params.ComputerGroup = $ComputerGroup}
elseif ($PSCmdlet.ParameterSetName -eq 'Type')  {$params.ServerType    = $ServerType}
Set-GPCustomSettings @params

### create GPO in AD
Write-Verbose 'Create new GPO'
try {
    $HasGpo = (Get-GPO -Name $GpoName -ErrorAction Stop) -as [bool]
    if ($HasGpo) {
        Write-Warning "GPO $GpoName already exists"
        Remove-Item "$env:TEMP\TempGpo" -Recurse -Force -Verbose:$false
        return
    }
}
catch {}

try {
    $EmptyGpo = New-GPO -Name $GpoName -Verbose:$false -ErrorAction Stop
    Import-GPO -BackupGpoName 'Local-Group' -TargetName $GpoName -Path $env:Temp\TempGpo -Verbose:$false -ErrorAction Stop | Out-Null
}
catch {throw $_}
finally {
    Remove-Item "$env:TEMP\TempGpo" -Recurse -Force -Verbose:$false    
}

### change the description
$NewGPO = Set-GPDescription @PSBoundParameters

if ($PassThru) {$NewGPO}
}