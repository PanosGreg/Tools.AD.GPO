function Set-GPCustomSettings {
<#
.SYNOPSIS
    Sets the Group Policy Preferences settings.
    The Group(s) to be added to the Local Group and the Filter in the Item-Level-Targetting
#>
[OutputType([void])]
[CmdletBinding(DefaultParameterSetName = 'Group')]
param (
    [Parameter(Mandatory,Position=0)]
    [ValidateSet('User','Admin')]
    [string]$GpoType = 'Admin',

    [Parameter(Mandatory,Position=0)]
    [Microsoft.ActiveDirectory.Management.ADGroup[]]$UserGroup,

    [Parameter(Mandatory,Position=1,ParameterSetName = 'Group')]
    [Microsoft.ActiveDirectory.Management.ADGroup]$ComputerGroup,

    [Parameter(Mandatory,Position=1,ParameterSetName = 'Type')]
    [ToolsServerType]$ServerType,

    [Parameter(Mandatory)]
    [string]$XmlPath
)

Write-Verbose 'Change Settings in GPO'

# find the appropriate GPO settings XML
if ($PSCmdlet.ParameterSetName -eq 'Group' -and $GpoType -eq 'Admin') {
    $XmlTemplate = "$PSScriptRoot\..\Data\AdminFilterGroup.xml"
}
elseif ($PSCmdlet.ParameterSetName -eq 'Type' -and $GpoType -eq 'Admin') {
    $XmlTemplate = "$PSScriptRoot\..\Data\AdminFilterLDAP.xml"
}
elseif ($PSCmdlet.ParameterSetName -eq 'Group' -and $GpoType -eq 'User') {
    $XmlTemplate = "$PSScriptRoot\..\Data\UserFilterGroup.xml"
}
elseif ($PSCmdlet.ParameterSetName -eq 'Type' -and $GpoType -eq 'User') {
    $XmlTemplate = "$PSScriptRoot\..\Data\UserFilterLDAP.xml"
}
[xml]$GPO = Get-Item $XmlTemplate | Get-Content -Raw

# add extra user groups to the GPO if more than 1
if ($UserGroup.Count -ge 2) {
    1..($UserGroup.Count-1) | foreach {
        $Nodes = $GPO.Groups.Group.Properties.Members
        $Child = $Nodes.OwnerDocument.ImportNode($Nodes.FirstChild, $true)
        [void]$Nodes.AppendChild($Child)
    }
}

# now set each user group appropriately
$i = 0
$GPO.Groups.Group.Properties.Members.GetEnumerator() | foreach {
    $_.name = '{0}\{1}' -f $env:USERDOMAIN,$UserGroup[$i].Name
    $_.sid  = $UserGroup[$i].SID.Value
    $i++
}

# set the Item-Level-Targetting filter
if ($PSCmdlet.ParameterSetName -eq 'Group') {
    $GPO.Groups.Group.Filters.FilterGroup.name = $ComputerGroup.Name
}
elseif ($PSCmdlet.ParameterSetName -eq 'Type') {
    $flt = "(&(objectCategory=computer)(objectClass=computer)(street=*""ServerType"":""$ServerType""*))"
    $GPO.Groups.Group.Filters.FilterLdap.searchFilter = $flt
}

# finally save the xml
[void]$GPO.Save($XmlPath)

}