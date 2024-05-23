﻿# Module manifest for module 'Tools.AD.GPO'
# Generated by: Panos Grigoriadis
# Generated on: 28 Mar 2024

@{
RootModule        = 'Tools.AD.GPO.psm1'
ModuleVersion     = '1.2.0'
GUID              = '0b242b1e-b061-49a0-914d-dc8daa4e4715'
Author            = 'Panos Grigoriadis'
#CompanyName       = ''
#Copyright         = ''
Description       = 'Function for creating GPOs in AD, that have specific settings regarding Local Groups.'
PowerShellVersion = '5.1'
RequiredModules   = 'ActiveDirectory','GroupPolicy'
FunctionsToExport = 'New-GPLocalGroup'
#CmdletsToExport   = @()
AliasesToExport   = @()       # <-- the empty array makes sure no aliases are exported
FileList          = 'readme.md',
                    'Tools.AD.GPO.psm1',
                    'Tools.AD.GPO.psd1',
                    'Public\New-GPLocalGroup.ps1',
                    '\Private\Set-GPCustomSettings.ps1',
                    '\Private\Set-GPDescription.ps1',
                    '\Private\Test-IsAdmin.ps1',
                    '\PSClass\PSClass.psm1'
PrivateData = @{
    PSData = @{
        Tags         = 'PowerShell', 'ActiveDirectory', 'GroupPolicy'
        #ProjectUri   = ''
        ReleaseNotes = 'Helper function to create Group Policy in AD'
    }
}
}

