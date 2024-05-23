
#region Get all the files we need to load

# helper function for use within the .psm1 file
function script:Get-ModuleName {
    $MyInvocation.MyCommand.Module.Name
}

$ModName = Get-ModuleName
$ModFile = $MyInvocation.MyCommand.Path
$ManFile = [System.IO.Path]::ChangeExtension($ModFile,'.psd1')

# get all the file names listed in the manifest
# this also checks that the .psd1 file exists
$FileList = (Import-PowerShellDataFile -Path $ManFile -EA Stop).FileList

# make sure there's at least one file to load
if (([array]$FileList).Count -eq 0) {
    Write-Warning 'Could NOT find any file names in the "FileList" property of the .psd1 manifest'
    Write-Warning 'Please edit the .psd1 manifest to explicitly include all the files of this module in the "FileList" property'
    Write-Warning "The module $ModName was NOT loaded properly"    
    return
}

# now get the module files (this also checks that the files exist)
$ModuleFiles = $FileList | foreach {
    Get-Item -Path (Join-Path $PSScriptRoot $_) -EA Stop
}

# filter all the PowerShell and CSharp files
$PSList = $ModuleFiles | where Extension -eq .ps1
$CSList = $ModuleFiles | where Extension -eq .cs

# now get the public-private functions and all C# classes-enums
$PSFunctions = $PSList | where {$_.Directory.Name -match 'Public|Private'}
$CSharpLibs  = $CSList | where {$_.Directory.Name -eq 'Class'}

#endregion

# load the module via the using statement in order to expose the PS classes
. ([scriptblock]::Create("using module $PSScriptRoot\PSClass\PSClass.psm1"))

# Load the Classes & Enumerations
# Note: this needs to be done before loading the functions
Foreach ($File in $CSharpLibs) {
    Try {
        #Add-Type -Path $File.FullName -ErrorAction Stop
    }
    Catch {
        $msg = "Failed to import types from $($File.FullName)"
        Write-Error -Message $msg
        Write-Error $_ -ErrorAction Stop
    }
}

# Load the functions
Foreach($Import in $PSFunctions) {
    Try {
        . $Import.FullName
    }
    Catch {
        $msg = "Failed to import function $($Import.FullName)"
        Write-Error -Message $msg
        Write-Error $_ -ErrorAction Stop
    }
}
