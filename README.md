

## Overview

This PowerShell module exposes a single command, the **`New-GPLocalGroup`**, that creates custom group policies in AD.


## Requirements

This command should be used from a Domain Controller.  
This command requires the `ActiveDirectory` module and the `GroupPolicy` module.
This command must be run from an elevated PowerShell session.


## Functionality

It creates a new Group Policy Object in AD (but does not link it in any OU) that gives either local admin or remote desktop access to one ore more user groups. It applies that policy only to a specific set of computers, that is either defined in another group or through an LDAP query that checks the server type of the computers in AD.

The server type is a custom tag that we have added to AD on all computer objects, which uses the "street" property.

### Options
The function can create a Group Policy Object that:
- Adds AD users either to the _"Administrators"_ local group or to the _"Remote Desktop Users"_ local group.
- You can add one or more AD groups to that local group.
- The GPO is filtered either through an AD group or through an LDAP query.
- The AD group filter means that the group policy will only apply to the computers found in a specified group
- The LDAP query filter means that the group policy will only apply to the computers that have a specific value on their street property. That value is a string that must include a predefined word, which in this case defines the server type.
- The server types I defined till now are: `PayDB`, `PaySupport`, `PayServer`


## Details

The way this function works is that it creates a brand new empty GPO. And then it imports a backed up GPO into it, which essentially loads the settings.  
Now the backed up GPO is created from a GPO template found on this module. Which we then modify according to our needs. And once the backed up GPO is ready then we import it into the empty GPO.

The result is a new Group Policy Object in AD, that has settings in this path:  
`\Computer Configuration\Preferences\Control Panel Settings\Local Users and Groups`

## Example

A quick example on how to use the function.

```PowerShell
# load the module
Import-Module Tools.AD.GPO

$params = @{
    GpoName       = 'TestLadmin4'
    UserGroup     = 'UserGroup1'
    ComputerGroup = 'DB-Servers'
    JiraLink      = 'https://sample.atlassian.net/browse/DEVOPS-1988'
    Owner         = 'john.doe@sample.com'
    GpoType       = 'Admin'
    PassThru      = $true
    Verbose       = $true
}
New-GPLocalGroup @params
```
Which will return the following:
```
DisplayName      : TestLadmin4
DomainName       : lab.net
Owner            : LAB\Domain Admins
Id               : 357484ba-e378-4f6d-8aaa-3535e13b6553
GpoStatus        : UserSettingsDisabled
Description      : This group policy adds specific users to a local group on specific computers.

                   The USERS of this AD group: UserGroup1
                       -- will be added to the local admins --
                   On the COMPUTERS that are members of the DB-Servers group

                   Jira ticket: DEVOPS-1988
                   Jira link: https://lab.atlassian.net/browse/DEVOPS-1988

                   Date: 29-Mar-2024
                   Owner: john.doe@sample.com

                   Technical Note
                   When using the Computer Group option in Item-Level-Targeting filter, then we have to set the group
                   name without the domain prefix (ex. "LAB\"), otherwise the GPO does not get applied to the
                   computers of the group.
CreationTime     : 29/03/2024 21:46:34
ModificationTime : 30/03/2024 22:53:36
UserVersion      : AD Version: 1, SysVol Version: 1
ComputerVersion  : AD Version: 13, SysVol Version: 13
WmiFilter        :
```

## Screenshots

These are a few sample screenshots from the Group Policy Management Console of the GPO that was created using this module.  
- _GPO Settings - Groups_
![GPO Settings - Groups](/Docs/GPO-Settings-Groups.jpg)
- _GPO Settings - Filter_
![GPO Settings - Filter](/Docs/GPO-Settings-Filter.jpg)
- _GPO Comment_
![GPO Comment](/Docs/GPO-Comment.jpg)
- _GPO Report_
![GPO Report](/Docs/GPO-Report.jpg)