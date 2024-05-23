<#
.SYNOPSIS
    Two PowerShell classes, one is a Transformation attribute and the other one is 
    a Validation attribute.
    The transformation converts a string into ADGroup, and the validation checks
    for a proper Jira URL.
.NOTES
    I need to put these classes here in a separate module (.psm1) in order to load
    it through the using statement on the root module, so that I can access the
    attribute classes.
    Also I think the classes need to be in the module file and not on separate files,
    hence they can't be dot sourced, but not 100% sure of that, since I'm loading this
    module with using, so it shouldn't matter.
#>


class StringToADGroupAttribute : System.Management.Automation.ArgumentTransformationAttribute {

    [object] Transform ([Management.Automation.EngineIntrinsics] $EngineIntrinsics, [object] $InputObject) {
        $Out = foreach ($Group in $InputObject) {
            if ($Group -is [Microsoft.ActiveDirectory.Management.ADGroup]) {
                Write-Output $Group
            }
            elseif ($Group -is [string]) {
                Get-ADGroup -Identity $Group -ErrorAction Stop
            }
            else {
                throw [System.ArgumentException]::new('Please provide a valid AD Group Object')
            }
        }
        return $Out
    }
}

class ValidateJiraLinkAttribute : System.Management.Automation.ValidateArgumentsAttribute {

    [void] Validate ([object]$InputObject,[System.Management.Automation.EngineIntrinsics]$EngineIntrinsics) {
        
        if ($InputObject -is [string]) {
            try   {$Uri = [uri]::new($InputObject,[System.UriKind]::Absolute)}
            catch {throw $_}
        }
        elseif ($InputObject -is [uri]) {$Uri = $InputObject}
        else {throw [System.ArgumentException]::new('Please provide a valid Uri type input')} 

        $IsGood = $Uri.IsAbsoluteUri -and $Uri.Host -like '*atlassian.net'
        if (-not $IsGood) {        
            throw [System.ArgumentException]::new('Please provide a valid JIRA Url')
        }
    }
}


# an Enumeration for the various computer types
enum ToolsServerType {
    PayDB
    PaySupport
    PayServer
}